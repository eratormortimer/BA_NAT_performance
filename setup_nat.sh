#!/bin/bash

### VARIABLES ###
# example_variable: type, description
###

###basic natting with iptables, ethX still not sure

echo 1 > /proc/sys/net/ipv4/ip_forward


/sbin/iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
/sbin/iptables -A FORWARD -i eth0 -o eth1 -m state
   --state RELATED,ESTABLISHED -j ACCEPT
/sbin/iptables -A FORWARD -i eth1 -o eth0 -j ACCEPT
