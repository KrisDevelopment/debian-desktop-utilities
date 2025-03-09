#!/bin/bash
echo "Installing pipewire..."
sudo apt install pipewire

echo "Enabling pipewire..."
systemctl --user disable --now pulseaudio 
systemctl --user enable --now pipewire pipewire-pulse 