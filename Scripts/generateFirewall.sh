#!/bin/bash
for i in {0..3}
do
for j in {1..255}
do
   echo ACCEPT $'\t' 192.168.$i.$j $'\t' 10.0.0.1  >> firewallRules 
done
done
