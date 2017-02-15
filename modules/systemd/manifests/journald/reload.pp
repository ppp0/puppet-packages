class systemd::journald::reload {

  require 'systemd'

  file { '/etc/systemd/journald.conf.d':
    ensure => directory,
    owner   => '0',
    group   => '0',
    mode    => '0644',
  }

  exec { 'journald reload due to config change':
    command     => 'systemctl restart systemd-journald',
    path        => ['/usr/local/sbin', '/usr/local/bin', '/usr/sbin', '/usr/bin', '/sbin', '/bin'],
    refreshonly => true,
  }
}