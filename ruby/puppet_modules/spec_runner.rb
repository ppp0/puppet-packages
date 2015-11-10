require 'open3'
require 'event_emitter'
require 'json'
require 'colorize'
require 'chronic_duration'
require 'komenda'
require 'indentation'

module PuppetModules

  class SpecRunner


    class Result

      attr_accessor :spec_result_list

      def initialize
        @spec_result_list = []
      end

      def examples_summary_hash
        initial = {
          'duration' => 0,
          'example_count' => 0,
          'failure_count' => 0,
          'pending_count' => 0,
        }
        @spec_result_list.reduce initial do |memo, spec_result|
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

        duration = examples_summary['duration'].floor
        summary << ', took ' + ChronicDuration.output(duration, :keep_zero => true)
        summary
      end
    end

    class SpecResult

      attr_reader :spec, :os

      def initialize(spec, os, status, stdout)
        @spec = spec
        @os = os
        @status = status
        @stdout = JSON.parse(stdout)
      end

      def success?
        @status == 0 && failed_examples.count == 0
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
        lines.push("\n")
        failed_examples.each do |example|
          example_lines = []
          example_lines << example['full_description']
          unless example['exception'].nil?
            exception = example['exception']
            example_lines << exception['class'] + ':'
            example_lines << exception['message'].indent(2)
          end
          lines << example_lines.join("\n").indent(4)
        end
        lines.push("\n")
        lines.join("\n")
      end

      def failed_examples
        @stdout['examples'].select do |example|
          example['status'] === 'failed'
        end
      end
    end


    include EventEmitter

    def initialize
      @specs = []
    end

    def add_specs(specs)
      @specs.concat(specs)
    end

    def run
      result = Result.new
      @specs.each do |spec|
        spec.get_module.supported_os_list.each do |os|
          emit(:output, "Running #{spec.name} for #{os}\n".bold)
          example_result = run_spec_in_box(spec, os)
          emit(:output, example_result.summary)
          result.spec_result_list.push(example_result)
        end
      end
      result
    end

    def run_spec_in_box(spec, box)
      env = {'box' => box}
      command = "bundle exec rspec --format json #{spec.file.to_s}"
      process = Komenda.create(command, {:env => env})
      runner = self
      process.on :stderr do |data|
        runner.emit(:output, data)
      end
      result = process.run
      SpecResult.new(spec, box, result.status, result.stdout)
    end
  end
end
