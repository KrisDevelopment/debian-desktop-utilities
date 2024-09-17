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

  # Validate UUID exists in current disk list
  if ! lsblk -o UUID | grep -q "$uuid"; then
    echo "Error: UUID not found."
    exit 1
  fi

  # Remove the entry from /etc/fstab safely
  sudo sed -i "\|$uuid|d" /etc/fstab

  # Unmount the disk and remove mount point if user wants to
  if sudo umount "$mountpoint"; then
    # Avoid removing critical directories
    if [[ "$mountpoint" == "/" || "$mountpoint" == "/home" || "$mountpoint" == "/var" ]]; then
      echo "Error: Refusing to remove system-critical mount point."
      exit 1
    fi

    read -p "Do you want to remove the mount point directory? (y/n): " remove_dir
    if [[ "$remove_dir" == "y" ]]; then
      sudo rm -r "$mountpoint"
    fi

    echo "The disk has been unmounted and removed from /etc/fstab successfully."
  else
    echo "Error unmounting $mountpoint"
  fi
}

# Function to unmount a temporary disk

unmount_disk() {
  read -e -p  "Enter the mount point you want to unmount (e.g., /mnt/mydisk): " mountpoint

  # Unmount the disk and remove mount point
  if sudo umount "$mountpoint"; then

    read -p "Do you want to remove the mount point directory? (y/n): " remove_dir
    if [[ "$remove_dir" == "y" ]]; then
      sudo rm -r "$mountpoint"
    fi
    
    echo "The disk has been unmounted successfully."
  else
    echo "Error unmounting $mountpoint"
  fi
}

print_temp_mounts() {
  echo "Temporary mounts:"
  mount | grep "/dev/sd\|/dev/nvme"
  echo ""
}

echo "This script will help you unmount a disk permanently or temporarily on your system."

echo "Select permanent or temporary unmount:"
options=("Permanent - EXPERIMENTAL" "Temporary")

select option in "${options[@]}"; do
  case $option in
    "Permanent - EXPERIMENTAL")
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
