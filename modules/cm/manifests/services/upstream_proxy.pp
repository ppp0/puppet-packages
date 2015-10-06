class cm::services::upstream_proxy(
  $members = ['localhost']
) {

  include 'cm::services::webserver'

  $upstream_members = suffix($members, ' max_fails=999 fail_timeout=1')

  nginx::resource::upstream { $name:
    ensure              => present,
    members             => $upstream_members,
    upstream_cfg_append => [
      'keepalive 400;',
    ],
  }
}
