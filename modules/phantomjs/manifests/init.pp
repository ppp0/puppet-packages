class phantomjs($version = '2.1.1') {

  require 'apt'
  require 'build'

  package {['unp', 'fontconfig']:
    provider => 'apt',
  }
  ->

  helper::script { 'install phantomjs':
    content => template("${module_name}/install.sh"),
    unless  => "/usr/local/share/phantomjs/bin/phantomjs --version | grep -q '${version}'",
  }
  ->

  file { '/usr/local/bin/phantomjs':
    ensure    => link,
    target    => '/usr/local/share/phantomjs/bin/phantomjs',
  }
}
