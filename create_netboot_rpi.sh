#!/bin/bash
# A. Janne Liukkonen
# References
# https://gist.github.com/jkullick/9b02c2061fbdf4a6c4e8a78f1312a689
# https://raspberrypi.stackexchange.com/a/99531

# Create loop device of rpi IMG, mount it etc. chroot it with arm qemu and resize2fs.

# PREREQUISITES
# apt install qemu qemu-user-static binfmt-support 
# USAGE
# ./script raspbian.img rootfsfolder

if [ "$EUID" -ne 0 ]
  then echo "Please run as root. For creating loop devices and mounts"
  exit
fi

set -u
set -e

if [ "$#" -lt "2" ]; then
	echo "Give two arguments, e.g. ./script.sh img.img foldername"
	exit 1
fi
dest=$2
if [ ! -d "$dest" ]; then
	echo Creating from image.
	TMP=$(mktemp -d)
	mkdir -p {$TMP,$dest}/{r,b}oot
	echo -e "Creating loop device ...\c"
	loop_device=$(losetup --show -fP "${1}")
	echo -en "$loop_device \e[32mOK\e[0m\n"
	echo -e "Mounting root and boot ...\c"
	mount ${loop_device}p2 $TMP/root 
	mount ${loop_device}p1 $TMP/boot
	echo -en "\e[32mOK\e[0m\n"
	echo -e "Copying all files from $TMP/root to $dest/root ...\c"
	cp -a $TMP/root/* $dest/root
	echo -en "\e[32mOK\e[0m\n"
	echo -e "Copying all files from $TMP/boot to $dest/boot ...\c"
	cp -a $TMP/boot/* $dest/boot
	echo -en "\e[32mOK\e[0m\n"
	echo -e "Cleaning up ...\c"
	umount $TMP/boot
	umount $TMP/root
	rm -rf $TMP
	losetup -d $loop_device
	echo -en "\e[32mOK\e[0m\n"
fi
## mount binds
tmp_tmpfs=$(mktemp -d)
echo -e "Creating mount binds and fixing ld.so.preload ...\c"
mount tmpfs -t tmpfs $dest/root/tmp
mount --bind $dest/boot $dest/root/boot
mount --bind /dev $dest/root/dev/
mount --bind /sys $dest/root/sys/
mount --bind /proc $dest/root/proc/
mount --bind /dev/pts $dest/root/dev/pts
echo -en "\e[32mOK\e[0m\n"
#
## ld.so.preload fix
sed -i 's/^/#CHROOT /g' $dest/root/etc/ld.so.preload
#
## copy qemu binary
cp /usr/bin/qemu-arm-static $dest/root/usr/bin/
#
#
## chroot to raspbian
echo "For netboot, disable dhcp and fix cmdline.txt with nfs root"
echo "AND turn on SSH server now!"
echo -e "Chrooting to rpi folder. Exit with Ctrl+D"
chroot $dest/root /bin/bash
#
## ----------------------------
## Clean up
## revert ld.so.preload fix
echo -e "Cleanup ...\c"
sed -i 's/^#CHROOT //g' $dest/root/etc/ld.so.preload
#
## unmount everything
umount -l $dest/root/{dev/pts,dev,sys,proc,boot,tmp}
echo -en "\e[32mEverything OK\e[0m\n"

echo Example command to package: "tar -C $(pwd)/$2 -cvpf rootfs.tar root boot"
echo Packaging...
tar -C $(pwd)/$2 -cvpf rootfs.tar root boot
echo Remember to extract with --same-owner and -p flags. "tar -C <where to extract path> --same-owner -xpvf rootfs.tar <root or boot>  --strip-components=1"

