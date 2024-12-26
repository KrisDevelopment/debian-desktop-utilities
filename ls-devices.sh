#!/bin/bash

# Enable color output if the terminal supports it
if command -v tput &>/dev/null && [ $(tput colors) -ge 8 ]; then
  RED="\033[0;31m"
  GREEN="\033[0;32m"
  YELLOW="\033[0;33m"
  CYAN="\033[0;36m"
  RESET="\033[0m"
else
  RED=""
  GREEN=""
  YELLOW=""
  CYAN=""
  RESET=""
fi

# Helper function for printing section headers
print_header() {
  echo -e "${CYAN}$1${RESET}"
  echo -e "${CYAN}$(printf '%.0s-' {1..70})${RESET}"
}

# Start of script
print_header "Listing block devices with detailed information using lsblk..."
# Display block devices with more detailed columns
sudo lsblk -o NAME,KNAME,FSTYPE,SIZE,TYPE,MOUNTPOINT,UUID,LABEL,MODEL,VENDOR,PARTUUID || {
  echo -e "${RED}Failed to list block devices.${RESET}";
}


print_header "Listing all disk partitions using fdisk..."
sudo fdisk -l || {
  echo -e "${RED}Failed to list disk partitions.${RESET}";
}

print_header "Listing mounted filesystems and their disk usage using df..."
sudo df -h || {
  echo -e "${RED}Failed to list mounted filesystems.${RESET}";
}

print_header "Listing physical volumes, volume groups, and logical volumes..."
if command -v pvs &> /dev/null && command -v vgs &> /dev/null && command -v lvs &> /dev/null; then
  echo -e "${YELLOW}Physical Volumes:${RESET}"
  sudo pvs || echo -e "${RED}Failed to list physical volumes.${RESET}"
  echo ""

  echo -e "${YELLOW}Volume Groups:${RESET}"
  sudo vgs || echo -e "${RED}Failed to list volume groups.${RESET}"
  echo ""

  echo -e "${YELLOW}Logical Volumes:${RESET}"
  sudo lvs || echo -e "${RED}Failed to list logical volumes.${RESET}"
else
  echo -e "${RED}LVM tools not installed or not available on this system.${RESET}"
fi

print_header "Identifying disk and device UUIDs using blkid..."
sudo blkid || {
  echo -e "${RED}Failed to identify UUIDs.${RESET}";
}

print_header "Identifying USB devices using lsusb..."
sudo lsusb || {
  echo -e "${RED}Failed to list USB devices.${RESET}";
}

echo -e "${GREEN}Script completed successfully.${RESET}"
