# Requiremenst 
## Software
* node js 0.8 or later http://nodejs.org/
* npm 1.2.x or later https://npmjs.org
* python
* java 
* solr 4.4.0 http://lucene.apache.org/solr/
* curl 
* libvirt
* mysqlclient 
* screen (temporary, while in alpha/development)

## Also: 
 *	Compute nodes must be resolvalbe by the hostname from the client machine. For hacking, add them to /etc/hosts. 
 *	ssh key access must be configured to compute nodes.  [Instructions here](https://github.com/dzimine/Couch_to_OpenStack/blob/dev/with-ssh/ssh-setup.sh)
 *	AMQP notifications shall be enabled on compute nodes. This is what [Ceilometer is also requiring](http://docs.openstack.org/developer/ceilometer/install/manual.html#installing-the-compute-agent). Have to restart `nova-compute`on compute nodes to pick up the change. 


# Install, Configure and run capacity dashboard

Get from dropbox, 
	ADD LINK HERE
unzip to $CAPACITY directory.
	
	tar -zxf capacity-dashboard.tar.gz 
	

## Install prerequisites
Scripted pre-requisit installation is in `$CAPACITY/install-prereqs.sh`. Details:

### node
	sudo apt-get update
	sudo apt-get install python-software-properties python g++ make
	sudo add-apt-repository ppa:chris-lea/node.js
	sudo apt-get update
	sudo apt-get install -y nodejs
	# Check
	node --versoin
	> v0.10.18
	npm --version 
	> 1.3.8

### java
	sudo apt-get install python-software-properties python g++ make
	sudo add-apt-repository ppa:webupd8team/java
	sudo apt-get update
	# state that you accepted the license 
	echo debconf shared/accepted-oracle-license-v1-1 select true | sudo debconf-set-selections
	echo debconf shared/accepted-oracle-license-v1-1 seen true | sudo debconf-set-selections
	sudo apt-get install oracle-java7-installer
	# Check
	java -version
	> java version "1.7.0_40"

### Install libvirt, libxml mysql client, curl, python
	sudo apt-get install -y libvirt-bin python-libvirt
	sudo apt-get install -y libxml2-dev libxslt1-dev
	sudo apt-get install -y libmysqlclient-dev
	sudo apt-get install -y curl
	sudo apt-get install -y python-dev python-pip python-virtualenv

### Screen
This is temporary, while developing (will daemonize the processes later).
	
	sudo apt-get install screen

## Configure OpenStack

### Enable Nova notifications vi RabbitMQ
We use the same mechanism as Ceilometer, and [asking for the same change](http://docs.openstack.org/developer/ceilometer/install/manual.html#installing-the-compute-agent). The AMQP notifications must be enabled on each compute node

* Edit `/etc/nova/nova.conf` file, in the DEFAULT section add the line:	`notification_driver=nova.openstack.common.notifier.rabbit_notifier`
By default it is disabled or [commented out] See [nova.conf sample](https://github.com/openstack/nova/blob/master/etc/nova/nova.conf.sample) on openstack github.

* Restart nova-compute on each compute node for the config to take effect:

		sudo stop nova-compute
		sudo start noav-compute

### Configure ssh access to compute nodes
Client machine must be able to ssh to libvirt on each compute node.
On each compute node: 

* configure the 'theuser', with ssh access and a member of libvirt group
	$ sudo usermod -G libvirtd -a theuser
* create and deploy SSH public keys, for passwordless access to compute nodes ([sample here](https://github.com/dzimine/Couch_to_OpenStack/blob/dev/with-ssh/ssh-setup.sh) )
* Test  that it all works. From client machine, fire: 
 
		virsh -c  qemu+ssh://theuser@172.16.80.201/system?socket=/var/run/libvirt/libvirt-sock list
It shall list instances running on the node. 

## Configure Capacity dashboard

1. Install python dependencies 

		cd osh
		./setup.sh
This must end with: `"Successfully installed configparser eventlet kombu librabbitmq pysolr lxml httplib2 sqlalchemy mysql-python nose mock greenlet anyjson amqp requests
Cleaning up…"`

1. Install node dependencies
		
		cd osh-ui
		npm install
This must end without errors. Warnings are OK. 

1. Edit the front-end config file, update connection info and credentials to nova DB.

		vi osh-ui/config/production.yml
	
1. Edit the backend config file, update connection info and credentials for nova DB, and RabbitMQ server (typically, on controller node)

		vi osh/config/config.ini

		nova_db_server=172.16.80.200
		nova_db_port=3306
		# Read only user for nova DB
		nova_db_creds=user:password
		amqp_server=172.16.80.200
		amqp_port=5672
		# AMQP credentials to listen to notifiations (this is default credentials. If different, look them up in nova.conf)
		amqp_creds=guest:guest
		# SSH user for libvirt access to compute nodes
		libvirt_user=theuser

## Run (manually) 
* TODO: script screen start
* TODO: figure how to use screen properly

### Start solr
	cd osh-data/inventory/solr
	./solr_testrun.sh
	# wait for about 10 sec for solr to launch up
 	# if you see this output, check the url
 	# if not, troubleshoot
	====================================================
	OK :)
	Solr installed, configured, tested, and running
	Go to http://localhost:8983/solr
	For output: tail -f -20 solr.out
	To shut down: ./kill.sh

	# log is in solr.out
	# ctrl+a, d - To detach from screen and keep it running on background

### start osh 
	screen -S osh
	cd osh
	./run.sh
	# logs is in osh/logs/
	# ctrl+a, d - To detach from screen and keep it running on background

### start ui
	screen -S ui
	cd osh-ui
	npm start
	# ctrl+a, d - To detach from screen and keep it running on background

### It should be working

	http://host:9000/#/capacity
