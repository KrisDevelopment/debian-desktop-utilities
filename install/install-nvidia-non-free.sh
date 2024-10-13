#!/bin/bash

# Check for root privileges
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (e.g., with sudo)"
  exit 1
fi

# Ensure Timeshift is installed and prompt the user to create a backup
if ! command -v timeshift &> /dev/null; then
  echo "Timeshift is not installed. Install it using:"
  echo "sudo apt install timeshift"
  exit 1
else
  echo "Please create a Timeshift snapshot before proceeding."
  read -p "Press Enter to continue after you have created the snapshot."
fi

# Add non-free repositories to sources.list
echo "Adding non-free repositories to /etc/apt/sources.list"
sed -i '/^deb /s/$/ contrib non-free/' /etc/apt/sources.list

# Update package lists
echo "Updating package lists..."
apt update

# Install kernel headers
echo "Installing kernel headers for the current kernel..."
apt install -y linux-headers-$(uname -r)

# Install NVIDIA drivers
echo "Installing NVIDIA drivers..."
echo "Please select the appropriate driver version from the list below:"
apt-cache search nvidia-driver
read -p "Enter the driver version to install (e.g., nvidia-driver-460) or leave empty for default: " driver_version

if [ -z "$driver_version" ]; then
  driver_version="nvidia-driver"
fi

apt install -y $driver_version

# other tools
apt install nvidia-settings
apt install nvidia-xconfig

# Reboot system
echo "Installation complete. Rebooting the system is required..."

if [ -t 0 ]; then
  read -p "Reboot now? (y/n): " confirm
  if [ "$confirm" == "y" ]; then
    reboot
  else
    echo "Please reboot the system to apply changes."
  fi
else
  reboot
fi
