#!/bin/bash

# Set the CPU power mode based on whether the laptop is running on battery or AC power

# Install cpufrequtils if not installed
if ! dpkg -s cpufrequtils > /dev/null 2>&1; then
  sudo apt-get install cpufrequtils -y
fi

# Assert that we have powersave and performance governors
if ! cpufreq-info | grep "powersave" > /dev/null 2>&1; then
  echo "Error: powersave governor not found"
  exit 1
fi

if ! cpufreq-info | grep "performance" > /dev/null 2>&1; then
  echo "Error: performance governor not found"
  exit 1
fi

# ensure BAT0 is present
if [ ! -d /sys/class/power_supply/BAT0 ]; then
  echo "Error: BAT0 not found"
  exit 1
fi

# Discharging means the laptop is running on battery
battery_mode=$(cat /sys/class/power_supply/BAT0/status)

if [ "$battery_mode" = "Discharging" ]; then
  # Set the CPU governor to powersave
  echo "Battert mode detected - Setting CPU governor to powersave"
  sudo cpufreq-set -r -g powersave

  # TODO: if the laptop continues to freeze up on battery, consider setting the CPU frequency to a fixed value
else
  # Set the CPU governor to performance
  echo "AC power detected - Setting CPU governor to performance"
  sudo cpufreq-set -r -g performance
fi

# print current governor (collapse repeated output)
cpufreq-info | grep "current policy" | uniq