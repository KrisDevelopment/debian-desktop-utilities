#!/bin/bash

# image path 
echo "Enter the path to the image file:"
read -e -p "Image path:" IMAGE_PATH

echo "Enter the device path for the usb (e.g. /dev/sdb):"
read -e -p "USB path:" USB_PATH

echo "Creating boot usb with 4M block size..."

# create boot usb
sudo dd bs=4M if=$IMAGE_PATH of=$USB_PATH status=progress oflag=sync

echo "Boot usb created successfully!"