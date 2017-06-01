#!/bin/bash
# script function: 1. set security system Networking. include ip forword.
#                  2. install develop env. 
#                  3. install njwl\d_p_smarthome\security system.
#                  4. other software. example startup system\toggle kerboard.
# Missing function: 1. mozilla fullscreen.
#
# Auther: kelvin
#
# base : 1. partition ok.
#        2. raspberrypi-config ok. 
#        3. /boot/config ok.
#

mypath=`pwd`
# sudo fdisk -l
# sudo mount /dev/mmcblk0p1 /mnt
# sudo leafpad /mnt/config.txt 
# sudo reboot 

# raspberrypi-config
# sudo reboot

if [ "`whoami`" == "root" ];then
	echo "don't use root priv"
	exit -1
fi

#check file . because github not save NJWL@Pi2.tgz and pdsmart.tgz
if [[ ! -f ${mypath}/OIC_NJWL/pdsmart.tgz || ! -f ${mypath}/OIC_NJWL/NJWL@Pi2.tgz ]];then
	echo "pdsmart.tgz or NJWL@Pi2.tgz missing . please check."
	exit -1
fi

# test network and install software 
dpkgres=1
pipres=1
pingnum=0
ping -c3 g.cn
pingres="$?"
while [ "$pingres" -ne "0" ];do
	if [ "$pingnum" -ge 3 ];then
		echo "network disconnected. please manual check."
		exit -1
	fi
	echo "set network"
	sudo chmod +x /usr/share/doc/ifupdown/examples/get-mac-address.sh 
	sudo cp -a ${mypath}/profile/etc/network/interfaces /etc/network
	sudo chmod 755 /etc/network/interfaces
	cd ${mypath}/scripts/
	sudo ./update_mac.sh
	cd -
	sudo service networking restart
	ping -c3 g.cn
	pingres="$?"
	pingnum=$(($pingnum + 1))
	echo "pingnum is $pingnum"
done
echo "network ok"

# use dpkg and pip install develop environment
dpkg -l | grep "udhcpd"
dpkgres="$?"
if [ "$dpkgres" -ne "0" ];then
	sudo apt-get update 
	sudo apt-get install vim htop iftop vlc browser-plugin-vlc smplayer iperf  -y
	sudo apt-get install unclutter firefox-esr-l10n-zh-cn python-dev build-essential -y
	sudo apt-get install hostapd udhcpd fbi -y
	sudo apt-get install ttf-wqy-zenhei scim-pinyin ttf-wqy-microhei libmatchbox1 matchbox-keyboard  -y
	#sudo apt-get install fcitx fcitx-googlepinyin -y
else 
	echo "udhcpd already installed."
fi
pip list | grep "netifaces"
pipres="$?"
if [ ${pipres} -ne "0" ];then
	sudo pip install tornado coapthon transitions onvif netifaces
else
	echo "python dev env already installed."
fi

cd ~/
mkdir guard -p
cd ~/guard/
echo "install NJWL runtime and d_P_smarthome system."
if [ -f NJWL@Pi2 ];then
	echo "directory NJWL@Pi2 already exist."
fi
if [ -f install ];then
	echo "directory install already exist."
fi
tar xf ${mypath}/OIC_NJWL/pdsmart.tgz
tar xf ${mypath}/OIC_NJWL/NJWL@Pi2.tgz

cd ~/guard/
echo "download security system and setup"
#cp ../install/start.desktop ../Desktop/
git clone https://github.com/ncaew/mytest1 
cp -a ~/guard/mytest1/start.sh ~/guard/.
chmod 755 ~/guard/start.sh

# Setup security system Networking .Configure AP and STA profile file
sudo cp -a ${mypath}/profile/etc/network/interfaces /etc/network
sudo chmod 755 /etc/network/interfaces
sudo chown root:root /etc/network/interfaces
sudo chmod +x  /usr/share/doc/ifupdown/examples/get-mac-address.sh 
sudo cp -a ${mypath}/profile/etc/udhcpd.conf /etc/
sudo chmod 755 /etc/udhcpd.conf
sudo chown root:root /etc/udhcpd.conf
sudo cp -a ${mypath}/profile/etc/default/udhcpd /etc/default/.
sudo chmod 755 /etc/default/udhcpd
sudo chown root:root /etc/default/udhcpd
sudo cp -a ${mypath}/profile/etc/default/hostapd /etc/default/.
sudo chmod 755 /etc/default/hostapd
sudo chown root:root /etc/default/hostapd
sudo cp -a ${mypath}/profile/etc/hostapd/hostapd.conf /etc/hostapd/.
sudo chmod 755 /etc/hostapd/hostapd.conf
sudo chown root:root /etc/hostapd/hostapd.conf

# set mac and configure 
cd ${mypath}/scripts/
sudo ./update_mac.sh
cd -

# ip forward
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
sudo iptables -A FORWARD -i eth0 -o wlan0 -m state --state RELATED,ESTABLISHED -j ACCEPT
sudo iptables -A FORWARD -i wlan0 -o eth0 -j ACCEPT
sudo sh -c "iptables-save > /etc/iptables.ipv4.nat"
if [ "`cat /etc/sysctl.conf | grep '^net\.ipv4\.ip_forward\=1'`" = "1" ];then
	sudo echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
	sudo sh -c "echo 1 > /proc/sys/net/ipv4/ip_forward"
fi

# keyboard softwore set 
sudo cp -a ${mypath}/profile/usr/share/applications/toggle-matchbox-keyboard.desktop /usr/share/applications/.
sudo cp -a ${mypath}/profile/usr/bin/toggle-matchbox-keyboard.sh /usr/bin/.
sudo chmod +x /usr/bin/toggle-matchbox-keyboard.sh
sudo chmod 755 /usr/share/applications/toggle-matchbox-keyboard.desktop

# startup system
sudo cp -a ${mypath}/profile/etc/X11/Xsession.d/100security_launch /etc/X11/Xsession.d/.
sudo cp -a ${mypath}/profile/etc/security_launch /etc/.
chmod 755 /etc/X11/Xsession.d/100security_launch
chmod 755 /etc/security_launch

# modify startup screeen
if [ ! -f /usr/share/plymouth/themes/pix/splash_orig.png ];then
	sudo cp -a /usr/share/plymouth/themes/pix/splash.png /usr/share/plymouth/themes/pix/splash_orig.png
fi
sudo cp -a ${mypath}/profile/usr/share/plymouth/themes/pix/splash.png  /usr/share/plymouth/themes/pix/.
sudo cp -a ${mypath}/profile/usr/share/plymouth/themes/pix/splash.png  /etc/.
sudo cp -a ${mypath}/profile/etc/init.d/asplashscreen /etc/init.d/.
chmod 755 /etc/init.d/asplashscreen
sudo update-rc.d asplashscreen defaults
cat /boot/config.txt | grep "^disable_splash=1"
if [ "$?" -eq "0" ];then
	echo " /boot/config.txt disable_splash=1"
else

	echo " /boot/config.txt disable_splash need modify"
	if [ ! -f /boot/config_orig.txt ];then
		sudo cp -a /boot/config.txt /boot/config_orig.txt
	fi
	sudo sh -c 'echo "disable_splash=1" >> /boot/config.txt'
fi
cat /boot/cmdline.txt  | grep "logo.nologo"
if [ "$?" -eq "0" ];then
	echo " /boot/cmdline.txt nologo is ok"
else
	echo " /boot/cmdline.txt need add nologo info"
	if [ ! -f /boot/cmdline_orig.txt ];then
		sudo cp -a /boot/cmdline.txt /boot/cmdline_orig.txt
	fi
	sudo sh -c 'cat /boot/cmdline.txt | sed "s/$/&\ logo.nologo\ loglevel\=3/g" > /boot/cmdline.txt.tmp'
	sudo mv /boot/cmdline.txt.tmp  /boot/cmdline.txt
fi

# update firemare
#sudo rpi-update
