#/bin/bash

if [ $# -eq 0 ]
then
	echo "Usage: $0 HOSTNAME"
	exit 1
fi

NODE=$1

echo "free $NODE (may have been allocated by another user)"
tb allocations free -f -n $NODE
sleep 1

echo "allocate $NODE"
tb allocations allocate $NODE
sleep 1

echo "shutdown $NODE"
tb nodes reset $NODE
sleep 5

#Upload work script on testserver and start it

scp testserver.sh $NODE:
scp setupIP2.sh $NODE:
ssh $NODE 'chmod +x testserver.sh; chmod +x setupIP2.sh; ./setupIP2.sh; ./testserver.sh' 






# TODO (when controller is finished) free machines at end of test
# tb allocations free -n $NODE
