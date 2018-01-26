#!/bin/bash

if [ $# -eq 0 ]                                                                 
then                                                                            
	echo "Usage: $0 HOSTNAME"                                               
	exit 1                                                                  
fi                                                                              
		                                                                                
NODE=$1 


scp MOSGIT.zip $NODE:
ssh $NODE 'unzip MOSGIT.zip;cd mOS-networking-stack-master;yes | ./setup.sh --compile-dpdk'

