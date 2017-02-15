require 'spec_helper'

describe 'systemd::journald_config' do

  describe file('/etc/systemd/journald.conf.d/00-foo.conf') do
    it { should be_file }
    its(:content) { should match /RateLimitInterval=5s/ }
    its(:content) { should match /RateLimitBurst=30/ }
    its(:content) { should match /MaxRetentionSec=10month/ }
    its(:content) { should match /SystemMaxFileSize=100M/ }
    its(:content) { should match /RuntimeMaxFileSize=1M/ }
  end

  describe file('/tmp/journal_dump') do
    its(:content) { should match /Suppressed+.+messages+.+from/ }
  end
end
