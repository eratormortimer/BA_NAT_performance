#!/bin/bash
ip a add 10.0.0.2/24 broadcast 10.0.0.255 dev ethC1
ip l set ethC1 up
ip a add 192.168.0.2/24 broadcast 192.168.0.255 dev ethC2
ip l set ethC2 up
