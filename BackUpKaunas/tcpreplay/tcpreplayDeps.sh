#!/bin/bash
apt-get update
sudo apt-get install dpkg-dev -y
apt-get source linux-image-$(uname -r) -y
sudo apt-get install build-essential libpcap-dev -y
wget https://github.com/appneta/tcpreplay/releases/download/v4.2.5/tcpreplay-4.2.5.tar.gz
tar xvf tcpreplay-4.2.5.tar.gz

