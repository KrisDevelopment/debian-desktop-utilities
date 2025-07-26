#!/bin/bash
set -e

if [ "$(id -u)" -ne 0 ]; then
  echo "Run as root or with sudo."
  exit 1
fi

if [ -z "$1" ]; then
  echo "Usage: $0 /dev/sdX"
  exit 1
fi

DEVICE="$1"

# Basic safety check: device name must be /dev/sdX or /dev/mmcblkX
if [[ ! "$DEVICE" =~ ^/dev/(sd[a-z]|mmcblk[0-9])$ ]]; then
  echo "Invalid device name. Use something like /dev/sdb or /dev/mmcblk0"
  exit 1
fi

echo "WARNING: This will destroy all data on $DEVICE"
read -p "Type YES to continue: " CONFIRM

if [ "$CONFIRM" != "YES" ]; then
  echo "Aborted."
  exit 1
fi

echo "Unmounting any mounted partitions on $DEVICE..."
umount ${DEVICE}?* || true

echo "Wiping partition table and first 10MB of $DEVICE..."
dd if=/dev/zero of="$DEVICE" bs=1M count=10 status=progress

echo "Creating new partition table (DOS)..."
parted -s "$DEVICE" mklabel msdos

echo "Creating primary partition spanning entire device..."
parted -s "$DEVICE" mkpart primary fat32 1MiB 100%

echo "Setting partition boot flag..."
parted -s "$DEVICE" set 1 boot on

PARTITION="${DEVICE}1"
# Handle mmcblk devices where partition names are like mmcblk0p1
if [[ "$DEVICE" =~ mmcblk[0-9]$ ]]; then
  PARTITION="${DEVICE}p1"
fi

echo "Formatting partition $PARTITION as FAT32..."
mkfs.vfat -F 32 -n "SDCARD" "$PARTITION"

echo "Done. The SD card is wiped and formatted as FAT32."


