#!/bin/bash
if ! command -v netstat &> /dev/null; then
    echo "net-tools is not installed. Installing..."
    sudo apt update && sudo apt install -y net-tools
fi

echo "Showing open ports:"
sudo netstat -tuln