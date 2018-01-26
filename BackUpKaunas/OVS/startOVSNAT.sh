#!/bin/bash
trap "set +x; sleep 5; set -x" DEBUG
cd /root/openvswitch-2.7.0
ovs-ofctl add-flow br0 "table=0,priority=1,action=drop"
ovs-ofctl add-flow br0 "table=0,priority=10,arp,action=normal"
ovs-ofctl add-flow br0 "table=0,priority=100,ip,ct_state=-trk,action=ct(table=1)"
ovs-ofctl add-flow br0 "table=1,in_port=2,ip,action=ct(commit,zone=1,nat(src=200.200.200.200)),1"
ovs-ofctl add-flow br0 "table=1,in_port=1,ct_state=+trk+new,action=drop"
ovs-ofctl add-flow br0 "table=1,in_port=1,ct_state=+trk+est,ip,action=ct(nat),2"
ovs-ofctl add-flow br0 "table=1,in_port=2,ct_state=+trk+est,ip,action=ct(nat),1"

