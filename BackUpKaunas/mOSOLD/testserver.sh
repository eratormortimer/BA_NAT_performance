#!/bin/bash

### VARIABLES ###
# example_variable: type, description
###

#Install Moongen for load-testing and bind it to the interface to the testserver
apt-get update                                                                  
apt-get install cmake -y                                                        
apt-get install libpci-dev -y                                                   
apt-get install dpdk -y                                                        
git clone https://github.com/emmericp/MoonGen
