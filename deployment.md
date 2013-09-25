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
Scripted pre-requisit installation is in [`deploy/install-prereqs.sh`](https://github.com/dzimine/deploy/blob/master/install-prereqs.sh). 
Run the script, or install manually using the script as a check-list.


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
	1. On the client host (hosting the StackStorm app): create keypair and register private key for ssh
			
			ssh-keygen -t rsa -N "libvirt access" -P "" -f id_rsa_libvirt
			cp id_rsa_libvirt ~/.ssh/
			cp id_rsa_libvirt.pub ~/.ssh/ #one day you'll want to delete it and need pub for this
			# May be needed to fix fix 
			# the "Could not open a connection to your authentication agent."
			eval $(ssh-agent)
			# Add key to ssh-agent
			ssh-add ~/.ssh/id_rsa_libvirt
	2. On target server(s) (compute nodes): deploy public key for our ssh user `theuser`
	
			sudo -u theuser cat id_rsa_libvirt.pub >>/home/theuser/.ssh/authorized_keys

* Test  that it works. From client machine, fire: 
 
			virsh -c  qemu+ssh://theuser@172.16.80.201/system?socket=/var/run/libvirt/libvirt-sock list
It shall list instances running on the node. 

## Configure Capacity dashboard

1. Install python dependencies 

		cd osh
		./setup.sh
This must end with: `"Successfully installed configparser eventlet kombu librabbitmq pysolr lxml httplib2 sqlalchemy mysql-python nose mock greenlet anyjson amqp requests
Cleaning up…"`

1. Edit the front-end config file, update connection info and credentials to OpenStack MySQL DB.

		vi osh-ui/config/production.yml
This file also contains default thresholds, and the web client port (default 9000)
	
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
