#!/bin/bash

#source /opt/EMSTS/scripts/bbb/gpio

#PIN_LTE5V_EN=216  # LTE_BUF_OE
#PIN_LTEVBAT_EN=19
#PIN_W_DISABLE=194
PIN_PWRKEY=49
# High reset
PIN_RESET=60
#PIN_WAKEUP_IN=50
#PIN_ANTENNA=232   # VDD_ANT_GNSS_EN
#PIN_AP_READY=14
#PIN_LTE_STATUS=72
MODEM_TTY="/dev/ttyS4"

config-pin p9_11 uart
config-pin p9_13 uart

function gpio() {
	echo "gpio $1 $2"
	echo out > /sys/class/gpio/gpio$2/direction
	if [ $1 = "clear" ]; then
		echo 0 > /sys/class/gpio/gpio$2/value
	fi
	if [ $1 = "set" ]; then
		echo 1 > /sys/class/gpio/gpio$2/value
	fi
}

function quectel_poweronoff() {
	# Power
	# disable LTE VBAT
	# gpio clear $PIN_LTEVBAT_EN

	# enable GNSS ANTENNA power
	#gpio clear $PIN_ANTENNA
	# disable  LTE 5V
	#gpio clear $PIN_LTE5V_EN
	#sleep 0.1

	# enable LTE VBAT
	#
	# VBAT always powered in the circuit.
	# gpio set $PIN_LTEVBAT_EN
	sleep 0.1

	# deassert RESET
	gpio clear $PIN_RESET
	# disable Airplane mode
	#gpio set $PIN_W_DISABLE
	# stay in WAKEUP state
	#gpio clear $PIN_WAKEUP_IN

	# Power On
	gpio clear $PIN_PWRKEY
	sleep 0.1
	gpio set $PIN_PWRKEY
	sleep 0.6
	gpio clear $PIN_PWRKEY
	sleep 0.1

	# issue Sleep
	# gpio set $PIN_WAKEUP_IN
	# enable  LTE 5V
	#gpio set $PIN_LTE5V_EN
}


quectel_poweronoff
#gpio clear $PIN_AP_READY

sleep 1
is_on=0
#if [ ! -c "$MODEM_TTY" ]; then
#	is_on=1
#fi
is_on=1

: <<\COMMENT
for ((i = 0; i < 20; i++)); do
	v=$(gpio input $PIN_LTE_STATUS)
	if [ "$v" -eq "0" ]; then
		is_on=1
		break
	fi
	sleep 0.3
done
COMMENT

if [ "$is_on" -ne "0" ]; then
	#echo -ne "Power up LTE module"
	echo "Power up LTE module"
	for ((i = 0; i < 50; i++)); do
		if [ -c "$MODEM_TTY" ]; then
			break;
		fi
		sleep 0.5
		echo -ne "."
	done
	echo "OK"
	exit 0
fi

echo -ne "Power off LTE module"
# Wait the LTE module power down completely
for ((i = 0; i < 30; i++)); do
	sleep 1
	echo -ne "."
done
echo "OK"
exit 1

