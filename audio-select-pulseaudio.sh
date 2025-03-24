#!/bin/bash
echo "Enabling pulse audio..."
systemctl --user disable --now pipewire pipewire-pulse || true
systemctl --user enable --now pulseaudio 