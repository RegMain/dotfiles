#!/bin/sh

# As is. This script is wrote by AI and allows you restore your Arch Linux via Alpine Linux using Btrfs-snapshots (Timeshift)

set -e

echo "============================================="
echo "      ARCH LINUX RECOVERY SCRIPT (BTRFS)     "
echo "============================================="

# 1. Searching for BTRFS
PARTITIONS=$(blkid | grep 'TYPE="btrfs"' | cut -d':' -f1)

if [ -z "$PARTITIONS" ]; then
    echo "ERROR: NO BTRFS PARTITIONS FOUND!"
    exit 1
fi

COUNT=$(echo "$PARTITIONS" | wc -l)
if [ "$COUNT" -eq 1 ]; then
    DEV=$PARTITIONS
    echo "Btrfs-partition found: $DEV"
else
    echo "Choose Btrfs-partition:"
    i=1
    for p in $PARTITIONS; do
        echo "[$i] $p"
        eval "PART_$i=\$p"
        i=$((i + 1))
    done
    MAX_PART=$((i - 1))
    while true; do
        read -p "Select partition number [1-$MAX_PART]: " P_CHOICE
        if [ "$P_CHOICE" -ge 1 ] 2>/dev/null && [ "$P_CHOICE" -le "$MAX_PART" ] 2>/dev/null; then
            eval "DEV=\$PART_$P_CHOICE"
            break
        fi
        echo "ERROR: INCORRECT CHOICE. TRY AGAIN"
    done
fi

# 2. Mounting in root
MOUNT_POINT="/mnt"
echo "Mounting $DEV to $MOUNT_POINT..."
umount "$MOUNT_POINT" 2>/dev/null || true
mount "$DEV" "$MOUNT_POINT"

SNAPSHOT_DIR="$MOUNT_POINT/timeshift-btrfs/snapshots"

if [ ! -d "$SNAPSHOT_DIR" ]; then
    echo "ERROR: TIMESHIFT DIRECTORY IS NOT FOUND AT $SNAPSHOT_DIR"
    umount "$MOUNT_POINT"
    exit 1
fi

# 3. List of snapshots
echo ""
echo "Available Timeshift snapshots:"
cd "$SNAPSHOT_DIR"
SNAPSHOTS=$(ls -d */ | sed 's/\///')

if [ -z "$SNAPSHOTS" ]; then
    echo "ERROR: NO SNAPSHOTS FOUND!"
    umount "$MOUNT_POINT"
    exit 1
fi

i=1
for snap in $SNAPSHOTS; do
    comment=""
    info_file="$SNAPSHOT_DIR/$snap/info.json"
    if [ -f "$info_file" ]; then
        comment=$(grep -o '"comments"[^,}]*' "$info_file" | head -1 | cut -d'"' -f4 || true)
    fi
    echo "[$i] $snap ($comment)"
    eval "SNAP_$i=\$snap"
    i=$((i + 1))
done
MAX_SNAP=$((i - 1))

# Choosing snapshot
echo ""
while true; do
    read -p "Choose snapshot [1-$MAX_SNAP]: " CHOICE
    if [ "$CHOICE" -ge 1 ] 2>/dev/null && [ "$CHOICE" -le "$MAX_SNAP" ] 2>/dev/null; then
        eval "SELECTED_SNAP=\$SNAP_$CHOICE"
        break
    fi
    echo "ERROR: INCORRECT CHOICE. TRY AGAIN"
done

echo ""
echo "Snapshot selected: $SELECTED_SNAP"
read -p "Do you want to proceed? Unsaved data will be lost (y/N): " CONFIRM
if [ "$CONFIRM" != "y" ] && [ "$CONFIRM" != "Y" ]; then
    echo "Process cancelled."
    umount "$MOUNT_POINT"
    exit 0
fi

# 4. Restoring system
BROKEN_DIR="$MOUNT_POINT/@_broken"
CURRENT_ROOT="$MOUNT_POINT/@"

# Removing @_broken
if [ -d "$BROKEN_DIR" ] || [ -L "$BROKEN_DIR" ]; then
    echo "Removing @_broken..."
    btrfs subvolume delete -R "$BROKEN_DIR"
fi

# Rename / to @_broken
if [ -d "$CURRENT_ROOT" ]; then
    echo "Renaming current system to @_broken..."
    mv "$CURRENT_ROOT" "$BROKEN_DIR"
else
    echo "ALERT: Current subvolume @ is not found. Clean install in process."
fi

# New @ from snapshot
TARGET_SNAP_SUBVOL="$SNAPSHOT_DIR/$SELECTED_SNAP/@"
echo "Creating @ from snapshot..."
btrfs subvolume snapshot "$TARGET_SNAP_SUBVOL" "$CURRENT_ROOT"

# Recursively deleting @_broken
if [ -d "$BROKEN_DIR" ] || [ -L "$BROKEN_DIR" ]; then
    echo "Removing @_broken (fully)..."
    btrfs subvolume delete -R "$BROKEN_DIR"
fi

# 5. End of script
echo "Unmounting..."
cd / && umount "$MOUNT_POINT"

echo ""
echo "============================================="
echo " SUCCESS: System was restored"
echo " $SELECTED_SNAP"
echo "============================================="
echo ""

read -p "Reboot now? (y/N): " REBOOT
if [ "$REBOOT" = "y" ] || [ "$REBOOT" = "Y" ]; then
    echo "Rebooting..."
    reboot
fi
