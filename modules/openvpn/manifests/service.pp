class openvpn::service {

  service { 'openvpn':
    enable => true,
  }
}
