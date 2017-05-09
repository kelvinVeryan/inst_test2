#!/bin/bash
# script function: 1 . update mac address at /etc/network/intefaces file. 
# 		   2 . update config file mac deviceinfo for hostapd and udhcpd.conf 
# base : 1. ifconfig info
# 	 2. /etc/network/interfaces have "map 00"(ap) and "map e8"(sta) info.
# Auther: kelvin
# 

#set -v on
debug=1
# init info
wlan0mac=""
wlan1mac=""
stadev=""
apdev=""

#map  00:13:ef:00:18:a4 wlan_ap
#map  e8:4e:06:45:2f:98 wlan_sta

# update /etc/network/interface mac info 
function update_apmac {
	echo "apmac : $1"
	macres=`cat /etc/network/interfaces | grep "map  $1"`
	if [ "$macres" = "" ];then
		echo "ap device is change , update mac"
		cat /etc/network/interfaces | sed s/"map  00.*"/"map  $1 wlan_ap"/g > /etc/network/interfaces_new
		mv /etc/network/interfaces_new /etc/network/interfaces
	else
		echo "ap device is ok. not update"
	fi
}

function update_stamac {
	echo "stamac : $1"
	macres=`cat /etc/network/interfaces | grep "map  $1"`
	if [ "$macres" = "" ];then
		echo "sta device is change , update mac"
		cat /etc/network/interfaces | sed s/"map  e8.*"/"map  $1 wlan_sta"/g > /etc/network/interfaces_new
		mv /etc/network/interfaces_new /etc/network/interfaces
	else
		echo "sta device is ok. not update"
	fi
}

function update_ap
{
	echo "update_ap function: $1";
	if [ ! -f /etc/udhcpd.conf ];then
		echo " Not found udhcpd.conf."
	else 	
		if [ "`cat /etc/udhcpd.conf | grep $1`" = "" ];then
			echo "swap udhcpd.conf to $1";
			sudo cat /etc/udhcpd.conf | sed "s/wlan./$1/g">/etc/udhcpd.conf_new
			sudo mv /etc/udhcpd.conf_new /etc/udhcpd.conf;
		else
			echo "/etc/udhcpd.conf correct";
		fi
	fi
	if [ ! -f /etc/hostapd/hostapd.conf ];then
		echo " Not found hostapd.conf."
	else
		if [ "`cat /etc/hostapd/hostapd.conf | grep $1`" = "" ];then
			echo "swap /etc/hostapd/hostapd.conf  to $1";
			sudo cat /etc/hostapd/hostapd.conf | sed "s/wlan./$1/g" > /etc/hostapd/hostapd.conf_new
			sudo mv /etc/hostapd/hostapd.conf_new /etc/hostapd/hostapd.conf;
		else
			echo "/etc/hostapd/hostapd.conf correct.";
		fi
	fi
}

# main start . Get Mac address
wlan0mac=`ifconfig | grep "wlan0" | awk '{print $5}'`
wlan1mac=`ifconfig | grep "wlan1" | awk '{print $5}'`


if [ "${wlan0mac%%:*}" = "00" ];then
	apdev="wlan0"
	stadev="wlan1"
else 
	if [ "${wlan1mac%%:*}" = "00" ];then
		apdev="wlan1"
		stadev="wlan0"
	else
		echo "wlan0mac :$wlan0mac . wlan1mac:$wlan1mac"
		echo " Warning : device mac address is error. please check."
		exit -1
	fi
fi 

if [ $debug = "1" ];then 
	echo "wlan0mac :$wlan0mac . wlan1mac:$wlan1mac"
	echo ${wlan0%%:*}
	echo "apdev: $apdev. stadev:$stadev."
fi

if [[ "$wlan1mac" = "" && "$wlan0mac" = "" ]];then
	echo "Not Found wlan1 and wlan0. will exit"
	exit -2
fi

if [ "$wlan1mac" = "" ];then
	echo "Warning : Not Found wlan1 device."
	# ap or sta
	if [ "${wlan0mac%%:*}" = "00" ];then
		update_apmac $wlan0mac
		wlan1mac="e8:e8:e8:e8:e8:e8"
		update_stamac $wlan1mac
		echo "will update ap wlan0device"
		update_ap wlan0 $wlan0mac;
		echo "Not sta set, please check and fix sta configure"
	else
		wlan1mac="00:00:00:00:00:01"
		update_apmac $wlan1mac
		update_stamac $wlan0mac
		echo "Not ap set, please check and fix ap configure"
	fi
else
	echo "Device is : wlan1 and wlan0."
	if [ "${wlan0mac%%:*}" = "00" ];then
		update_apmac $wlan0mac
		update_stamac $wlan1mac
		echo "will update ap wlan0device"
		update_ap wlan0 $wlan0mac;
	else
		update_apmac $wlan1mac
		update_stamac $wlan0mac
		echo "will update ap wlan1device"
		update_ap wlan1 $wlan1mac;
	fi
fi
