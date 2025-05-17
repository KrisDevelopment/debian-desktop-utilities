#!/bin/bash

# Required packages
PACKAGES="lshw dmidecode hwinfo inxi mesa-utils pciutils neofetch"

# Check if sudo is available
if command -v sudo &>/dev/null; then
    SUDO="sudo"
    echo "Sudo is available. You may be prompted for your password."
else
    SUDO=""
fi


# Check and install required packages
check_and_install_packages() {
    for pkg in $PACKAGES; do
        if ! dpkg -l | grep -q "^ii  $pkg "; then
            echo "Installing required package: $pkg"
            $SUDO apt-get install -y "$pkg"
        fi
    done
}

# Function to show CPU information
show_cpu_info() {
    echo "=== CPU Information ==="
    echo
    lscpu | grep -E "Model name|CPU MHz|CPU max MHz|CPU min MHz|Core|Thread|Socket|Cache"
    echo
    echo "Press Enter to continue..."
    read
}

# Function to show GPU information
show_gpu_info() {
    echo "=== GPU Information ==="
    echo
    if command -v nvidia-smi &> /dev/null; then
        echo "NVIDIA GPU Information:"
        nvidia-smi
        echo
    fi
    
    echo "All Graphics Cards:"
    lspci | grep -i vga
    echo
    echo "Detailed GPU Info:"
    glxinfo | grep -i "renderer\|vendor"
    echo
    echo "Press Enter to continue..."
    read
}

# Function to show RAM information
show_ram_info() {
    echo "=== RAM Information ==="
    echo
    $SUDO dmidecode --type memory | grep -A16 "Memory Device" | grep -v "^$"
    echo
    echo "Total Memory Usage:"
    free -h
    echo
    echo "Press Enter to continue..."
    read
}

# Function to show storage information
show_storage_info() {
    echo "=== Storage Information ==="
    echo
    echo "Disk Partitions and Usage:"
    df -h
    echo
    echo "Storage Devices:"
    lsblk -o NAME,SIZE,TYPE,MOUNTPOINT,MODEL
    echo
    echo "SMART Status (if available):"
    for drive in $(lsblk -d -o NAME -n); do
        if [[ $drive == sd* ]] || [[ $drive == nvme* ]]; then
            echo "=== $drive ==="
            $SUDO smartctl -i "/dev/$drive" 2>/dev/null || echo "SMART not available for $drive"
            echo
        fi
    done
    echo "Press Enter to continue..."
    read
}

# Function to show motherboard information
show_motherboard_info() {
    echo "=== Motherboard Information ==="
    echo
    echo "Board Information:"
    $SUDO dmidecode -t baseboard | grep -v "^#"
    echo
    echo "BIOS Information:"
    $SUDO dmidecode -t bios | grep -v "^#"
    echo
    echo "Press Enter to continue..."
    read
}

# Function to show network information
show_network_info() {
    echo "=== Network Information ==="
    echo
    echo "Network Interfaces:"
    ip -br addr
    echo
    echo "Detailed Network Info:"
    $SUDO lshw -class network
    echo
    echo "Press Enter to continue..."
    read
}

# Function to show power supply information
show_power_info() {
    echo "=== Power Information ==="
    echo
    echo "Power Supply Information (if available):"
    $SUDO dmidecode -t 39 || echo "Power supply information not available"
    echo
    echo "Battery Information (if laptop):"
    if [ -d "/sys/class/power_supply" ]; then
        for battery in /sys/class/power_supply/BAT*; do
            if [ -e "$battery" ]; then
                cat "$battery/uevent"
            fi
        done
    else
        echo "No battery information available"
    fi
    echo
    echo "Press Enter to continue..."
    read
}

# Main menu function
show_menu() {
    while true; do
        clear
        echo "=== Hardware Information Tool ==="
        echo "1. CPU Information"
        echo "2. GPU Information"
        echo "3. RAM Information"
        echo "4. Storage Information"
        echo "5. Motherboard Information"
        echo "6. Network Information"
        echo "7. Power Supply Information"
        echo "8. Show All Information"
        echo "9. Neofetch Information"
        echo "10. Exit"
        echo
        read -p "Please select an option (1-9): " choice

        case $choice in
            1) clear && show_cpu_info ;;
            2) clear && show_gpu_info ;;
            3) clear && show_ram_info ;;
            4) clear && show_storage_info ;;
            5) clear && show_motherboard_info ;;
            6) clear && show_network_info ;;
            7) clear && show_power_info ;;
            8) 
                clear
                show_cpu_info
                show_gpu_info
                show_ram_info
                show_storage_info
                show_motherboard_info
                show_network_info
                show_power_info
                ;;
            9) 
                clear
                echo "=== Neofetch Information ==="
                echo
                neofetch
                echo
                echo "Press Enter to continue..."
                read
                ;;
            10) exit 0 ;;
            *) echo "Invalid option. Press Enter to continue..."; read ;;
        esac
    done
}

# Main execution
check_and_install_packages
show_menu