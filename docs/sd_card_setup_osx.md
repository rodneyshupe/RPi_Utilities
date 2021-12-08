# Raspbian SD Card Setup

## Get Image
Download latest Raspbian Lite version from [here](https://www.raspberrypi.org/downloads/raspbian/)

## Setup on Mac
Determine SD Card disk identifier:
```
diskutil list
```
Unmount your SD card by using the disk identifier, to prepare for copying data to it:
```
diskutil unmountDisk /dev/disk4
```
Next we need to zero out the partition map, OSX has an issue if you don't do this
```
sudo dd if=/dev/zero of=/dev/rdisk4 bs=1024 count=1
```

Unmount your SD card again:
```
diskutil unmountDisk /dev/disk4
```

Write the image to disk:
```
sudo dd bs=1m if=~/Downloads/2019-09-26-raspbian-buster-lite.img of=/dev/rdisk4
```

Check if it is mounted. Create a file names `ssh` in `boot` folder.
```
touch /Volumes/boot/ssh
```

Unmount your SD card one last time:
```
sync && diskutil unmountDisk /dev/disk4
```


All in one script
```bash

if [ $(diskutil list | grep 'external, physical' | wc -l) eq 1 ]; then
  DISK_NUM=$(diskutil list | grep 'external, physical' | grep --only-matching '/dev/disk[0-9]\+' | grep --only-matching '[0-9]\+')
else
  echo "More than one external drive.  Select correct one."
  exit 1
fi

diskutil unmountDisk /dev/disk${DISK_NUM}
sudo dd if=/dev/zero of=/dev/rdisk${DISK_NUM} bs=1024 count=1
diskutil unmountDisk /dev/disk${DISK_NUM}
sudo dd bs=1m if=~/Downloads/ClusterCTRL-2019-09-26-lite-1-CNAT.img of=/dev/rdisk${DISK_NUM}
sudo dd bs=1m if=~/Downloads/2019-09-26-raspbian-buster-lite.img of=/dev/rdisk${DISK_NUM}

touch /Volumes/boot/ssh
cat << EOF > /Volumes/boot/wpa_supplicant.conf
country=US
update_config=1
ctrl_interface=/var/run/wpa_supplicant

network={
	scan_ssid=1
	ssid="MilliwaysWiFi-5G"
	psk="Zarquon42-5G"
	id_str="Milliways-5G"
}
network={
	scan_ssid=1
	ssid="MilliwaysWiFi"
	psk="Zarquon42"
	id_str="Milliways"
}
network={
	scan_ssid=1
	ssid="unbounce-staff"
	psk="Ch00se+Extr@+++"
	id_str="UnbounceStaff"
}
network={
	scan_ssid=1
	ssid="unbounce-guest"
	psk="ChooseExtra@2019"
	id_str="UnbounceGuest"
}
EOF
sync && diskutil unmountDisk /dev/disk${DISK_NUM}
```
