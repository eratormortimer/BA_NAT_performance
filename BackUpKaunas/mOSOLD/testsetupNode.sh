#/bin/bash

if [ $# -eq 0 ]
then
	echo "Usage: $0 HOSTNAME"
	exit 1
fi

NODE=$1

echo "free $NODE (may have been allocated by another user)"
testbed-nodes free -f -s $NODE
sleep 1

echo "allocate $NODE"
testbed-nodes allocate -i ubuntu-16.04 $NODE
sleep 1

echo "shutdown $NODE"
testbed-nodes boot $NODE
sleep 5

# TODO (when controller is finished) free machines at end of test
# tb allocations free -n $NODE
