#!/bin/bash
apt-get update -y 
apt-get install linux-headers-$(uname -r) -y
apt-get install libnuma-dev -y
apt-get install libc6 -y
apt-get install libssl-dev -y
apt-get install libglib2.0-0 -y
#apt-get install libdpdk-dev -y
apt-get install pciutils -y
apt-get install unzip -y
apt-get install make -y
apt-get install gcc -y
apt-get install coreutils -y
apt-get install libpcap-dev -y
apt-get install vim -y
apt-get install tshark -y
