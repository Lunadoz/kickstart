#!/bin/bash
#Seal a RHEL9 (for template)
#Source:
#https://access.redhat.com/solutions/5793031
#https://access.redhat.com/documentation/fr-fr/red_hat_update_infrastructure/3.0/html/system_administrators_guide/create_client_images_and_templates

#Check runlevel
if ! [[ `runlevel | cut -d " " -f 2` =~ ^[1S]$ ]]
then
	echo "Please *boot* to runlevel 1"
	exit 3
fi

#Check histfile
if [ -n "$HISTFILE" ]
then
	echo 'Please unset HISTFILE'
	exit 4
fi

#Kill udev
echo 'Kill udev'
killall -9 udevd

#Remove all files in /var that are not owned by an RPM
echo 'Remove all files in /var that are not owned by an RPM'
for FILE in `find /var -type f`
do
	rpm -qf --quiet "$FILE" || rm -f "$FILE"
done

#Remove empty directories in /var that are not owned by an RPM
echo 'Remove empty directories in /var that are not owned by an RPM'
until [ "$REMOVED_DIR" = false ]
do
	REMOVED_DIR=false
	for DIR in `find /var -type d -empty`
	do
		if ! rpm -qf --quiet "$DIR"
		then
			REMOVED_DIR=true
			rmdir "$DIR"
		fi
	done
done

#Truncate any remaining files in /var/log
echo 'Truncate any remaining files in /var/log'
for FILE in `find /var/log -type f`
do
	echo -n > "$FILE"
done

#Remove history files
echo 'Remove history files'
rm -f /root/.bash_history

#Remove kickstart files
echo 'Remove kickstart files'
rm -f /root/anaconda-ks.cfg
rm -f /root/original-ks.cfg

#Remove the MAC address. If you have any static information like IP address, DNS, gateway, please delete those information in files
echo 'Remove the MAC address. If you have any static information like IP address, DNS, gateway, please delete those information in files'
sed -i '/^UUID\|^HWADDR/Id' /etc/NetworkManager/system-connections/*.nmconnection

#Remove MAC to interface name associations
echo 'Remove MAC to interface name associations'
rm -rf /etc/udev/rules.d/70-persistent-*

#Configure a generic hostname
echo 'Configure a generic hostname'
hostnamectl set-hostname localhost.localdomain

#Remove host SSH keys
echo 'Remove host SSH keys'
rm -rf /etc/ssh/ssh_host_*

#Remove unique ID
echo 'Remove unique ID'
rm /etc/machine-id
echo "uninitialized" > /etc/machine-id

#Clean /tmp
echo 'Clean /tmp'
find /tmp -mindepth 1 -delete
find /var/tmp -mindepth 1 -delete
