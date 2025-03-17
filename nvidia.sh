#!/bin/bash

# usage: nvidia.sh
# usage: nvidia.sh --min-max 300 2100

arg_func=$1 # --min-max, --reset

# opt to use args for min and max
arg_min=$2
arg_max=$3

# ---------------------------------------

if [ "$arg_func" == "--min-max" ] && [ -n "$arg_min" ] && [ -n "$arg_max" ]; then
    echo "Setting Nvidia GPU clock speed to $arg_min, $arg_max"
    sudo nvidia-smi -lgc $arg_min,$arg_max
    exit
fi


# arg --reset to reset to default
if [ "$arg_func" == "--reset" ]; then
    sudo nvidia-smi -rgc
    echo "Reset GPU clock speed to default"
    exit
fi

# ---------------------------------------

# functions
show_gpu_info() {
    echo "============================"
    echo "    GPU info"
    echo "----------------------------"
    
    nvidia-smi -q

    echo "----------------------------"

    echo "lspci | grep -i nvidia"
    lspci | grep -i nvidia
    
    echo "----------------------------"
    echo "Compact view:"

    nvidia-smi
}

install_nvidia_driver() {
    # warn and confirm
    echo "This will install Nvidia driver and tools. No responsibility for any damage."
    read -p "Continue? (y/n): " confirm
    if [ "$confirm" != "y" ]; then
        return
    fi

    # run the installation script from install/install-nvidia-non-free.sh
    script_dir=$(dirname "$(realpath "$0")")
    sudo $script_dir/install/install-nvidia-non-free.sh
}

notebook_fan_control() {
    script_dir=$(dirname "$(realpath "$0")")

    $script_dir/fancontrol.sh
}

# My missadventures with Predator Helios 300

install_cooler_control() {
    sudo apt-get install curl apt-transports-https
    curl -1sLf \
        'https://dl.cloudsmith.io/public/coolercontrol/coolercontrol/setup.deb.sh' |
        sudo -E bash
    sudo apt update
    sudo apt install coolercontrol
    sudo systemctl enable --now coolercontrol
    sudo systemctl status coolercontrol
}

cooler_control() {
    # cooler control
    if [ ! -f /usr/bin/coolercontrol ]; then
        echo "Cooler control not installed"
        read -p "Install cooler control? (y/n): " confirm
        if [ "$confirm" == "y" ]; then
            install_cooler_control
        else
            return
        fi
    else
        echo "Cooler control detected"

        # run GUI
        coolercontrol
    fi

}

set_clock_speed() {
    echo "Set clock speed"
    echo "--------------"

    echo "Set new (1) or reset defaults (2) ?"
    read -p "Enter option: " option
    if [ "$option" == "1" ]; then

        echo "Current clock speed"
        sudo nvidia-smi -q -d CLOCK | grep "Graphics"

        read -p "Enter clock speed (MHz) low: " clock_speed
        read -p "Enter clock speed (MHz) high: " clock_speed_high

        echo "nvidia-smi -lgc $clock_speed,$clock_speed_high"

        sudo nvidia-smi -lgc $clock_speed,$clock_speed_high

    elif [ "$option" == "2" ]; then
        sudo nvidia-smi -rgc
    else
        echo "Invalid option"
    fi
}

set_power_limit() {
    echo "Set power limit"
    echo "--------------"

    echo "Current power limit"
    sudo nvidia-smi -q -d POWER | grep "Power Limit"

    read -p "Enter new power limit (W) : " power_limit

    read -p "Enter GPU number (0 default): " gpu_number
    if [ -z "$gpu_number" ]; then
        gpu_number=0
    fi

    echo "nvidia-smi -pl $gpu_number $power_limit"
    sudo nvidia-smi -pl $gpu_number $power_limit

    echo "New power limit"
    sudo nvidia-smi -q -d POWER | grep "Power Limit"

    echo "Done"
}

disable_persistence_mode() {
    echo "Disable persistence mode"
    echo "------------------------"

    echo "nvidia-smi -pm 0"
    sudo nvidia-smi -pm 0
}

enable_persistence_mode() {
    echo "Enable persistence mode"
    echo "------------------------"

    echo "nvidia-smi -pm 1"
    sudo nvidia-smi -pm 1
}

# ---------------------------------------

# array of menu options
options=(
    "Quit"
    "Show GPU info"
    "Install or update Nvidia driver"
    "Fan and Temp Controls"
    "Set GPU clock speed",
    "Set GPU power limit",
    "Disable persistence mode",
    "Enable persistence mode"
)

while true; do
    # display menu as 1 2 3 ..
    for i in "${!options[@]}"; do
        printf "%s %s\n" "$i" "${options[$i]}"
    done

    read -p "Enter option: " option
    case $option in
    0) break ;;
    1) show_gpu_info ;;
    2) install_nvidia_driver ;;
    3) notebook_fan_control ;;
    4) set_clock_speed ;;
    5) set_power_limit ;;
    6) disable_persistence_mode ;;
    7) enable_persistence_mode ;;
    *) echo "Invalid option" ;;
    esac

    read -p "Press to continue"
done
