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
