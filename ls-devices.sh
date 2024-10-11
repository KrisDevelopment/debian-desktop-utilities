#!/bin/bash



echo "Listing block devices with detailed information using lsblk..."
echo "--------------------------------------------------------------"
# Display block devices with more detailed columns
sudo lsblk -o NAME,KNAME,FSTYPE,SIZE,TYPE,MOUNTPOINT,UUID,LABEL,MODEL,VENDOR,PARTUUID

echo ""
echo "Listing all disk partitions using fdisk..."
echo "-----------------------------------------"
sudo fdisk -l

echo ""
echo "Listing mounted filesystems and their disk usage using df..."
echo "------------------------------------------------------------"
sudo df -h

echo ""
echo "Listing physical volumes, volume groups, and logical volumes..."
echo "-------------------------------------------------------------"
if command -v sudo pvs &> /dev/null && command -v sudo vgs &> /dev/null && command -v sudo lvs &> /dev/null; then
    echo "Physical Volumes:"
    sudo pvs
    echo ""
    
    echo "Volume Groups:"
    sudo vgs
    echo ""
    
    echo "Logical Volumes:"
    sudo lvs
else
    echo "LVM tools not installed or not available on this system."
fi

echo ""
echo "Identifying disk and device UUIDs using blkid..."
echo "------------------------------------------------"
sudo blkid

echo ""
echo "Identifying USB devices using lsusb..."
echo "--------------------------------------"
sudo lsusb

echo ""
echo "Script completed."
