#!/bin/bash

# unmount disk
# Function to list disks with their GUIDs

list_disks() {
  echo "Available disks and their GUIDs:"
  lsblk -o NAME,UUID,MOUNTPOINT,FSTYPE,SIZE | grep -v "loop"
  echo ""
}

# Function to remove selected disk from /etc/fstab

remove_from_fstab() {
  read -p "Enter the disk's UUID you want to unmount permanently (e.g., a1b2c3d4-e5f6-7890-abcd-1234567890ab): " uuid
  read -p "Enter the mount point (e.g., /mnt/mydisk): " mountpoint

  # Backup existing fstab
  sudo cp /etc/fstab /etc/fstab.bak

  # Remove the entry from /etc/fstab
  sudo sed -i "/$uuid/d" /etc/fstab

  # Unmount the disk
  sudo umount "$mountpoint"

  # Remove the mount point
  sudo rm -r "$mountpoint"

  echo "The disk has been unmounted and removed from /etc/fstab successfully."
}

# Function to unmount a temporary disk

unmount_disk() {
  read -e -p  "Enter the mount point you want to unmount (e.g., /mnt/mydisk): " mountpoint

  # Unmount the disk
  sudo umount "$mountpoint"

  # Remove the mount point
  sudo rm -r "$mountpoint"

  echo "The disk has been unmounted successfully."
}

print_temp_mounts() {
  echo "Temporary mounts:"
  mount | grep "/dev/"
  echo ""
}


echo "This script will help you unmount a disk permanently or temporarily on your system."

echo "Select permanent or temporary unmount:"
options=("Permanent" "Temporary")

select option in "${options[@]}"; do
  case $option in
    "Permanent")
      list_disks
      remove_from_fstab
      break
      ;;
    "Temporary")
      print_temp_mounts
      unmount_disk
      break
      ;;
    *)
      echo "Invalid option. Please select Permanent or Temporary."
      ;;
  esac
done

