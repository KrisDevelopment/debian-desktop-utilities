#!/bin/bash

# First, make sure we have all necessary PipeWire packages
echo "Installing PipeWire and required packages..."
sudo apt update
sudo apt install -y pipewire pipewire-audio-client-libraries \
    pipewire-pulse pipewire-jack libspa-0.2-bluetooth \
    wireplumber libspa-0.2-modules

# Stop and disable PulseAudio
echo "Disabling PulseAudio..."
systemctl --user disable --now pulseaudio.service pulseaudio.socket || true
systemctl --user mask pulseaudio

# Remove any existing PipeWire configuration
rm -rf ~/.config/pipewire/* 2>/dev/null

# Copy default PipeWire configuration
mkdir -p ~/.config/pipewire
cp -r /usr/share/pipewire/* ~/.config/pipewire/ 2>/dev/null

# Restart PipeWire services
echo "Enabling and starting PipeWire services..."
systemctl --user daemon-reload
systemctl --user enable --now pipewire.service pipewire-pulse.service wireplumber.service

# Wait a moment for services to start
sleep 2

# Check service status
echo "Checking PipeWire service status..."
systemctl --user status pipewire.service
systemctl --user status pipewire-pulse.service
systemctl --user status wireplumber.service

# List audio devices
echo -e "\nListing audio devices..."
pw-cli ls | grep -E "node.name|node.description"

echo -e "\nIf no audio devices are showing, try logging out and back in, or reboot the system."
echo "You can check audio devices with: pactl list sinks"