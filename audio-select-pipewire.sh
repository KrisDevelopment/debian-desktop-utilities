#!/bin/bash
echo "Installing pipewire..."
sudo apt install pipewire

echo "Enabling pipewire..."
systemctl --user enable --now pipewire pipewire-pulse 