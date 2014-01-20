class { 'zookeeper':
    myid => '1',
	package_url => 'http://www.poolsaboveground.com/apache/zookeeper/zookeeper-3.4.5/zookeeper-3.4.5.tar.gz',
	
}

class { 'kafka':
	broker_id => 0,
	hostname => $::ipaddress_eth1, # $::ipaddress is picked by default
	zookeeper_connect => 'localhost:2181',
	package_url => 'http://mirrors.ukfast.co.uk/sites/ftp.apache.org/kafka/0.8.0/kafka_2.8.0-0.8.0.tar.gz',
}
