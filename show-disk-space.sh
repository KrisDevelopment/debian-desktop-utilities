#!/bin/bash

# Get terminal width (fallback 80)
term_width=$(tput cols 2>/dev/null || echo 80)

# Fixed layout widths
FS_WIDTH=35
FREE_WIDTH=8
PCT_WIDTH=5

# Compute bar width dynamically
BAR_WIDTH=$(( term_width - FS_WIDTH - FREE_WIDTH - PCT_WIDTH - 10 ))
(( BAR_WIDTH < 10 )) && BAR_WIDTH=10

color() {
    local p=$1
    if (( p < 70 )); then
        echo -ne "\033[32m"   # green
    elif (( p < 90 )); then
        echo -ne "\033[33m"   # yellow
    else
        echo -ne "\033[31m"   # red
    fi
}

reset="\033[0m"

print_bar() {
    local fs="$1"
    local mount="$2"
    local avail="$3"
    local used="${4%\%}"

    # truncate filesystem column
    local label="${mount}"
    (( ${#label} > FS_WIDTH )) && label="${label:0:FS_WIDTH-3}..."

    local filled=$(( used * BAR_WIDTH / 100 ))
    local empty=$(( BAR_WIDTH - filled ))

    local bar_filled bar_empty
    bar_filled=$(printf '%*s' "$filled" '' | tr ' ' '#')
    bar_empty=$(printf '%*s' "$empty" '' | tr ' ' '-')

    local c=$(color "$used")

    printf "%-${FS_WIDTH}s %${FREE_WIDTH}s " "$label" "$avail"
    echo -ne "[${c}${bar_filled}${reset}${bar_empty}] "
    printf "%3s%%\n" "$used"
}

df -h --output=target,avail,pcent -x tmpfs -x devtmpfs |
tail -n +2 |
while read -r mount avail pcent; do
    print_bar "" "$mount" "$avail" "$pcent"
done