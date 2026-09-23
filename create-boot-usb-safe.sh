#!/bin/bash

set -euo pipefail

if ! command -v lsblk >/dev/null 2>&1; then
    echo "Error: lsblk is required."
    exit 1
fi

if ! command -v dd >/dev/null 2>&1; then
    echo "Error: dd is required."
    exit 1
fi

if ! command -v udisksctl >/dev/null 2>&1; then
    echo "Error: udisksctl is required for safe unmounting."
    exit 1
fi

read -e -p "Enter the path to the image file: " IMAGE_PATH

if [[ ! -f "$IMAGE_PATH" ]]; then
    echo "Error: Image file does not exist: $IMAGE_PATH"
    exit 1
fi

echo
echo "Detected removable USB disks (stable IDs):"

declare -a IDS=()
declare -a DEVS=()
declare -a SIZES=()
declare -a MODELS=()
declare -a SERIALS=()

for link in /dev/disk/by-id/*; do
    [[ -L "$link" ]] || continue
    base=$(basename "$link")
    [[ "$base" == *-part* ]] && continue

    case "$base" in
        usb-*|ata-*|scsi-*)
            ;;
        *)
            continue
            ;;
    esac

    dev=$(readlink -f "$link" || true)
    [[ -b "$dev" ]] || continue

    transport=$(lsblk -dn -o TRAN "$dev" 2>/dev/null | tr -d ' ')
    hotplug=$(lsblk -dn -o HOTPLUG "$dev" 2>/dev/null | tr -d ' ')
    rmflag=$(lsblk -dn -o RM "$dev" 2>/dev/null | tr -d ' ')

    if [[ "$transport" != "usb" && "$hotplug" != "1" && "$rmflag" != "1" ]]; then
        continue
    fi

    size=$(lsblk -dn -o SIZE "$dev" 2>/dev/null | tr -d ' ')
    model=$(lsblk -dn -o MODEL "$dev" 2>/dev/null | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    serial=$(lsblk -dn -o SERIAL "$dev" 2>/dev/null | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

    skip=0
    for seen in "${IDS[@]:-}"; do
        if [[ "$seen" == "$link" ]]; then
            skip=1
            break
        fi
    done
    [[ "$skip" -eq 1 ]] && continue

    IDS+=("$link")
    DEVS+=("$dev")
    SIZES+=("$size")
    MODELS+=("${model:-unknown-model}")
    SERIALS+=("${serial:-unknown-serial}")
done

if [[ "${#IDS[@]}" -eq 0 ]]; then
    echo "No removable USB disks found via /dev/disk/by-id."
    echo "Try re-plugging the stick, then run: lsblk -d -o NAME,SIZE,MODEL,SERIAL,TRAN,HOTPLUG"
    exit 1
fi

for i in "${!IDS[@]}"; do
    n=$((i + 1))
    printf "[%d] %s\n" "$n" "${IDS[$i]}"
    printf "    dev=%s size=%s model=%s serial=%s\n" "${DEVS[$i]}" "${SIZES[$i]}" "${MODELS[$i]}" "${SERIALS[$i]}"
done

echo
read -r -p "Select target number: " pick

if ! [[ "$pick" =~ ^[0-9]+$ ]]; then
    echo "Error: selection must be a number."
    exit 1
fi

idx=$((pick - 1))
if (( idx < 0 || idx >= ${#IDS[@]} )); then
    echo "Error: selection out of range."
    exit 1
fi

TARGET_ID="${IDS[$idx]}"
TARGET_DEV="${DEVS[$idx]}"
TARGET_SIZE="${SIZES[$idx]}"
TARGET_SERIAL="${SERIALS[$idx]}"

serial_token="$TARGET_SERIAL"
if [[ "$serial_token" == "unknown-serial" || -z "$serial_token" ]]; then
    serial_token=$(basename "$TARGET_ID")
fi

serial_clean=$(printf "%s" "$serial_token" | tr -cd '[:alnum:]')
if [[ -z "$serial_clean" ]]; then
    serial_tail="UNKNOWN"
elif (( ${#serial_clean} <= 6 )); then
    serial_tail="$serial_clean"
else
    serial_tail="${serial_clean: -6}"
fi

echo
echo "Target selected:"
echo "  ID:     $TARGET_ID"
echo "  Device: $TARGET_DEV"
echo "  Size:   $TARGET_SIZE"
echo "  Serial: $TARGET_SERIAL"
echo
echo "WARNING: ALL DATA ON THIS DEVICE WILL BE DESTROYED."
read -r -p "Type ERASE to continue: " confirm_erase
if [[ "$confirm_erase" != "ERASE" ]]; then
    echo "Cancelled."
    exit 1
fi

read -r -p "Type the device size exactly ($TARGET_SIZE): " confirm_size
if [[ "$confirm_size" != "$TARGET_SIZE" ]]; then
    echo "Cancelled: size mismatch."
    exit 1
fi

read -r -p "Type last 6 serial chars ($serial_tail): " confirm_serial
if [[ "$confirm_serial" != "$serial_tail" ]]; then
    echo "Cancelled: serial tail mismatch."
    exit 1
fi

echo
echo "Unmounting mounted partitions on $TARGET_DEV (if any)..."
base_name=$(basename "$TARGET_DEV")
while read -r part_name; do
    [[ "$part_name" == "$base_name" ]] && continue
    part_dev="/dev/$part_name"
    mountpoint=$(lsblk -ln -o MOUNTPOINT "$part_dev" 2>/dev/null || true)
    [[ -z "$mountpoint" ]] && continue
    sudo udisksctl unmount -b "$part_dev" >/dev/null 2>&1 || sudo umount "$part_dev" >/dev/null 2>&1 || true
done < <(lsblk -ln -o NAME "$TARGET_DEV")

echo "Writing image to $TARGET_ID ..."
sudo dd if="$IMAGE_PATH" of="$TARGET_ID" bs=4M status=progress conv=fsync
sync

echo
echo "Done."
echo "Tip: If the USB stick is physically very hot, let it cool for a minute before unplugging."
