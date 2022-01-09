# ZTE B860H v5 OS10 Root

## Disclaimer

This script will alter your device and may render it useless. Do at your own risk!

## Preparation

What should you prepare to do the works:
* ZTE B860H v5 with Android 10
* A USB to TTL converter (PL-2303), be careful to choose the chipset as some of it
  would not works under Windows version after Windows 7
* A USB male to male cable
* USB Burning Tool already installed including the driver
* [Putty](https://www.putty.org)
* Download of this repository

The hardest part of this work is to put the device into USB Burning mode, so do it
carefully and patiently. There is already some guides to put the device into USB
Burning mode which involves shorting a certain pin of device. You can search Youtube
for more videos on how to do it.

To ensure the MMC subsystem is working as intended, after doing pin shorting, issue
the command in putty window (U-Boot environment):

`g12a_u212_v1#`**`mmc dev 1`**
```
co-phase 0x2, tx-dly 0, clock 40000000
co-phase 0x2, tx-dly 0, clock 40000000
co-phase 0x2, tx-dly 0, clock 400000
emmc/sd response timeout, cmd8, cmd->cmdarg=0x1aa, status=0x1ff2800
emmc/sd response timeout, cmd55, cmd->cmdarg=0x0, status=0x1ff2800
co-phase 0x2, tx-dly 0, clock 400000
co-phase 0x2, tx-dly 0, clock 40000000
[set_emmc_calc_fixed_adj][862]find fixed adj_delay=20
init_part() 297: PART_TYPE_AML
[mmc_init] mmc init success
switch to partitions #0, OK
mmc1(part 0) is current device
```
`g12a_u212_v1#`**`mmc part`**
```

Partition Map for MMC device 1  --   Partition Type: AML

Part   Start     Sect x Size Type  name
 00 0 8192    512 U-Boot bootloader
 01 73728 131072    512 U-Boot reserved
 02 221184 2048000    512 U-Boot cache
 03 2285568 16384    512 U-Boot env
 04 2318336 16384    512 U-Boot logo
 05 2351104 49152    512 U-Boot recovery
 06 2416640 16384    512 U-Boot misc
 07 2449408 8192    512 U-Boot conf
 08 2473984 16384    512 U-Boot dtbo
 09 2506752 16384    512 U-Boot cri_data
 10 2539520 32768    512 U-Boot param
 11 2588672 32768    512 U-Boot boot
 12 2637824 32768    512 U-Boot oem
 13 2686976 32768    512 U-Boot metadata
 14 2736128 4096    512 U-Boot vbmeta
 15 2756608 65536    512 U-Boot tee
 16 2838528 16384    512 U-Boot factory
 17 2871296 3686400    512 U-Boot super
 18 6574080 8695808    512 U-Boot data
** Partition 19 not found on device 1 **
```
Then put in USB Burning mode by issuing:

`g12a_u212_v1#`**`update`**
```
InUsbBurn
wait for phy ready count is 0
```

## How Does It Work

ZTE B860H v5 is an Andoid TV box powered by Android 10. It uses a locked bootloader,
so to be able to root the device, one must be unlock the bootloader first.

The steps is outlined below:
1. Put the device in USB Burning mode
2. Check if the device is connected
3. Backup CONF partition
4. Wipe cache and data
5. Set device to unlocked state
6. Flash Magisk patched boot image
7. Flash TWRP image
8. Flash empty CONF image
9. Restart device then complete setup and connect to network using WiFi, note the IP address
10. Enable Developer Options and then activate USB debugging
11. Using adb, connect to device IP and install Magisk app
12. Restore saved CONF partition

## Rooting

It is advised to do full backup of your device. To do so, execute `backup.cmd` using
Administrator Command Prompt. Once completed copy the `out` folder somewhere safe.

`C:\b860hv5-os10-root>`***`backup.cmd`***

```
AMLogic Backup Utility
(c) 2022 Toha <tohenk@yahoo.com>
--------------------------------

Detecting device...
Device connected...

Begin backup...
Backup partition bootloader...
Backup partition reserved...
Backup partition cache...
Backup partition env...
Backup partition logo...
Backup partition recovery...
Backup partition misc...
Backup partition conf...
Backup partition dtbo...
Backup partition cri_data...
Backup partition param...
Backup partition boot...
Backup partition oem...
Backup partition metadata...
Backup partition vbmeta...
Backup partition tee...
Backup partition factory...
Backup partition super...
Backup partition data...

Backup done, copy "C:\b860hv5-os10-root\out" to somewhere safe...

```

To start rooting your device, execute `root.cmd` using Administrator Command Prompt.

`C:\b860hv5-os10-root>`***`root.cmd`***
```
ZTE B860H v5 OS 10 Root
(c) 2022 Toha <tohenk@yahoo.com>
--------------------------------

Detecting device...
Device connected...

Begin rooting...
Backup partition conf...
Wiping cache and data...
Unlock boot loader...
Flashing boot...
Flashing recovery...
Flashing conf...

Reboot your device and complete the setup
Connect using WiFi and note the IP address
Enable Developer Options and activate USB debugging

IP address of your device=172.16.1.45

Make sure to allow this computer to access ADB
then Magisk App will be installed to your device
along with original CONF partition
Press ENTER to install Magisk App...
Press ENTER to restore CONF partition...
8192+0 records in
8192+0 records out
4194304 bytes (4.0 M) copied, 0.250313 s, 16 M/s
Done rooting...

```

Restart your device, after that you can customize the device as you need.
To access adb from outside the device you may need install ADB over Ethernet app.
