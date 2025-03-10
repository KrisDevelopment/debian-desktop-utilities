#!/bin/bash

# Set the CPU power mode based on whether the laptop is running on battery or AC power
# Note: Governors don't work on all CPUs. This script sets the clock speeds to the maximum or minimum using the scaling_max_freq file.

# Sleep a little to allow the system to detect the battery status when mode changes
# Sometimes the battery status is not updated immediately.
sleep 1

# Discharging means the laptop is running on battery
battery_mode=$(cat /sys/class/power_supply/BAT0/status)

# List only -l

if [ "$1" = "-l" ]; then
  cpufreq-info | grep "current policy" | uniq
  echo "Battery mode: $battery_mode"
  exit 0
fi

# ========================
# Usage: 
# ========================

echo "=== update-power-mode.sh [options] ==="
echo "Supported single options:"
echo "  -m [Mhz]: Manual mode, set the max CPU frequency to [Mhz]"
echo "  -p: Force performance mode"
echo "  -s: Force powersave mode"
echo "  -h: Display this help message"
echo "  -y: Skip confirmations in default mode" # If runing without any custom options and userspace governor is not enabled, this will skip the confirmation prompt
echo "  -l: Show current power mode"
echo "  -i: Install as a service"
echo "======================================"

if [ "$1" = "-h" ]; then
  exit 0
fi

script_path=$(realpath $0)

# ========================
# Install as a service
# ========================

# Makes udev rule to run the script when AC power is changed
install()
{

  echo $(dirname "$(readlink -f "$0")")
  script_dir_arg=$(dirname "$(readlink -f "$0")")

  # RUN ON AC CHANGE
  echo "Installing as a service"

  # Create a udev rule to run the script when AC power is changed
  echo "Creating udev rule"

  # Switch to battery mode
  sudo echo "SUBSYSTEM==\"power_supply\", ATTR{online}==\"0\", RUN+=\"$script_path\"" | sudo tee /etc/udev/rules.d/99-power-mode.rules
  # Switch to AC power
  sudo echo "SUBSYSTEM==\"power_supply\", ATTR{online}==\"1\", RUN+=\"$script_path\"" | sudo tee -a /etc/udev/rules.d/99-power-mode.rules

  # Reload the udev rules
  echo "Reloading udev rules"
  sudo udevadm control --reload-rules

  # RUN ON BOOT
  echo "Making the install run on boot..."
  # copy the script from /resources/update-power-mode to init.d
  echo "Copying to /etc/init.d"
  sudo cp $script_dir_arg/resources/update-power-mode /etc/init.d/update-power-mode

  # replace SCRIPT_DIR= with the actual script directory of update-power-mode.sh
  sudo sed -i "s|SCRIPT_DIR=.*|SCRIPT_DIR=$script_dir_arg|" /etc/init.d/update-power-mode
  
  sudo chmod +x /etc/init.d/update-power-mode
  # reload the init.d scripts
  sudo systemctl daemon-reload
  sudo update-rc.d update-power-mode defaults
  # enable the service
  sudo systemctl enable update-power-mode

  echo "Done"
  exit 0
}

if [ "$1" = "-i" ]; then
  install
fi

# ========================
# Logic
# ========================

set_frequency=0
forced_performance=0
forced_powersave=0
skip_confirmation=0

if [ "$1" = "-m" ]; then
  if [ -z "$2" ]; then
    echo "Error: Missing frequency value"
    exit 1
  fi
  set_frequency=$2
elif [ "$1" = "-p" ]; then
  forced_performance=1
elif [ "$1" = "-s" ]; then
  forced_powersave=1
elif [ "$1" = "-y" ]; then
  skip_confirmation=1
fi

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

# To enable userspace governor ()
if ! cpufreq-info | grep "userspace" > /dev/null 2>&1; then
  if [ $skip_confirmation -eq 0 ]; then
    echo "Warning: userspace governor not found. Enabling userspace governor will allow the script to set the CPU frequency. Do you want to enable userspace governor? (y/n)"
    read enable_userspace
    if [ "$enable_userspace" != "y" ]; then
      echo "Exiting"
      exit 0
    fi
  fi

  echo "Enabling userspace governor"
  echo passive | sudo tee /sys/devices/system/cpu/intel_pstate/status
  cpufreq-info | grep "available cpufreq governors" | uniq
fi

set_max_scaling_freq () {
  # Set the CPU frequency to the specified value in Mhz
  echo "Setting CPU frequency to $1 Mhz"
  
  # Set the CPU governor to userspace
  sudo cpufreq-set -r -g userspace

  # Convert to khz
  khz=$(echo "$1 * 1000" | bc)

  if [ $khz -lt 1000 ]; then
    echo "Error: Internal error - Invalid frequency"
    exit 1
  fi
  
  echo $khz | sudo tee /sys/devices/system/cpu/cpufreq/policy*/scaling_max_freq

}

parse_frequency_str_to_mhz() {
  max_frequency=$1

  if echo "$max_frequency" | grep -q "GHz"; then
    mhz=$(echo "$max_frequency" | awk '{if ($2 == "GHz") print $1 * 1000; else print $1}')
  elif echo "$max_frequency" | grep -q "MHz"; then
    mhz=$(echo "$max_frequency" | awk '{print $1}')
  else
    echo "0"
    exit 1
  fi

  # Convert to integer (remove decimal point)
  mhz=$(echo $mhz | awk -F. '{print $1}')

  echo $mhz
}

select_performance() {
  # First restore the user space frequency to the hardware limit
  echo "Performance mode selected - Setting CPU frequency to hardware limit"

  # get hardware limits
  # Eg parse "  hardware limits: 800 MHz - 5.00 GHz" to get 5.00 GHz
  hardware_limit_max=$(cpufreq-info | grep "hardware limits" | sed -n 's/.*\([0-9]\.[0-9][0-9] \(MHz\|GHz\)\).*/\1/p')
  echo "Upper hardware limits detected:"
  echo "$hardware_limit_max" | uniq

  if [ -z "$hardware_limit_max" ]; then
    echo "Error: Hardware limits not found"
    exit 1
  fi

  # $hardware_limit_max is a list of frequencies
  # We want the last one
  max_frequency=$(echo "$hardware_limit_max" | tail -n 1)


  # parse GHz to Mhz, and preserve Mhz as is
  mhz=$(parse_frequency_str_to_mhz "$max_frequency")
  
  if [ $mhz -eq 0 ]; then
    echo "Error: Internal error - Invalid frequency. Failed to parse $max_frequency"
    exit 1
  fi

  set_max_scaling_freq $mhz

  # Finally restore the CPU governor to performance
  echo "Restoring CPU governor to performance"
  sudo cpufreq-set -r -g performance
}

select_powersave() {
  # First first set the user space frequency to the lowest possible
  echo "Powersave mode selected - Setting CPU frequency to lowest possible"

  # get hardware limits
  # Eg parse "  hardware limits: 800 MHz - 5.00 GHz" to get 800 MHz
  hardware_limit_min=$(cpufreq-info | grep "hardware limits" | sed -n 's/.*hardware limits: \([0-9.]*\) \(GHz\|MHz\).*/\1 \2/p')
  echo "Lower hardware limits detected:"
  echo "$hardware_limit_min" | uniq

  if [ -z "$hardware_limit_min" ]; then
    echo "Error: Hardware limits not found"
    exit 1
  fi

  # $hardware_limit_min is a list of frequencies
  min_frequency=$(echo "$hardware_limit_min" | head -n 1)

  mhz=$(parse_frequency_str_to_mhz "$min_frequency")

  if [ $mhz -eq 0 ]; then
    echo "Error: Internal error - Invalid frequency. Failed to parse $min_frequency"
    exit 1
  fi

  set_max_scaling_freq $mhz

  # Set the CPU governor to powersave
  echo "Setting CPU governor to powersave"
  sudo cpufreq-set -r -g powersave
}

if [ $set_frequency -ne 0 ]; then
  set_max_scaling_freq $set_frequency
  
  # https://askubuntu.com/questions/1529885/missing-cpu-scaling-governors
  # https://www.linuxquestions.org/questions/slackware-14/locking-all-cpu%27s-to-their-maximum-frequency-4175607506/?__cf_chl_tk=e03Wgl9HbhjSjVtKWZ3m6NuleczCmPMrq8JTO7DqM8w-1738663094-1.0.1.1-YO980BksCbmf9D2835JckKVYo3fNhIL9e2rPPDS2naQ
  # https://askubuntu.com/questions/1482295/cpufreq-set-not-taking-effect-on-fixing-cpu-frequency-on-ubuntu-20

elif [ $forced_performance -eq 1 ]; then
  # Set the CPU governor to performance
  echo "Forcing performance mode"
  select_performance
elif [ $forced_powersave -eq 1 ]; then
  # Set the CPU governor to powersave
  echo "Forcing powersave mode"
  select_powersave
else
  echo "Automatically setting CPU governor based on power mode"

  if [ "$battery_mode" = "Discharging" ]; then
    # Set the CPU governor to powersave
    echo "Battery mode detected - Setting CPU governor to powersave"

    select_powersave

  else
    # Set the CPU governor to performance
    echo "AC power detected - Setting CPU governor to performance"


    select_performance
  fi
fi

# print current governor (collapse repeated output)
cpufreq-info | grep "current policy" | uniq