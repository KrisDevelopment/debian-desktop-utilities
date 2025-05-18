#!/bin/bash

echo "Select a desktop environment to install:"
echo "1) Plasma"
echo "2) Cinnamon"
echo "3) XFCE"
read -p "Enter your choice (1/2/3): " choice

sudo apt update

case $choice in
    1)
        sudo apt install plasma-desktop sddm
        ;;
    2)
        sudo apt install cinnamon lightdm
        ;;
    3)
        sudo apt install xfce4 lightdm
        ;;
    *)
        echo "Invalid choice. Exiting."
        exit 1
        ;;
esac