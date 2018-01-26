#!/bin/sh
ifdown eth2
ifdown eth3
rmmod ixgbe
rmmod netmap_lin
insmod ./netmap_lin.ko
mknod /dev/netmap c 10 59
modprobe mdio 
insmod ./ixgbe/ixgbe.ko
ifup eth2
ifup eth3
