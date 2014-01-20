Exec {
  path => ['/bin', '/usr/bin']
}

$masterNode = "pm"

class setupMaster {

  # Setup master
  host { 'addAgentEntry':
    name => 'pa',
    ip   => '192.168.33.11',
  }

  file { '/etc/puppet/puppet.conf':
    ensure  => file,
    content => template('puppet.conf.erb'),
  }

  file { '/etc/puppet/manifests/site.pp':
    ensure  => file,
    content => template('site.pp.erb'),
    require => [ File['/etc/puppet/puppet.conf'],
                 Exec['install zookeeper', 'install apt', 'install stdlib', 'install kafka'],
                ],
    notify  => Service['puppetmaster'],
  }

  # Add puppet repo
  exec { 'add_repo':
    command => 'sudo dpkg -i /vagrant/puppetlabs-release-precise.deb',
  }

  # Update repos
  exec { 'update_repo':
    command => 'apt-get update',
    require => Exec['add_repo'],
  }

  # Install puppet master
  exec { 'install puppet master':
    command => 'sudo apt-get install -y puppetmaster',
    require => [ Exec['update_repo'], Host['addAgentEntry'] ],
    before  =>  File['/etc/puppet/manifests/site.pp',  '/etc/puppet/puppet.conf'],

  }

  # Puppet service
  service { 'puppetmaster':
    ensure  => running,
    require => Exec['install puppet master'],
  }

  # Puppet dependencies
  exec {
    'install zookeeper':
      command => 'puppet module install whisklabs-zookeeper --force',
      require => Exec['install puppet master'];

    'install apt':
      command => 'puppet module install puppetlabs/apt --force',
      require => Exec['install puppet master'];

    'install stdlib':
      command => 'puppet module install puppetlabs/stdlib --force',
      require => Exec['install puppet master'];

    'install kafka':
      command => 'puppet module install whisklabs-kafka --force',
      require => Exec['install puppet master'];

    'install graphite':
      command => 'puppet module install dwerder/graphite --force',
      require => Exec['install puppet master'];
  }

}

include setupMaster
