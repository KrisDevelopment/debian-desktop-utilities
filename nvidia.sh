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

    # run the installation script from install/install-nvidia-non-free.sh
    script_dir=$(dirname "$(realpath "$0")")
    $script_dir/install/install-nvidia-non-free.sh

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
# ---------------------------------------

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

    echo "nvidia-smi -pl $power_limit"
    sudo nvidia-smi -pl $power_limit

    echo "New power limit"
    sudo nvidia-smi -q -d POWER | grep "Power Limit"

    echo "Done"
}

# array of menu options
options=(
    "Quit"
    "Show GPU info"
    "Install Nvidia driver"
    "Fan and Temp Controls"
    "Set GPU clock speed",
    "Set GPU power limit",
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
    *) echo "Invalid option" ;;
    esac

    read -p "Press to continue"
done
