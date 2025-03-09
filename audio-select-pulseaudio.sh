#!/bin/bash
echo "Enabling pulse audio..."
# systemctl --user enable --now pipewire pipewire-pulse
systemctl --user enable --now pulseaudio 