#!/bin/bash
cd /root/openvswitch-2.7.0
export DPDK_BUILD=/usr/src/dpdk-16.11/x86_64-native-linuxapp-gcc
./configure --with-dpdk=$DPDK_BUILD
make 
make install
export DB_SOCK=/usr/local/var/run/openvswitch/db.sock
export PATH=$PATH:/usr/local/share/openvswitch/scripts
ovs-ctl --no-ovsdb-server --db-sock="$DB_SOCK" --system-id=test start
#mkdir -p /usr/local/var/run/openvswitch
#ovsdb-server --remote=punix:/usr/local/var/run/openvswitch/db.sock --remote=db:Open_vSwitch,Open_vSwitch,manager_options --pidfile --detach --log-file
ovs-vsctl --no-wait set Open_vSwitch . other_config:dpdk-init=true
ovs-vsctl --no-wait set Open_vSwitch . other_config:dpdk-socket-mem="1024"
#ovs-ctl --no-ovsdb-server --db-sock="$DB_SOCK" start
ovs-vsctl add-br br0 -- set bridge br0 datapath_type=netdev
#Change PCI if necessary
ovs-vsctl add-port br0 dpdk-p0 -- set Interface dpdk-p0 type=dpdk options:dpdk-devargs=0000:02:00.0
ovs-vsctl add-port br0 dpdk-p1 -- set Interface dpdk-p1 type=dpdk options:dpdk-devargs=0000:02:00.1
ovs-ofctl add-flow br0 "in_port=1,action=output:2"
ovs-ofctl add-flow br0 "in_port=2,action=output:1"

