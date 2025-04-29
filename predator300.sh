#!/bin/bash

# TURBO and keyboard control for Predator Helios 300
# Note: root user PATH doesn't include this script, that's why I run sudo inside.
set -e
script_dir_arg=$(dirname "$0")

# functions
install() {

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

    sudo $script_dir_arg/predator-turbo/install.sh

    if [ "$unattended" = false ]; then
        read -p "Do you want to make this install permanent? (y/n): " -n 1 -r
    fi

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Making the install run on boot..."
        # copy the script from /resources/predator300setup to init.d
        echo "Copying predator300setup to /etc/init.d"
        sudo cp $script_dir_arg/resources/predator300setup /etc/init.d/predator300setup

        # replace SCRIPT_DIR= with the actual script directory of predator-turbo
        sudo sed -i "s|SCRIPT_DIR=.*|SCRIPT_DIR=$script_dir_arg/predator-turbo|" /etc/init.d/predator300setup
        
        sudo chmod +x /etc/init.d/predator300setup
        # reload the init.d scripts
        sudo systemctl daemon-reload
        sudo update-rc.d predator300setup defaults
        # enable the service
        sudo systemctl enable predator300setup
    fi
}

keyboard() {
    echo "Installing Predator Turbo from $script_dir_arg"
    cd $script_dir_arg/predator-turbo
    sudo python3 keyboard.py
}


if [ "$unattended" = true ]; then
    install
    exit 0
fi

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
    0) break ;;
    1) install ;;
    2) keyboard ;;
    *) echo "Invalid option" ;;
    esac

    read -p "Press to continue"
done
