class bluetooth (
  $audio_autoconnect = true,
  $audio_fastconnectable = true,
){

  include 'bluetooth::bluez'

  package { 'bluetooth':
    provider => apt
  }

  file { '/etc/bluetooth/audio.conf':
    ensure  => file,
    content => template("${module_name}/audio.conf"),
    mode    => '0655',
    owner   => '0',
    notify  => Service['bluetooth'],
    before  => Service['bluetooth'],
    require => Package['bluetooth'],
  }

  service { 'bluetooth':
    enable => true,
  }
}
