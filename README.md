# Introduction

Read through the script. It creates a loop device from the raspbian image.

Mounts the loop device, copies root and boot sections. 

Packages the whole root directory to rootfs.tar

## Usage
```
./create_netboot_rpi.sh latest_raspbian.img rootfsfolder
```

## Recommendations

Inside the chroot, run following to enable SSH server.

```
systemctl enable ssh
```

