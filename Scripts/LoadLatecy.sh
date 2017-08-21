#!/bin/bash                                                                     
                                                                                
if [ $# -eq 0 ]                                                                 
then                                                                            
        echo "Usage: $0 HOSTNAME"                                               
        exit 1                                                          
fi                                                              
NODE=$1

#i for packet size
#j for number of flows
#k for transmit rate
for i in {84..65507}
do
for j in {1..2000}
do 
for k in {1..10000}
do
    ssh $NODE 'cd MoonGen;./build/MoonGen ./examples/l3-load-latency.lua -s $i -f $j -r $k 0 1'
    ssh $NODE 'cd MoonGen;cp histogram.csv ../results/histogram_Size-$i_Flows-$j_Rate-$k.csv'
done
done
done
