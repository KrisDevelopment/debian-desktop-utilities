#!/bin/bash

# ------------------------------------------------------------------------------
# Mounts a NFS share to a mount point with user permissions
# ------------------------------------------------------------------------------

# Check if whiptail is installed
if ! command -v whiptail &> /dev/null; then
    echo "whiptail is not installed. Please install it using your package manager."
    exit 1
fi

input_source(){
    echo "Enter the NFS server IP address or hostname:"
    read -p "Server IP/Hostname: " server_ip

    echo "Enter the NFS share path on the server (e.g., /mnt/data):"
    read -p "Share Path: " share_path

    # Check if the server IP/hostname and share path are valid
    if [ -z "$server_ip" ] || [ -z "$share_path" ]; then
        echo "Server IP/Hostname and Share Path cannot be empty."
        exit 1
    fi

    # Check if the server IP/hostname is reachable

    if ping -c 1 "$server_ip" &> /dev/null; then
        echo "Server $server_ip is reachable."
    else
        read -p "Server $server_ip is not reachable. Do you want to continue? (y/n): " choice
        if [ "$choice" != "y" ]; then
            echo "Operation cancelled."
            exit 1
        fi
    fi    
}

# Function to prompt for mount point
select_mount_point() {

    # also set some default mount points at the home of the current user (e.g., /home/user/mnt/0)
    # if a directory with the same name already exists, increment the number at the end (e.g., /home/user/mnt/1)
    
    default_mount_point="/home/$USER/mnt/0"
    i=0
    while [ -d "$default_mount_point" ]; do
        i=$((i+1))
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

mount_nfs(){
    echo "Mounting NFS share $server_ip:$share_path to $mount_point..."

    # Mount the NFS share with user permissions
    sudo mount -t nfs -o rw,hard,intr,user "$server_ip:$share_path" "$mount_point"

    ls -l "$mount_point"
    echo "NFS share mounted successfully to $mount_point."

    read -p "Do you want to make this NFS share permanent? (y/n): " choice
    if [ "$choice" == "y" ]; then
        make_permanent
    fi
}

make_permanent(){
    # Add the NFS share to /etc/fstab for permanent mounting
    echo "Adding NFS share to /etc/fstab with safer options for unreliable network..."

    # Backup existing fstab
    sudo cp /etc/fstab /etc/fstab.bak

    # Add the entry to /etc/fstab
    echo "$server_ip:$share_path $mount_point nfs rw,soft,nofail,user,timeo=100 0 0" | sudo tee -a /etc/fstab

    # Mount the NFS share
    sudo mount -a

    echo "NFS share added to /etc/fstab with safer network options."
}

# Main script execution
input_source
select_mount_point
mount_partition