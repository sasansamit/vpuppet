class java::params {

  $java_version = $::hostname ? {
    default        => "1.7.0_03",
  }
  $java_base = $::hostname ? {
    default     => "/opt/java/",
  }

  $java_home = $::hostname ? {
    default => '/usr/lib/jvm/java-7-oracle',
  }

  $java_bin = $::hostname ? {
    default => "${java_home}/bin",
  }
}
