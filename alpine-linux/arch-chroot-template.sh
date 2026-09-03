#!/bin/sh

# YOU NEED TO REPLACE <REPLACE IT> WITH YOUR PARTITION (lsblk) FIRST

mount -o subvol=@ <REPLACE IT> /mnt 2>/dev/null || true
mount --bind /dev /mnt/dev
mount --bind /sys /mnt/sys
mount --bind /proc /mnt/proc
mount --bind /run /mnt/run
chroot /mnt /bin/bash
