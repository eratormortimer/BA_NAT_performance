#!/bin/sh


#Source: https://software.intel.com/sites/default/files/comment/1716807/how-to-change-frequency-on-linux-pub.txt

if [ "x$1" == "x" ]
then
echo "have to enter a frequency. Available frequencies are:"
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_frequencies
exit
fi

echo "Available frequencies are:"
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_frequencies

# see http://www.thinkwiki.org/wiki/How_to_make_use_of_Dynamic_Frequency_Scaling

cpucount=`cat /proc/cpuinfo|grep processor|wc -l`

# load the governors if compiled as modules
modprobe cpufreq_performance cpufreq_ondemand cpufreq_conservative cpufreq_powersave cpufreq_userspace

FLROOT=/sys/devices/system/cpu

echo "display available governors"
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors

echo "display current cpu0 governor"
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor


METHOD=0 # 0=use setspeed, 1=use min max
i=0
while [ $i -ne $cpucount ]
do
	if [ $METHOD == 0 ]; then
		FLNM="$FLROOT/cpu"$i"/cpufreq/scaling_governor"
		echo "Setting $FLNM to " userspace
		echo userspace > $FLNM
		FLNM="$FLROOT/cpu"$i"/cpufreq/scaling_setspeed"
		echo "Setting freq $FLNM to " $1
		echo $1 > $FLNM
	else
		echo "Setting freq $FLROOT/cpu"$i"/cpufreq/cpuinfo_max_freq to " $1
		FLNMAX="$FLROOT/cpu"$i"/cpufreq/cpuinfo_max_freq"
		FLNMIN="$FLROOT/cpu"$i"/cpufreq/cpuinfo_min_freq"
		echo $1 > $FLNMAX
		echo $1 > $FLNMIN
	fi
	i=`expr $i + 1`
done 

# RedHat EL4 64 bit all kernel versions have cpuid and msr driver built in. 
# You can double check it by looking at /boot/config* file for the kernel installed. 
# And look for CPUID and MSR driver config option. It it says 'y' then it is 
# builtin the kernel. If it says 'm', then it is a module and modprobe is needed.


echo check cpu freq in /proc/cpuinfo
cat /proc/cpuinfo |grep -i mhz
