#!/bin/bash

# functions
install ()
{
    script_dir_arg=$(dirname "$0")
    echo "Installing Predator Turbo from $script_dir_arg"
    cd $script_dir_arg/predator-turbo
    sudo ./install.sh

    echo "Done. Predator Turbo button will now work"
}

keyboard ()
{
    script_dir_arg=$(dirname "$0")
    echo "Installing Predator Turbo from $script_dir_arg"
    cd $script_dir_arg/predator-turbo
    sudo python3 keyboard.py   
}

# array of menu options
options=(
    "Quit"
    "Install Predator Turbo"
    "Keyboard"
)

while true; do
    # display menu as 1 2 3 ..
    for i in "${!options[@]}"; do
        printf "%s %s\n" "$i" "${options[$i]}"
    done

    read -p "Enter option: " option
    case $option in
        0) break;;
        1) install;;
        2) keyboard;;
        *) echo "Invalid option";;
    esac

    read -p "Press to continue"
done

