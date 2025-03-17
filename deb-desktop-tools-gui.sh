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

search_string=""

script_dir_arg=$(dirname "$0")

# Define colors
colors=("\e[1;91m" "\e[1;32m" "\e[1;33m" "\e[1;34m" "\e[1;35m" "\e[1;36m") # Red, Green, Yellow, Blue, Magenta, Cyan
reset_color="\e[0m"

while true; do

    # Array of menu options by querying the scripts in the directory
    options=("Quit")

    if [ -z "$search_string" ]; then
        options+=("Search")

        for script in "$script_dir_arg"/*.sh; do
            options+=("$script")
        done
    else
        for script in "$script_dir_arg"/*.sh; do
            if grep -q "$search_string" "$script"; then
                options+=("$script")
            fi
        done
    fi

    echo
    # Display menu with alternating colors
    for i in "${!options[@]}"; do
        color="${colors[i % ${#colors[@]}]}"  # Cycle through colors
        printf "%b%s %s%b\n" "$color" "$i:" "${options[$i]}" "$reset_color"
    done

    is_searching=1
    if [ -z "$search_string" ]; then
        is_searching=0
    fi
    
    read -p "Enter option: " option
    if [ -z "$search_string" ]; then
        
        case $option in
            0) break;;
            1) read -p "Enter search string: " search_string;;
            *) bash "${options[$option]}";;
        esac
    else
        case $option in
            0) break;;
            *) bash "${options[$option]}";;
        esac
    fi

    if [ $is_searching -eq 1 ]; then
        search_string=""
    fi
done