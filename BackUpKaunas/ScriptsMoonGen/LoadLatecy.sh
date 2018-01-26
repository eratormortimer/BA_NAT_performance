#!/bin/bash                                                            

#Test with smallest packet size, with different flow lengths and in the area of the interessting transmit rate


DATE=$(date "+%y_%m_%d_%R")
######
#Define your array of transmit rates
#array=(100 200 300 400 500 600 700 800 900 1000 1100 1200 1300 1400 1500 1600 1700 1800 1900 2000 3000 4000 5000 6000 7000 8000 9000 10000)
array=(200 220 240 260 280 300 320 340 360 380 400 420 440 460 480 500 520 540 560 580 600 620 640 660 680 700 720 740 760 780 800)
#Define array for flows (here we will choose 5 different flow length just to see if there are differences
arrayFlow=(80000 90000 100000 110000)
#####


n=1
for j in ${arrayFlow[*]};
    do
    ssh -p 10022 sternsdo@172.16.0.1 "mkdir /srv/testbed/results/manual_test_sternsdo/OVSNATStresstestMinPacketsizeFlow$j/"
        for i in ${array[*]};
        do
                cd /root/MoonGen
                echo "starting MoonGen with Rate $i"
                echo "start $(date)" >> output
                echo "$(./build/MoonGen ./examples/l3-load-latency.lua -r $i -f $j 1 0 & sleep 60 ; kill -INT $!)" >> output
                echo "finished with Moongen"
                sleep 20
                echo "end $(date)" >> output
                scp -P 10022 output sternsdo@172.16.0.1:/srv/testbed/results/manual_test_sternsdo/OVSNATStresstestMinPacketsizeFlow$j/output-send$n
                scp -P 10022 histogram.csv sternsdo@172.16.0.1:/srv/testbed/results/manual_test_sternsdo/OVSNATStresstestMinPacketsizeFlow$j/hist$n.csv
                echo "uploaded everything"
                rm output
                rm histogram.csv
                n=$(( $n+1 ))
        done
    n=1
    done
