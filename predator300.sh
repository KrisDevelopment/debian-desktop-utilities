#!/bin/bash

# TURBO and keyboard control for Predator Helios 300

# functions
install ()
{

    # the location of this script regardless of shell path
    # script_dir_arg=$(dirname "$0")
    echo $(dirname "$(readlink -f "$0")")
    script_dir_arg=$(dirname "$(readlink -f "$0")")

    # echo "Script dir: $script_dir_arg"
    echo "Installing Predator Turbo from $script_dir_arg/predator-turbo"
    cd $script_dir_arg/predator-turbo

    # if the predator-turbo directory is empty, this means git submodule is not initialized
    if [ ! "$(ls -A $script_dir_arg/predator-turbo)" ]; then
        echo "Git submodule not initialized. Initializing..."
        git submodule update --init --recursive
    fi

    read -p "Temporary or permanent installation? (t/p): " install_type
    if [ "$install_type" == "t" ]; then
        sudo $script_dir_arg/predator-turbo/install.sh
        echo "Done. Predator Turbo button will now work until reboot."
    elif [ "$install_type" == "p" ]; then
        sudo $script_dir_arg/predator-turbo/install_service.sh
        echo "Done. Predator Turbo button will now work as a systemd service."
    else
        echo "Invalid option"
    fi
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

