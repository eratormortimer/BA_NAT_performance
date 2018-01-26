#!/bin/bash
ip a add 10.0.0.1/24 broadcast 10.0.0.255 dev eth2
ip l set eth2 up
ip a add 192.168.0.1/24 broadcast 192.168.0.255 dev eth3
ip l set eth3 up
