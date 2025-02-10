#!/bin/bash

# Set the CPU power mode based on whether the laptop is running on battery or AC power
# Note: Governors don't work on all CPUs. This script sets the clock speeds to the maximum or minimum using the scaling_max_freq file.

# Usage:
echo "=== update-power-mode.sh [options] ==="
echo "Supported single options:"
echo "  -m [Mhz]: Manual mode, set the max CPU frequency to [Mhz]"
echo "  -p: Force performance mode"
echo "  -s: Force powersave mode"
echo "  -h: Display this help message"
echo "======================================"

if [ "$1" = "-h" ]; then
  exit 0
fi

interactive=0
set_frequency=0
forced_performance=0
forced_powersave=0

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
fi

echo "Running in $([ $interactive -eq 1 ] && echo "interactive" || echo "non-interactive") mode"

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
  if [ $interactive -eq 1 ]; then
    echo "userspace governor not found. Enable it? (y/n)"
    read enable_userspace
    if [ "$enable_userspace" = "y" ]; then
      echo "Enabling userspace governor"
      echo passive | sudo tee /sys/devices/system/cpu/intel_pstate/status
    else
      exit 1
    fi
  else
    echo "Error: userspace governor not found"
    # List available governors
    cpufreq-info | grep "available cpufreq governors"
    exit 1
  fi
fi

# Discharging means the laptop is running on battery
battery_mode=$(cat /sys/class/power_supply/BAT0/status)

set_max_scaling_freq () {
  # Set the CPU frequency to the specified value in Mhz

  echo "Setting CPU frequency to $1 Mhz"
  
  # Set the CPU governor to userspace
  sudo cpufreq-set -r -g userspace

  khz=$(echo "$1 * 1000" | bc)

  echo "set: $khz"

  if [ $khz -lt 1000 ]; then
    echo "Error: Invalid frequency"
    exit 1
  fi
  
  echo $khz | sudo tee /sys/devices/system/cpu/cpufreq/policy*/scaling_max_freq

}

parse_frequency_str_to_mhz() {
  max_frequency=$1

  if echo "$max_frequency" | grep -q "GHz"; then
    mhz=$(echo "$max_frequency" | sed 's/\([0-9]\+\)\.[0-9][0-9] GHz/\1 * 1000/' | bc)
  else
    mhz=$(echo "$max_frequency" | sed 's/\([0-9]\+\) MHz/\1/')
  fi

  echo $mhz
}

select_performance() {
  # First restore the user space frequency to the hardware limit
  echo "Performance mode selected - Setting CPU frequency to hardware limit"

  # get hardware limits
  # Eg parse "  hardware limits: 800 MHz - 5.00 GHz" to get 5.00 GHz
  hardware_limit_max=$(cpufreq-info | grep "hardware limits" | sed -n 's/.*\([0-9]\.[0-9][0-9] GHz\).*/\1/p')
  echo "Upper hardware limits detected:"
  echo "$hardware_limit_max"

  if [ -z "$hardware_limit_max" ]; then
    echo "Error: Hardware limits not found"
    exit 1
  fi

  # $hardware_limit_max is a list of frequencies
  # We want the last one
  max_frequency=$(echo "$hardware_limit_max" | tail -n 1)

  # parse GHz to Mhz, and preserve Mhz as is
  mhz=$(parse_frequency_str_to_mhz $max_frequency)
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
  hardware_limit_min=$(cpufreq-info | grep "hardware limits" | sed -n 's/.*hardware limits: \([0-9.]*\) \(GHz\|MHz\).*/\1 \2/p' | awk '{if ($2 == "GHz") print $1 * 1000; else print $1}')
  echo "Lower hardware limits detected:"
  echo "$hardware_limit_min"

  if [ -z "$hardware_limit_min" ]; then
    echo "Error: Hardware limits not found"
    exit 1
  fi

  # $hardware_limit_min is a list of frequencies
  # We want the first one

  min_frequency=$(echo "$hardware_limit_min" | head -n 1)

  mhz=$(parse_frequency_str_to_mhz $min_frequency)
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

    if [ $interactive -eq 1 ]; then
      echo "Press any key to continue"
      read -n 1 -s
    fi

    select_powersave

  else
    # Set the CPU governor to performance
    echo "AC power detected - Setting CPU governor to performance"

    if [ $interactive -eq 1 ]; then
      echo "Press any key to continue"
      read -n 1 -s
    fi

    select_performance
  fi
fi

# print current governor (collapse repeated output)
cpufreq-info | grep "current policy" | uniq