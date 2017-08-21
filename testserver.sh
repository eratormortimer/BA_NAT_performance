#!/bin/bash

### VARIABLES ###
# example_variable: type, description
###

#Install Moongen for load-testing and bind it to the interface to the testserver
testbed-install archive MoonGen

deps/dpdk/tools/dpdk_nic_bind.py --force --bind igb_uio <INTERFACE>
