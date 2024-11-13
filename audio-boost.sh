#!/bin/bash

# List available sinks
echo "Available audio devices:"
pactl list short sinks | awk '{print $1 ": " $2}'

# Prompt user to select a sink
read -p "Enter the device number you want to boost: " device_number

# Validate device number
if ! pactl list short sinks | awk '{print $1}' | grep -q "^$device_number$"; then
    echo "Invalid device number."
    exit 1
fi

# Prompt user for volume boost percentage
read -p "Enter the volume boost percentage (e.g., +50% or -10%): " volume_boost

# Validate volume input
if [[ ! "$volume_boost" =~ ^[\+\-]?[0-9]+%$ ]]; then
    echo "Invalid volume input. Use a percentage format, e.g., +50% or -10%."
    exit 1
fi

# Apply the volume boost to the selected device
pactl set-sink-volume "$device_number" "$volume_boost"
echo "Volume boosted by $volume_boost for device $device_number."
