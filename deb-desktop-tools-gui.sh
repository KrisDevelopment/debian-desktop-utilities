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

# array of menu options by querying the scripts in the directory
options=("Quit")
script_dir_arg=$(dirname "$0")
for script in $(ls $script_dir_arg/*.sh); do
    script_name=$(basename "$script")
    options+=("$script_name")
done

while true; do
    # display menu as 1 2 3 ..
    for i in "${!options[@]}"; do
        printf "%s %s\n" "$i" "${options[$i]}"
    done

    read -p "Enter option: " option
    case $option in
        0) break;;
        *) bash "${options[$option]}";;
    esac

    read -p "Press to continue"
done
