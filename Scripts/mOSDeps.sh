#!/bin/bash                                                                     
apt-get update                                                                  
apt-get install linux-headers-$(uname -r) -y                                    
apt-get install libnuma-dev -y                                                  
apt-get install libc6 -y                                                        
apt-get install libssl-dev -y                                                   
apt-get install libglib2.0-0 -y                                                 
apt-get install libdpdk-dev -y                                                  
apt-get install pciutils -y                                                     
