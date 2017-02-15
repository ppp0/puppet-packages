# Excerpts from man journald.conf(5)
#
# $max_retention: This setting also takes time values which may be suffixed with the
#    units "year", "month", "week", "day", "h" or " m" to override the default time unit of seconds.
#
# $rate_limit_interval: The time specification for RateLimitInterval= may be
#    specified in the following units: "s", "min", "h", "ms", "us". To turn off any kind of rate limiting,
#    set either value to 0.
#
# $systems_max_file_size: Specify values in bytes or use K, M, G, T, P, E as units
# $runtime_max_file_size
#

define systemd::journald::config (
  $max_retention       = '1m',
  $rate_limit_interval = '5s',
  $rate_limit_burst    = 40,
  $system_max_file_size = '100M',
  $runtime_max_file_size = '1M'
) {

  include 'systemd::journald::reload'
  include 'augeas'

  file { "/etc/systemd/journald.conf.d/${name}.conf":
    ensure  => file,
    content => template("${module_name}/journald/conf.erb"),
    owner   => '0',
    group   => '0',
    mode    => '0644',
    notify  => Exec['journald reload due to config change'],
  }

  augeas { $title:
    lens    => "Puppet.lns",
    incl    => "/etc/systemd/journald.conf",
    changes => [
      "set Journal/MaxRetentionSec 3m",
      "set Journal/SystemMaxUse 200M",
      "set Journal/MaxRetentionSec 7d",
    ],
    require => Class['augeas'],
    notify  => Exec['journald reload due to config change'],
  }
}

