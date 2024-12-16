#!/usr/bin/env bash

# https://docs.espressif.com/projects/esp-idf/en/latest/esp32/get-started/linux-macos-setup.html

# install prerequisites
sudo apt-get install git wget flex bison gperf python3 python3-pip python3-venv cmake ninja-build ccache libffi-dev libssl-dev dfu-util libusb-1.0-0

# Get ESP-IDF

if [ -d ~/esp ]; then
    echo "Directory ~/esp already exists. Skipping the install."
else
    mkdir -p ~/esp
    cd ~/esp
    git clone --recursive https://github.com/espressif/esp-idf.git

# Set up the tools

    cd ~/esp/esp-idf

    read -p "Do you want to install all the tools? [y/n] " -n 1 -r

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        ./install.sh all
    else
        echo "Installing just the ESP32 tools"
        ./install.sh esp32
    fi
fi

# bashrc configuration to setup the environment variables

# make sure $HOME/esp/esp-idf/export.sh' exists
if [ ! -f "$HOME/esp/esp-idf/export.sh" ]; then
    echo "export.sh not found"
    exit 1
fi

if grep -q "get_idf" ~/.bashrc; then
    echo "get_idf already exists in ~/.bashrc"
    echo "ESP-IDF installed. Run 'get_idf' to set up the environment variables."
else
    echo "alias get_idf='. $HOME/esp/esp-idf/export.sh'" >> ~/.bashrc
    source ~/.bashrc

    get_idf
fi 