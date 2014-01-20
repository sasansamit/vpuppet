class java {
  include apt

  exec { 'apt-get update':
    command => '/usr/bin/apt-get update',
    before => Apt::Ppa["ppa:webupd8team/java"],
  }
  apt::ppa { "ppa:webupd8team/java": }

  exec { 'apt-get update 2':
    command => '/usr/bin/apt-get update',
    require => Apt::Ppa["ppa:webupd8team/java"]
  }
  exec { "accept_license":
    command   => "echo debconf shared/accepted-oracle-license-v1-1 select true | sudo debconf-set-selections && echo debconf shared/accepted-oracle-license-v1-1 seen true | sudo debconf-set-selections",
    cwd       => "/home/vagrant",
    user      => "vagrant",
    path      => "/usr/bin/:/bin/",
    logoutput => true,
    before => Package["oracle-java7-installer"],
  }
  package { ["oracle-java7-installer"]:
    ensure => present,
    require => Exec["apt-get update 2"],
  }
  file { "/home/vagrant/.bash_profile":
    content => "export JAVA_HOME=/usr/lib/jvm/java-7-oracle"
  }
}
