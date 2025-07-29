#!/bin/bash

set -e

# Check if whiptail is installed
if ! command -v whiptail &>/dev/null; then
	echo "whiptail is not installed, but it is required for this script to function. Please install it using your package manager."
	exit 1
fi

# Function to list disks with their GUIDs
list_disks() {
	echo "Available disks and their GUIDs:"
	sudo lsblk -o NAME,UUID,MOUNTPOINT,FSTYPE,SIZE | grep -v "loop"
	echo ""
}

# Function to add selected disk to /etc/fstab
add_to_fstab() {
	read -p "Enter the disk's UUID you want to mount permanently (e.g., a1b2c3d4-e5f6-7890-abcd-1234567890ab): " uuid

	home_dir=$(eval echo ~$USER)
	default_mount_point="$home_dir/mnt/$uuid"

	read -e -p "Enter the mount point (e.g., /mnt/mydisk) or leave empty for \"$default_mount_point\": " mountpoint

	if [ -z "$mountpoint" ]; then
		mountpoint=$default_mount_point
	fi

	read -p "Enter the filesystem type (e.g., ext4, xfs, btrfs, auto): " fstype

	if [ -z "$fstype" ]; then
		echo "Filesystem type cannot be empty."
		exit 1
	fi

	if [ "$fstype" == "auto" ]; then
		echo "Auto-detecting filesystem type..."
		fstype=$(sudo lsblk -o FSTYPE -n "/dev/disk/by-uuid/$uuid")
		echo "Detected filesystem type: $fstype"
	fi

	read -p "Enter the mount options (e.g., defaults, nofail): " options
	read -p "Enter the username that should own the mount point or leave empty for \"$USER\": " username

	if [ -z "$username" ]; then
		username=$USER
	fi

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
	# sudo chown -R "$username":"$username" "$mountpoint"

	# Set permissions (optional)
	# sudo chmod -R 755 "$mountpoint"

	echo "The disk has been mounted and added to /etc/fstab successfully."
	echo "Ownership of the mount point has been set to $username."
}

# Function to list block devices (not partitions)
list_devices() {
	devices=($(sudo lsblk -d -n -o NAME | grep '^sd'))
	device_menu=()

	for i in "${!devices[@]}"; do
		device_name=${devices[$i]}
		device_info=$(sudo lsblk -d -n -o SIZE,MODEL "/dev/$device_name")
		device_menu+=("$i" "/dev/$device_name $device_info")
	done
}

# Function to show a menu of devices
select_device() {
	device_selection=$(whiptail --title "Select Device" --menu "Choose a device to view partitions:" 15 60 5 "${device_menu[@]}" 3>&1 1>&2 2>&3)

	if [ $? -eq 0 ]; then
		device="/dev/${devices[$device_selection]}"
		echo "Selected device: $device"
	else
		echo "Operation cancelled."
		exit 1
	fi
}

format_cfdisk() {
	# Check if cfdisk is installed
	if ! command -v sudo cfdisk &>/dev/null; then
		echo "cfdisk is not installed. Please install it using your package manager."
		exit 1
	fi

	echo "Runnning cfdisk on $device"
	echo "WARNING: This will format the disk. All data will be lost."
	# Run cfdisk to format the disk
	sudo cfdisk "$device"
}

# DRAW SCRIPT MENU
echo "This script will help you format/mount/unmount a disk permanently or temporarily on your system."

echo "Select action:"
options=("Permanent Mount Device" "Temporary Mount Device" "Mount NFS" "Unmount" "Format disk or flash" "Format SD Card" "Show Disk I/O")
script_dir=$(dirname "$(realpath "$0")")

select option in "${options[@]}"; do
	case $option in
	"Permanent Mount Device")
		list_disks
		add_to_fstab
		break
		;;
	"Temporary Mount Device")
		# run ./mount-temp.sh

		script_path="$script_dir/mount-temp.sh"

		if [ -f "$script_path" ]; then
			bash "$script_path"
		else
			echo "Script not found: $script_path"
			exit 1
		fi

		break
		;;

	"Mount NFS")
		# run ./mount-nfs.sh

		script_path="$script_dir/mount-nfs.sh"

		if [ -f "$script_path" ]; then
			bash "$script_path"
		else
			echo "Script not found: $script_path"
			exit 1
		fi

		break
		;;
	"Unmount")
		# unmounts the disk using ./unmount.sh

		script_path="$script_dir/unmount.sh"

		if [ -f "$script_path" ]; then
			bash "$script_path"
		else
			echo "Script not found: $script_path"
			exit 1
		fi

		break
		;;
	"Format disk or flash")
		list_devices
		select_device
		format_cfdisk

		if [ -f "$script_path" ]; then
			bash "$script_path"
		else
			echo "Script not found: $script_path"
			exit 1
		fi

		break
		;;
	"Format SD Card")
		# run ./wipe-sdcard.sh
		list_devices
		select_device

		script_path="$script_dir/format-sdcard.sh"

		if [ -f "$script_path" ]; then
			bash "$script_path" "$device"
		else
			echo "Script not found: $script_path"
			exit 1
		fi

		break
		;;
	"Show Disk I/O")
		sudo iotop -ao || {
			echo "iotop is not installed. Please install it using your package manager."
			exit 1
		}
	
		break
		;;
	*)
		echo "Invalid option. Please select a valid option."
		;;
	esac
done
