#!/bin/bash                                                                     
                                                                                
if [ $# -eq 0 ]                                                                 
then                                                                            
        echo "Usage: $0 HOSTNAME"                                               
        exit 1                                                          
fi                                                              
NODE=$1


for i in {60..65507}
do
    ssh $NODE 'cd MoonGen;./build/MoonGen ./examples/l3-load-latency.lua -s $i 0 1'
done
