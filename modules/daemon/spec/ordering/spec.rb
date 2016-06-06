require 'spec_helper'

describe 'daemon:ordering' do

  describe service('my-program') do
    it { should be_enabled }
    it { should be_running }
  end

  describe process('my-program') do
    it { should be_running }
  end

  describe file('/tmp/TS_after') do
    its(:content) { should match /active \(running\)/ }
  end

  describe command('test $(($(cat /tmp/TS_after)-$(cat /tmp/TS_before))) -gt 0') do
    its(:exit_status) { should eq 0 }
  end

end
