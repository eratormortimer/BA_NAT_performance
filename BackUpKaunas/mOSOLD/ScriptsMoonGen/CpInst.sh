#!/bin/bash 

if [ $# -eq 0 ]                                                                 
then                                                                            
        echo "Usage: $0 HOSTNAME"                                               
	exit 1                                                                  
fi                                                                              
		                                                                                
NODE=$1 

scp MoonGenDeps.sh $NODE:				
scp MoonGen.zip $NODE:
ssh $NODE 'chmod +x MoonGenDeps.sh;./MoonGenDeps.sh;unzip MoonGen.zip;cd MoonGen;./build.sh;./setup-hugetlbfs.sh'
