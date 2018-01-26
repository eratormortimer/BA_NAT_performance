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



#copy files for NAT setup and execute them
scp testNAT.sh $NODE:
scp setupIP1.sh $NODE:
ssh $NODE 'chmod +x setupIP1.sh; chmod +x testNAT.sh; ./setupIP1.sh; testNAT.sh'




# TODO (when controller is finished) free machines at end of test
# tb allocations free -n $NODE
