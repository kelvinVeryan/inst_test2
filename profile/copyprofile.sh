#!/bin/bash
mkdir -p etc/default/
mkdir -p etc/hostapd
mkdir -p etc/network
cp -a /etc/network/interfaces ./etc/network
cp -a /etc/udhcpd.conf ./etc/
cp -a /etc/default/udhcpd ./etc/default/
cp -a /etc/default/hostapd  ./etc/default/
cp -a /etc/hostapd/hostapd.conf ./etc/hostapd
