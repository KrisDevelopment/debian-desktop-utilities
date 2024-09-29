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

notebook_fan_control() {
    echo "Using nbfc Fan Control"

    if [ ! -f /usr/bin/nbfc ]; then
        echo "NBFC not installed"
        read -p "Install NBFC? (y/n): " confirm
        if [ "$confirm" == "y" ]; then

            download_linl = "https://objects.githubusercontent.com/github-production-release-asset-2e65be/392712777/814e0891-2ea7-435d-9b3e-6dea0467052f?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=releaseassetproduction%2F20240928%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Date=20240928T193012Z&X-Amz-Expires=300&X-Amz-Signature=fdf13732fd7034bdd3ba75723c6e69cf08b4f1f56a745c9422a74f97aab84ebd&X-Amz-SignedHeaders=host&response-content-disposition=attachment%3B%20filename%3Dnbfc-linux_0.2.7_amd64.deb&response-content-type=application%2Foctet-stream"
            wget -O nbfc-linux_0.2.7_amd64.deb $download_linl
            sudo dpkg -i nbfc-linux_0.2.7_amd64.deb
            # install the package
            sudo apt-get install -f 
            sudo nbfc config --recommend
            read -p "Enter config file (no quotes): " config_file
            sudo nbfc config --set "$config_file"
            sudo nbfc start

            echp "Would you like to start NBFC on boot?"
            read -p "Start NBFC on boot? (y/n): " confirm
            if [ "$confirm" == "y" ]; then
                sudo systemctl enable nbfc
                echo "If you soft-lock your system with wrong fan settings, enter emergency mode using init=/bin/bash in grub, then mount the fs in read-write mode (mount -o remount,rw / ) and edit the config file in /etc/nbfc/nbfc.json "
            fi
        else
            return
        fi
    else
        echo "NBFC detected"
        echo "Run 'sudo nbfc config --set auto' to set auto fan control"
        echo "Run 'sudo nbfc config --recommend' to recommend fan control"
    fi
    
    # enter fan settings, 99 is safety, 100 might crash it.
    read -p "Enter fan speed (0-99, auto): " fan_speed
    
    if [ "$fan_speed" == "auto" ]; then
        sudo nbfc set -a
    else
        if [ "$fan_speed" -gt 99 ]; then
            echo "Fan speed too high, setting to 99"
            fan_speed=99
        fi

        sudo nbfc set -s $fan_speed
    fi

    echo "Done"
}


# My missadventures with Predator Helios 300

install_cooler_control()
{
    sudo apt-get install curl apt-transports-https
    curl -1sLf \
  'https://dl.cloudsmith.io/public/coolercontrol/coolercontrol/setup.deb.sh' \
  | sudo -E bash
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
    "Set fan speeds (Notebook - NBFC)"
    "Set GPU clock speed",
    "Set GPU power limit",
    "Cooler control"
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
        3) notebook_fan_control;;
        4) set_clock_speed;;
        5) set_power_limit;;
        6) cooler_control;;
        *) echo "Invalid option";;
    esac

    read -p "Press to continue"
done

