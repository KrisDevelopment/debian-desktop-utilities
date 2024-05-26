#!/bin/bash


# functions
show_gpu_info() {
    echo "GPU info"
    echo "--------"
    echo "lspci | grep -i nvidia"
    lspci | grep -i nvidia
    echo ""
    echo "nvidia-smi"
    nvidia-smi
}

install_nvidia_driver() {
    # warn and confirm
    echo "This will install Nvidia driver 440 and tools. No responsibility for any damage."
    read -p "Continue? (y/n): " confirm
    if [ "$confirm" != "y" ]; then
        return
    fi

    # nvidia-driver-440
    echo "Installing Nvidia driver"
    echo "------------------------"
    sudo apt-get install nvidia-driver-440
    
    # other tools
    sudo apt-get install nvidia-settings
    sudo apt-get install nvidia-xconfig
}

set_fan_speeds_pc() {
    echo "Set fan speeds - PC"
    echo "--------------"

    read -p "Enter GPU number: " gpu_number
    read -p "Enter fan speed (0-100): " fan_speed
    
    sudo nvidia-xconfig
    sudo nvidia-xconfig --cool-bits=4
    echo "Cool bits set to 4"
    sudo nvidia-settings -a "[gpu:$gpu_number]/GPUFanControlState=1"
    sudo nvidia-settings -a "[fan:$gpu_number]/GPUTargetFanSpeed=$fan_speed"
}

set_fan_speeds_predator_nb() {
    
    echo "Not implemented"
    # gotta make this bullshit script work https://github.com/kphanipavan/PredatorNonSense?tab=readme-ov-file
    
}

# array of menu options
options=(
    "Quit"
    "Show GPU info"
    "Install Nvidia driver"
    "Set fan speeds - PC (Experimental)"
    "Set fan speeds - Laptop (WIP)"
)

while true; do
    # display menu as 1 2 3 ..
    for i in "${!options[@]}"; do
        printf "%s %s\n" "$i" "${options[$i]}"
    done

    read -p "Enter option: " option
    case $option in
        0) break;;
        1) show_gpu_info;;
        2) install_nvidia_driver;;
        3) set_fan_speeds_pc;;
        4) set_fan_speeds_predator_nb;;
        *) echo "Invalid option";;
    esac

    read -p "Press to continue"
done

