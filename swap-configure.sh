#!/bin/bash

# Usage: sudo ./swap-configure.sh 4G   (or 8192M, 1G, etc.)

set -e

# require sudo
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root"
    exit 1
fi

# Check if a size was given
SIZE="$1"

if [ -z "$1" ]; then
    echo "Usage: sudo $0 <size>  (e.g., 4G, 2048M)"
    
    read -p "Do you want to create a 4G swap file? (y/n) " answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        SIZE="4G"
    else
        echo "Exiting..."
        exit 1
    fi
fi

SWAPFILE="/swapfile"

# Check if swapfile already exists
if [ -f "$SWAPFILE" ]; then
    echo "Swap file already exists at $SWAPFILE"
    echo "If you want to recreate it, delete the file first."
    exit 2
fi

echo "Creating $SIZE swap file at $SWAPFILE..."

fallocate -l "$SIZE" "$SWAPFILE" || {
    echo "fallocate failed — trying dd instead..."
    dd if=/dev/zero of="$SWAPFILE" bs=1M count=$(echo "$SIZE" | sed 's/G/*1024/;s/M//' | bc) status=progress
}

chmod 600 "$SWAPFILE"
mkswap "$SWAPFILE"
swapon "$SWAPFILE"

# Add to /etc/fstab if not already there
if ! grep -q "$SWAPFILE" /etc/fstab; then
    echo "$SWAPFILE none swap sw 0 0" >> /etc/fstab
    echo "Added $SWAPFILE to /etc/fstab"
fi

# Optional: reduce swappiness a bit
current_swappiness=$(cat /proc/sys/vm/swappiness)
read -p "Do you want to reduce swappiness from $current_swappiness to 10? (y/n) " answer

if [[ "$answer" =~ ^[Yy]$ ]]; then
    echo "Reducing swappiness to 10..."
    sysctl -w vm.swappiness=10

    if ! grep -q "vm.swappiness" /etc/sysctl.conf; then
        echo "vm.swappiness=10" >> /etc/sysctl.conf
        sysctl -p
        echo "Set vm.swappiness=10 for more RAM-preferring behavior"
    fi
fi

echo "Swap file created and enabled. Run 'free -h' to verify."
