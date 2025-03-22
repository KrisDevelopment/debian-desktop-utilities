#!/bin/bash
echo "Installing pipewire..."
sudo apt install pipewire libspa-0.2-bluetooth pipewire-audio

echo "Enabling pipewire..."
systemctl --user disable --now pulseaudio 
systemctl --user enable --now pipewire pipewire-pulse 