#!/bin/bash
echo "Enabling pulse audio..."
systemctl --user disable --now pipewire pipewire-pulse
systemctl --user enable --now pulseaudio 