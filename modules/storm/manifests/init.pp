# /etc/puppet/modules/storm/manafests/init.pp
class storm (
  $version = $storm::params::version,
  $storm_user = $storm::params::storm_user,
  $storm_group = $storm::params::storm_group,
  $nimbus_host = $storm::params::nimbus_host,
  $zookeeper_servers = $storm::params::zookeeper_servers,
  $java_home = $java::params::java_home,
  $storm_base = $storm::params::storm_base,
  $storm_conf = $storm::params::storm_conf,
  $storm_user_path = $storm::params::storm_user_path,
  $storm_local_path = $storm::params::storm_local_path
) inherits storm::params {

  require storm::params
  require java

  package { 'gcc':
    ensure  => installed,
    before => File['/opt/zeromq'],
  }

  package { 'g++':
    ensure  => installed,
    before => File['/opt/zeromq'],
  }

  package { 'uuid-dev':
    ensure  => installed,
    before => File['/opt/zeromq'],
  }

  package { 'make':
    ensure  => installed,
    before => File['/opt/zeromq'],
  }

  package { 'pkg-config':
    ensure  => installed,
    before => File['/opt/zeromq'],
  }

  package { 'libtool':
    ensure  => installed,
    before => File['/opt/zeromq'],
  }

  package { 'autoconf':
    ensure  => installed,
    before => File['/opt/zeromq'],
  }

  package { 'automake':
    ensure  => installed,
    before => File['/opt/zeromq'],
  }


  file { "/opt/zeromq":
    ensure => "directory",
    owner => "${storm_user}",
    group => "${storm_group}",
    require => [ User["${storm_user}"], Group["${storm_group}"] ]
  }

  exec { 'download_zeromq':
    command => "wget http://download.zeromq.org/zeromq-2.1.7.tar.gz",
    cwd => "/opt/zeromq",
    creates => "/opt/zeromq/zeromq-2.1.7.tar.gz",
    user => "${storm_user}",
    path    => ["/bin", "/usr/bin", "/usr/sbin"],
    before      => Exec['untar_zeromq'],
    require => File['/opt/zeromq'],
    logoutput => true,
  }

  exec { "untar_zeromq":
    command => "tar xfvz zeromq-2.1.7.tar.gz",
    cwd => "/opt/zeromq",
    creates => "/opt/zeromq/zeromq-2.1.7",
    alias => "untar-zeromq",
    user => "${storm_user}",
    require => User["${storm_user}"],
    path    => ["/bin", "/usr/bin", "/usr/sbin"],
  }

  exec { "config_zeromq":
    command => "./configure",
    cwd => "/opt/zeromq/zeromq-2.1.7",
    alias => "config-zeromq",
    user => "${storm_user}",
    require => Exec["untar_zeromq"],
    path    => ["/bin", "/usr/bin", "/usr/sbin", "/opt/zeromq/zeromq-2.1.7"],
    logoutput => true,
  }

  exec { "make_zeromq":
    command => "make",
    cwd => "/opt/zeromq/zeromq-2.1.7",
    alias => "make-zeromq",
    user => "${storm_user}",
    require => Exec["config_zeromq"],
    path    => ["/bin", "/usr/bin", "/usr/sbin"],
  }

  exec { "install_zeromq":
    command => "sudo make install",
    cwd => "/opt/zeromq/zeromq-2.1.7",
    alias => "install-zeromq",
    require => Exec["make_zeromq"],
    path    => ["/bin", "/usr/bin", "/usr/sbin"],
  }

  package { 'git':
    ensure  => installed,
    require => Exec['install_zeromq'],
  }

  file { "/opt/jzmq":
    ensure => "directory",
    owner => "${storm_user}",
    group => "${storm_group}",
    require => [ User["${storm_user}"], Group["${storm_group}"] ],
    before => Exec['download_jzmq'],
  }

  exec { "download_jzmq":
    command => "git clone https://github.com/nathanmarz/jzmq.git",
    cwd => "/opt/jzmq",
    alias => "download-jzmq",
    creates => "/opt/jzmq/jzmq",
    user => "${storm_user}",
    require => Package["git"],
    path    => ["/bin", "/usr/bin", "/usr/sbin"],
  }

  exec { "autogen_jzmq":
    command => "./autogen.sh",
    cwd => "/opt/jzmq/jzmq",
    alias => "autogen-jzmq",
    user => "${storm_user}",
    require => Exec["download_jzmq"],
    path    => ["/bin", "/usr/bin", "/usr/sbin", "/opt/jzmq/jzmq"],
    logoutput => true,
  }

  exec { "config_jzmq":
    command => "./configure",
    cwd => "/opt/jzmq/jzmq",
    environment => "JAVA_HOME=${java_home}",
    alias => "config-jzmq",
    user => "${storm_user}",
    require => Exec["autogen_jzmq"],
    path    => ["/bin", "/usr/bin", "/usr/sbin", "/opt/jzmq/jzmq"],
    logoutput => true,
  }

  file { "/opt/jzmq/jzmq/src/classdist_noinst.stamp":
    owner => "${storm_user}",
    group => "${storm_group}",
    mode => "644",
    content => "",
    require => Exec["config_jzmq"],
    alias => "touch_classdist",
  }

  exec { "make_trick_jzmq":
    command => "javac -d . org/zeromq/ZMQ.java org/zeromq/ZMQException.java org/zeromq/ZMQQueue.java org/zeromq/ZMQForwarder.java org/zeromq/ZMQStreamer.java",
    cwd => "/opt/jzmq/jzmq/src",
    environment => "CLASSPATH=.:./.:$CLASSPATH",
    alias => "make-trick-jzmq",
    user => "${storm_user}",
    require => File["touch_classdist"],
    path    => ["/bin", "/usr/bin", "/usr/sbin", "/opt/jzmq/jzmq", "${java_home}/bin"],
    logoutput => true,
  }

  exec { "make_jzmq":
    command => "make",
    cwd => "/opt/jzmq/jzmq",
    alias => "make-jzmq",
    user => "${storm_user}",
    require => Exec["make-trick-jzmq"], 
    path    => ["/bin", "/usr/bin", "/usr/sbin"],
    logoutput => true,
  }

  exec { "install_jzmq":
    command => "sudo make install",
    cwd => "/opt/jzmq/jzmq",
    alias => "install-jzmq",
    require => Exec["make_jzmq"],
    path    => ["/bin", "/usr/bin", "/usr/sbin"],
  }

  #  group { "remove_group_storm":
  #    name   => '${storm_group}',
  #    ensure => absent,
  #  }

  group { "${storm_group}":
    ensure  => present,
    #require => Group['remove_group_storm'],
    gid     => "802"
  }

  #  user { "remove_user_storm":
  #    name   => "${storm_user}",
  #    ensure => absent,
  #    uid => "803",
  #    gid => "802",
  #    shell => "/bin/bash",
  #    home => "${storm_user_path}",
  #  }

  user { "${storm_user}":
    ensure => present,
    comment => "Storm",
    password => "!!",
    uid => "803",
    gid => "802",
    shell => "/bin/bash",
    home => "${storm_user_path}",
    require => Group["${storm_group}"],
  }

  file { "${storm_user_path}/.bashrc":
    ensure => present,
    owner => "${storm_user}",
    group => "${storm_group}",
    alias => "${storm_user}-bashrc",
    content => template("storm/home/bashrc.erb"),
    require => [ User["${storm_user}"], File["${storm_user}-home"] ]
  }

  file { "${storm_user_path}":
    ensure => "directory",
    owner => "${storm_user}",
    group => "${storm_group}",
    alias => "${storm_user}-home",
    require => [ User["${storm_user}"], Group["${storm_group}"] ]
  }

  file { "${storm_local_path}":
    ensure => "directory",
    owner => "${storm_user}",
    group => "${storm_group}",
    require => [ User["${storm_user}"], Group["${storm_group}"] ]
  }

  file {"${storm_base}":
    ensure => "directory",
    owner => "${storm_user}",
    group => "${storm_group}",
    alias => "storm-base",
  }

  file {"${storm_conf}":
    ensure => "directory",
    owner => "${storm_user}",
    group => "${storm_group}",
    alias => "storm-conf",
    require => [File["storm-base"], Exec["unzip-storm"]],
    before => [ File["storm-yaml"] ]
  }

  file { "${storm_base}/storm-${version}.zip":
    mode => 0644,
    owner => "${storm_user}",
    group => "${storm_group}",
    source => "puppet:///modules/storm/storm-${version}.zip",
    alias => "storm-source-zip",
    before => Exec["unzip-storm"],
    require => File["storm-base"]
  }

  package { 'unzip':
    ensure  => installed,
    require => File['storm-source-zip'],
  }

  exec { "unzip storm-${version}.zip":
    command => "unzip storm-${version}.zip",
    cwd => "${storm_base}",
    creates => "${storm_base}/storm-${version}",
    alias => "unzip-storm",
    refreshonly => true,
    subscribe => File["storm-source-zip"],
    user => "${storm_user}",
    before => [ File["storm-symlink"], File["storm-app-dir"]],
    require => Package['unzip'],
    path    => ["/bin", "/usr/bin", "/usr/sbin"],
  }

  file { "${storm_base}/storm-${version}":
    ensure => "directory",
    mode => 0644,
    owner => "${storm_user}",
    group => "${storm_group}",
    alias => "storm-app-dir",
    require => Exec["unzip-storm"],
  }

  file { "${storm_base}/storm":
    force => true,
    ensure => "${storm_base}/storm-${version}",
    alias => "storm-symlink",
    owner => "${storm_user}",
    group => "${storm_group}",
    require => File["storm-source-zip"],
    before => [ File["storm-yaml"] ]
  }

  file { "${storm_base}/storm-${version}/conf/storm.yaml":
    owner => "${storm_user}",
    group => "${storm_group}",
    mode => "644",
    alias => "storm-yaml",
    require => File["storm-app-dir"],
    content => template("storm/conf/storm.yaml"),
  }

}
