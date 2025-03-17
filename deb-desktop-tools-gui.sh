#!/bin/bash

# This is a GUI for the debiand desktop utilities, kinda redundant but fun to have

# Check if whiptail is installed
if ! command -v whiptail &> /dev/null; then
    read -p "whiptail is not installed. Install it? (y/n): " confirm
    if [ "$confirm" == "y" ]; then
        sudo apt install whiptail
    else
        echo "whiptail is required for this script to run."
        exit 1
    fi
fi

# Array of menu options by querying the scripts in the directory
options=("Quit")
script_dir_arg=$(dirname "$0")
for script in "$script_dir_arg"/*.sh; do
    options+=("$script")
done

# Define colors
colors=("\e[1;91m" "\e[1;32m" "\e[1;33m" "\e[1;34m" "\e[1;35m" "\e[1;36m") # Red, Green, Yellow, Blue, Magenta, Cyan
reset_color="\e[0m"

while true; do
    echo
    # Display menu with alternating colors
    for i in "${!options[@]}"; do
        color="${colors[i % ${#colors[@]}]}"  # Cycle through colors
        printf "%b%s %s%b\n" "$color" "$i:" "${options[$i]}" "$reset_color"
    done

    read -p "Enter option: " option
    case $option in
        0) break;;
        *) bash "${options[$option]}";;
    esac

    read -p "Press to continue"
done
