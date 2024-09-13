#!/bin/bash

# Function to list disks with their GUIDs
list_disks() {
  echo "Available disks and their GUIDs:"
  lsblk -o NAME,UUID,MOUNTPOINT,FSTYPE,SIZE | grep -v "loop"
  echo ""
}

# Function to add selected disk to /etc/fstab
add_to_fstab() {
  read -p "Enter the disk's UUID you want to mount permanently (e.g., a1b2c3d4-e5f6-7890-abcd-1234567890ab): " uuid
  read -p "Enter the mount point (e.g., /mnt/mydisk): " mountpoint
  read -p "Enter the filesystem type (e.g., ext4, xfs, btrfs): " fstype
  read -p "Enter the mount options (e.g., defaults, nofail): " options
  read -p "Enter the username that should own the mount point: " username

  # Backup existing fstab
  sudo cp /etc/fstab /etc/fstab.bak

  # Create mount point if it doesn't exist
  if [ ! -d "$mountpoint" ]; then
    sudo mkdir -p "$mountpoint"
  fi

  # Add the entry to /etc/fstab
  echo "UUID=$uuid $mountpoint $fstype $options 0 2" | sudo tee -a /etc/fstab

  # Mount the disk
  sudo mount -a

  # Change ownership of the mount point
  sudo chown -R "$username":"$username" "$mountpoint"

  # Set permissions (optional)
  sudo chmod -R 755 "$mountpoint"

  echo "The disk has been mounted and added to /etc/fstab successfully."
  echo "Ownership of the mount point has been set to $username."
}

echo "This script will help you mount a disk permanently or temporarily on your system."

echo "Select permanent or temporary mount:"
options=("Permanent" "Temporary")

select option in "${options[@]}"; do
  case $option in
    "Permanent")
      list_disks
      add_to_fstab
      break
      ;;
    "Temporary")
      # run ./mount-temp.sh

      current_dir=$(pwd)
      script_dir=$(dirname "$0")
      script_path="$current_dir/$script_dir/mount-temp.sh"

      if [ -f "$script_path" ]; then
        bash "$script_path"
      else
        echo "Script not found: $script_path"
        exit 1
      fi

      echo "The disk has been mounted temporarily."
      break
      ;;
    *)
      echo "Invalid option. Please select Permanent or Temporary."
      ;;
  esac
done