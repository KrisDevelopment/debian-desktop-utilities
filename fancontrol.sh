#!/bin/bash

# functions
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

toggle_nbfc_boot_daemon() {
    if [ ! -f /usr/bin/nbfc ]; then
        echo "NBFC not installed"
        return
    fi

    if [ ! -f /etc/systemd/system/nbfc.service ]; then
        echo "NBFC not enabled on boot"
        read -p "Enable NBFC on boot? (y/n): " confirm
        if [ "$confirm" == "y" ]; then
            sudo systemctl enable nbfc
        else
            return
        fi
    else
        echo "NBFC enabled on boot"
        read -p "Disable NBFC on boot? (y/n): " confirm
        if [ "$confirm" == "y" ]; then
            sudo systemctl disable nbfc
        else
            return
        fi
    fi
}

# array of menu options
options=(
    "Quit"
    "Set fan speeds (Notebook - NBFC)"
    "Enable/disable nbfc on boot"
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
        1) notebook_fan_control;;
        2) cooler_control;;
        *) echo "Invalid option";;
    esac

    read -p "Press to continue"
done

