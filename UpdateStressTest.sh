#!/bin/bash
#
# depends: devmem 

# cycle times , default 500
EXP_COUNT=500

LOG_CYCLE=/var/log/cycle.log
LOG_VER=/var/log/last_version.log
LOG_INFO=/var/log/update.log
CURRENT_VERSION=$(devmem 0xe4020000|grep "0xE4020000"|awk -F " " '{print $6}')
#prefix="0x"
FPGA_VERSION_A="Production_8003.bin"
FPGA_VERSION_B="Production_8005.bin"

#check fpga last version
if [ ! -f $LOG_VER ]; then
	touch $LOG_VER
fi

#check count.log exist or not
if [ ! -f $LOG_CYCLE ]; then
	touch $LOG_CYCLE
	echo 1 > $LOG_CYCLE
	sleep 1
fi

# check log info file exist
if [ ! -f $LOG_INFO ]; then
	touch $LOG_INFO
fi

# check whether the frist time cycle update
PREVIOUS_VERSION=`cat $LOG_VER`

if [ -z $PREVIOUS_VERSION ]; then
	echo "----------------------------------- Start fpga update cycle test -----------------------------------" > $LOG_INFO
	echo 1 > $LOG_CYCLE

fi

COUNT=`cat $LOG_CYCLE`

# update process fucntion
function update()
{
	# show timecard driver information
	dmesg | grep ptp_ocp
	
	echo ""
	# prepare update fpga
	echo "check current fpga version and last version"
	if [[ "$PREVIOUS_VERSION" == "$CURRENT_VERSION" ]]; then
		echo "current version ($CURRENT_VERSION) is same with last verion($PREVIOUS_VERSION), update failed!"
		exit -1
	fi

	echo ""
	echo -e "Current version is $CURRENT_VERSION, starting update image ... \n"
	if [ "$CURRENT_VERSION" == "0x8005" ]; then
		echo "*********************Upgrade FPGA version($FPGA_VERSION_A)*************************"
		devlink dev flash pci/0000:11:00.0 file $FPGA_VERSION_A
	elif [ "$CURRENT_VERSION" == "0x8003" ]; then
		echo "*********************Upgrade FPGA version($FPGA_VERSION_B)*************************"
		devlink dev flash pci/0000:11:00.0 file $FPGA_VERSION_B
	else
		echo "Can't uddate FPGA image"
		exit 1
	fi
	# save version info
	echo $CURRENT_VERSION > $LOG_VER
	echo -e "\n*******************************Upgrade FPGA image completed.***********************************\n"
}

# main execute function
function main()
{
    sleep 1
    echo -e "\n======================== Test Loop $COUNT=============================\n" >> $LOG_INFO
    if [ $COUNT -le $EXP_COUNT ]; then
        COUNT=$(($COUNT+1))
        echo $COUNT > $LOG_CYCLE
        sync

        update >> $LOG_INFO
        sleep 30

        echo "reboot system ......"
        reboot
    fi
}

main &

