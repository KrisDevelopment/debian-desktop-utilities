#!/bin/bash

# ------------------------------------------------------------------------------
# Mounts a pyhsical partition to a mount point with user permissions temporarily
# ------------------------------------------------------------------------------

# Check if whiptail is installed
if ! command -v whiptail &>/dev/null; then
    echo "whiptail is not installed. Please install it using your package manager."
    exit 1
fi

# Function to list block devices (not partitions)
list_devices() {
    devices=($(lsblk -d -n -o NAME | grep '^sd'))
    device_menu=()

    for i in "${!devices[@]}"; do
        device_name=${devices[$i]}
        device_info=$(lsblk -d -n -o SIZE,MODEL "/dev/$device_name")
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

# Function to list partitions of the selected device
list_partitions() {
    partitions=($(lsblk -n -o NAME "$device" --noheadings --list | grep -v '^sd$'))
    partition_menu=()

    for i in "${!partitions[@]}"; do
        partition_name=${partitions[$i]}
        partition_info=$(lsblk -n -o SIZE,TYPE,MOUNTPOINT "/dev/$partition_name")
        partition_menu+=("$i" "/dev/$partition_name $partition_info")
    done

    if [ ${#partitions[@]} -eq 0 ]; then
        whiptail --msgbox "No partitions found on $device." 8 45
        exit 1
    fi
}
# Function to show a menu of partitions
select_partition() {
    # Create a simple numbered menu for partitions
    partition_menu=()
    for i in "${!partitions[@]}"; do
        partition_name="/dev/${partitions[$i]}"
        partition_info=$(lsblk -n -o SIZE,TYPE,MOUNTPOINT "$partition_name")
        partition_menu+=("$i" "$partition_name $partition_info")
    done

    # Use whiptail to present the menu
    partition_selection=$(whiptail --title "Select Partition" --menu "Choose a partition to mount:" 15 60 5 "${partition_menu[@]}" 3>&1 1>&2 2>&3)

    if [ $? -eq 0 ]; then
        partition="/dev/${partitions[$partition_selection]}"
        echo "Selected partition: $partition"
    else
        echo "Operation cancelled."
        exit 1
    fi
}

# Function to prompt for mount point
select_mount_point() {

    # also set some default mount points at the home of the current user (e.g., /home/user/mnt/0)
    # if a directory with the same name already exists, increment the number at the end (e.g., /home/user/mnt/1)

    default_mount_point="/home/$USER/mnt/0"
    i=0
    while [ -d "$default_mount_point" ]; do
        i=$((i + 1))
        default_mount_point="/home/$USER/mnt/$i"
    done

    # use standard termina to read mount point with autocomplete
    read -e -p "Enter the mount point (leave blank for default $default_mount_point): " mount_point
    mount_point=${mount_point:-$default_mount_point}

    if [ $? -eq 0 ] && [ -d "$mount_point" ]; then
        echo "Mount point selected: $mount_point"
    else
        # Create the mount point if it doesn't exist
        echo "Do you want to create the mount point?"
        options=("Yes" "No")
        select option in "${options[@]}"; do
            case $option in
            "Yes")
                sudo mkdir -p "$mount_point"
                echo "Mount point created: $mount_point"
                break
                ;;
            "No")
                echo "Operation cancelled."
                exit 1
                ;;
            esac
        done
    fi
}

# Function to mount the selected partition
mount_partition() {
    echo "Mounting $partition to $mount_point..."
    sudo mount -o uid=$(id -u),gid=$(id -g) "$partition" "$mount_point"

    if [ $? -eq 0 ]; then
        whiptail --msgbox "$partition mounted successfully to $mount_point." 8 45
    else
        whiptail --msgbox "Failed to mount $partition." 8 45
        exit 1
    fi

    ls -l "$mount_point"
    echo "Partition mounted successfully to $mount_point."
}

# Main script execution
list_devices
select_device
list_partitions
select_partition
select_mount_point
mount_partition
