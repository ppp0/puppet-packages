class openvpn(
  $max_clients = 25,
  $data_compression = true,
  $duplicate_cn = false,
  $client_to_client = false,
  $route_private_network_mask = '255.255.255.0',
  $route_private_network = '172.20.10.0',
  $vpn_subnet_mask = '172.20.80.0',
  $vpn_subnet = '255.255.255.0',
  $crypt_key,
  $crypt_key_cert,
  $crypt_key_certauth,
){

  include 'openvpn::service'
}
