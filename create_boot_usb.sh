#!/bin/bash


# Image path 
read -e -p "Enter the path to the image file: " IMAGE_PATH

# Validate if the image file exists
if [[ ! -f "$IMAGE_PATH" ]]; then
   echo "Error: Image file does not exist."
   exit 1
fi

# List devices and ask for the USB path
echo "Available drives:"
lsblk

read -e -p "Enter the device path for the USB (e.g. /dev/sdb): " USB_PATH

# Confirm the selected USB device path
read -p "WARNING: All data on $USB_PATH will be lost. Do you want to continue? (y/n) " CONFIRM
if [[ $CONFIRM != "y" ]]; then
   echo "Operation cancelled."
   exit 1
fi

# Ensure the USB device is not mounted
if mount | grep "$USB_PATH"; then
    echo "Error: USB device is mounted. Please unmount before proceeding."
    exit 1
fi

echo "Creating boot USB with 4M block size..."

# Create boot USB
if sudo dd bs=4M if="$IMAGE_PATH" of="$USB_PATH" status=progress oflag=sync; then
    echo "Syncing..."
    sync
    echo "Boot USB created successfully!"
else
    echo "Error: Failed to create boot USB."
    exit 1
fi
