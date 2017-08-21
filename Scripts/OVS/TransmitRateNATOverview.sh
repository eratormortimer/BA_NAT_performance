#!/bin/bash                                                                     

DATE=$(date "+%y_%m_%d_%R")
ssh -p 10022 sternsdo@172.16.0.1 "mkdir /srv/testbed/results/manual_test_sternsdo/TransmitRate$DATE/"
######
#Define your array of transmit rates
array=(100 200 300 400 500 600 700 800 900 1000 1100 1200 1300 1400 1500 1600 1700 1800 1900 2000 3000 4000 5000 6000 7000 8000 9000 10000)
#####



for i in ${array[*]};
do
    cd /root/MoonGen
    echo "starting MoonGen with Rate $i"
    echo "start $(date)" >> output
    echo "$(./build/MoonGen ./examples/l3-load-latency.lua -r $i -f 2000 1 0 & sleep 60 ; kill -INT $!)" >> output
    echo "finished with Moongen"
    sleep 20
    echo "end $(date)" >> output
    scp -P 10022 output sternsdo@172.16.0.1:/srv/testbed/results/manual_test_sternsdo/TransmitRate$DATE/outputRate_$i
    scp -P 10022 histogram.csv sternsdo@172.16.0.1:/srv/testbed/results/manual_test_sternsdo/TransmitRate$DATE/histogramRate_$i.csv
    echo "uploaded everything"
    rm output
    rm histogram.csv
done
