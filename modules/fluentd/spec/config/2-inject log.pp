node default {

  exec{ 'add entry to observed file':
    provider => shell,
    command  => "sleep 5;echo '{\"message\":\"FOO\"}' >>/tmp/my-source-2",
    path => ['/usr/local/sbin', '/usr/local/bin', '/usr/sbin', '/usr/bin', '/sbin', '/bin'],
  }
}
