# Pre-requirements for Debian/Ubuntu
# Tested on Ubuntu 12.04

# Node JS and NPM
sudo apt-get -y update
sudo apt-get -y install python-software-properties python g++ make
sudo add-apt-repository -y ppa:chris-lea/node.js
sudo apt-get update
sudo apt-get install nodejs
# Check
node --version
# v0.10.18
npm --version 
# 1.3.8


# Java
#
# sudo apt-get install -y python-software-properties python g++ make
# 
sudo add-apt-repository -y ppa:webupd8team/java
sudo apt-get update
# state that you accepted the license 
echo debconf shared/accepted-oracle-license-v1-1 select true | sudo debconf-set-selections
echo debconf shared/accepted-oracle-license-v1-1 seen true | sudo debconf-set-selections
sudo apt-get install -y oracle-java7-installer
# Check
java -version
#> java version "1.7.0_40"

### Install libvirt, libxml mysql client, curl, python
sudo apt-get install -y libvirt-bin python-libvirt
sudo apt-get install -y libxml2-dev libxslt1-dev
sudo apt-get install -y libmysqlclient-dev
sudo apt-get install -y curl
sudo apt-get install -y python-dev python-pip python-virtualenv

# Screen 
# This is temporary, while developing (will daemonize the processes later).
sudo apt-get install screen
which screen


  