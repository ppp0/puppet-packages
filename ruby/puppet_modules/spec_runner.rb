require 'open3'
require 'event_emitter'
require 'json'

require 'colorize'

module PuppetModules
  class SpecRunner

    class Result

      attr_accessor :spec_result_list

      def initialize
        @spec_result_list = []
      end

      def examples_summary_hash
        memo = {
          'duration' => 0,
          'example_count' => 0,
          'failure_count' => 0,
          'pending_count' => 0,
        }
        @spec_result_list.reduce memo do |memo, spec_result|
          memo.merge spec_result.summary_hash do |key, oldval, newval|
            oldval + newval
          end
        end
      end

      def success?
        @spec_result_list.all?(&:success?)
      end

      def summary

        spec_total_count = @spec_result_list.count
        spec_failures = @spec_result_list.reject(&:success?)
        summary = "#{spec_total_count} specs run, #{spec_failures.count} failures"

        examples_summary = examples_summary_hash
        examples_total_count = examples_summary['example_count']
        examples_failure_count = examples_summary['failure_count']
        summary << " (#{examples_total_count} examples, #{examples_failure_count} failures)"


        duration = examples_summary['duration']
        minutes = (duration / 60).floor
        seconds = (duration % 60).floor
        summary << ', took'
        summary << " #{minutes} minutes and" if minutes > 0
        summary << " #{seconds} seconds"
        summary
      end

    end

    class ExampleResult

      attr_reader :spec, :os

      def initialize(spec, os, status, stdout)
        @spec = spec
        @os = os
        @status = status
        @stdout = stdout
      end

      def success?
        @status == 0 && failures.count == 0
      end

      def summary_hash
        @stdout['summary']
      end

      def summary
        headline = [
          success? ? 'Success!'.green : 'Failure!'.red,
          @stdout['summary_line']
        ].join(' ').bold

        lines = []
        lines.push(headline)
        lines.push('Failed examples:') unless success?
        lines += failures.map { |example| '  ' + example['full_description'] }
        lines.push("\n")
        lines.join("\n")
      end

      def failures
        @stdout['examples'].select do |example|
          example['status'] === 'failed'
        end
      end
    end


    include EventEmitter

    def initialize(os_support)
      @os_support = os_support
      @specs = []
    end

    def add_specs(specs)
      @specs.concat(specs)
    end

    def run
      result = Result.new
      @specs.each do |spec|
        spec.get_module.supported_os_list.each do |os|
          emit(:output, "Running #{spec.name} for #{os[:operatingssystem]} #{os[:operatingsystemrelease]}\n".bold)
          box = map_os_to_box(os)
          example_result = run_in_box(spec, box)
          emit(:output, example_result.summary)
          result.spec_result_list.push(example_result)
        end
      end
      result
    end

    def run_in_box(spec, box)
      env = {'box' => box}
      command = "bundle exec rspec --format json #{spec.file.to_s}"
      output = {:stdout => '', :stderr => '', :combined => ''}
      status = nil

      Open3.popen3(env, command) do |stdin, stdout, stderr, wait_thr|
        stdin.close

        streams_read_open = [stdout, stderr]
        begin
          streams_read_available, _, _ = IO.select(streams_read_open)

          streams_read_available.each do |stream|
            if stream.eof?
              stream.close
              streams_read_open.delete(stream)
            else
              data = stream.readpartial(4096)
              if stdout === stream
                output[:stdout] += data
              end
              if stderr === stream
                emit(:output, data)
                output[:stderr] += data
              end
              output[:combined] += data
            end
          end
        end until streams_read_open.empty?
        status = wait_thr.value
      end
      stdout = JSON.parse(output[:stdout])
      ExampleResult.new(spec, box, status, stdout)
    end

    def map_os_to_box(os)
      supported_os = @os_support.select { |data|
        data['operatingsystem'] === os[:operatingssystem] and data['operatingsystemrelease'] === os[:operatingsystemrelease]
      }.first
      raise 'Unsupported OS' if supported_os.nil?
      supported_os['box']
    end
  end
end
