Exec {
  path => ['/bin', '/usr/bin']
}

$masterNode = "pm"

class setupClient {
  # Configuring Agent
  host { 'addMasterEntry':
    name => 'pm',
    ip   => '192.168.33.10',
  }

  file { '/etc/puppet/puppet.conf':
    ensure  => file,
    content => template('puppet.conf.erb'),
  }

  file { '/etc/default/puppet':
    ensure  => file,
    content => template('puppet.erb'),
    require => File['/etc/puppet/puppet.conf'],
    notify  => Service['puppet'],
  }

  # Adding puppet repo
  exec { 'add_repo':
    command => 'sudo dpkg -i /vagrant/puppetlabs-release-precise.deb',
  }

  exec { 'update_repo':
    command => 'apt-get update',
    require => Exec['add_repo'],
  }

  exec { 'install puppet client':
    command => 'sudo apt-get install -y puppet',
    require => [ Exec['update_repo'], Host['addMasterEntry'] ],
    before  =>  File['/etc/default/puppet', '/etc/puppet/puppet.conf'],
  }

  service { 'puppet':
    ensure  => running,
    require => Exec['install puppet client'],
  }  
}

include setupClient

