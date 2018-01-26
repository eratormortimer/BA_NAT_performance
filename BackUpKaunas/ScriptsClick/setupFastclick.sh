#!/bin/bash
cd fastclick-master-8c4851a8f55961ff82427933f2da84cb72a16182
export RTE_SDK=/root/dpdk-2.2.0/
export RTE_TARGET=x86_64-native-linuxapp-gcc
./configure --enable-multithread --disable-linuxmodule --enable-intel-cpu --enable-user-multithread --verbose CFLAGS="-g -O3" CXXFLAGS="-g -std=gnu++11 -O3" --disable-dynamic-linking --enable-poll --enable-bound-port-transfer --enable-dpdk --enable-batch --with-netmap=no --enable-zerocopy --enable-dpdk-pool --disable-dpdk-packet
make
