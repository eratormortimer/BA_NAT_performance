#!/bin/bash
apt-get update
apt-get install cmake -y
apt-get install libnuma-dev -y
apt-get install libpci-dev -y
apt-get install pciutils -y
apt-get install dpdk -y
apt-get install unzip -y
apt-get install git -y
apt-get install vim -y
apt-get install tshark -y
unzip MoonGen.zip
cd MoonGen
./build.sh
./setup-hugetlbfs.sh

