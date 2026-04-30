#!/usr/bin/env bash

set -euo pipefail

# ---------------------------------------------------
# KDE config files to migrate (including keybind files)
# ---------------------------------------------------
KDE_FILES=(
    "kdeglobals"
    "kwinrc"
    "kglobalshortcutsrc"
    "kcminputrc"
    "plasmarc"
    "kscreenlockerrc"
    "khotkeysrc"                                    # ← NEW: custom KDE hotkeys
    "plasma-org.kde.plasma.desktop-appletsrc"
)

# ---------------------------------------------------
# KDE keybinding accelerator files
# (These store internal shortcut state and custom script bindings)
# ---------------------------------------------------
KGLOBALACCEL_DIRS=(
    "kglobalaccel"                                  # ~/.local/share/kglobalaccel
)

# ============================================================
# Function: confirm required resource exists (file or dir)
# ============================================================
require() {
    local path="$1"
    local type="$2"  # file or dir

    if [[ "$type" == "dir" && ! -d "$path" ]]; then
        echo "❌ Required directory missing: $path"
        exit 1
    fi

    if [[ "$type" == "file" && ! -f "$path" ]]; then
        echo "❌ Required file missing: $path"
        exit 1
    fi
}

echo "============================================"
echo " KDE Plasma Configuration Migration Utility"
echo "============================================"
echo
echo "This script can:"
echo "  1) Mirror KDE Plasma settings from your OLD home directory"
echo "  2) Revert your original settings from backups"
echo
echo "Your current home: $HOME"
echo

echo "Choose an option:"
echo "  [1] Mirror KDE configuration"
echo "  [2] Revert to backup"
echo -n "> "
read -r choice

# ================================================================
# OPTION 2: REVERT TO BACKUP
# ================================================================
if [[ "$choice" == "2" ]]; then
    echo
    echo "Revert selected."
    echo

    require "$HOME/.config.backup-kde" "dir"
    require "$HOME/.local.share.backup-kde" "dir"

    echo "✔️ Backups found. Restoring..."
    rm -rf "$HOME/.config"
    rm -rf "$HOME/.local/share"

    mv "$HOME/.config.backup-kde" "$HOME/.config"
    mv "$HOME/.local.share.backup-kde" "$HOME/.local/share"

    echo "✔️ Restoration complete!"
    echo "Please log out and back in."
    exit 0
fi

# ================================================================
# OPTION 1: MIRROR KDE CONFIGS
# ================================================================
if [[ "$choice" != "1" ]]; then
    echo "❌ Invalid choice. Exiting."
    exit 1
fi

echo
echo "You chose: Mirror KDE configs"
echo

# Ask for old home directory
echo "Enter path to your OLD home directory:"
echo -n "> "
read -r OLD_HOME

# ---------------------------
# PRE-FLIGHT SAFETY CHECKS
# ---------------------------
echo
echo "Performing pre-flight checks..."
echo

# Basic directory checks
require "$OLD_HOME" "dir"
require "$OLD_HOME/.config" "dir"
require "$OLD_HOME/.local/share" "dir"
require "$HOME/.config" "dir"
require "$HOME/.local/share" "dir"

# ------------------------------------------------------------
# BACKUP DIRECTORY HANDLING (interactive)
# ------------------------------------------------------------
if [[ -d "$HOME/.config.backup-kde" || -d "$HOME/.local.share.backup-kde" ]]; then
    echo "⚠️  Existing KDE backup directories detected:"
    [[ -d "$HOME/.config.backup-kde" ]] && \
        echo "   - $HOME/.config.backup-kde"
    [[ -d "$HOME/.local.share.backup-kde" ]] && \
        echo "   - $HOME/.local.share.backup-kde"

    echo
    echo "Choose an action:"
    echo "  [R] Remove old backups and create fresh ones"
    echo "  [S] Skip creating backups and continue migration"
    echo "  [C] Cancel (safe choice)"
    echo -n "> "
    read -r backup_choice

    case "$backup_choice" in
        R|r)
            echo "🗑 Removing old backup directories..."
            rm -rf "$HOME/.config.backup-kde" 2>/dev/null || true
            rm -rf "$HOME/.local.share.backup-kde" 2>/dev/null || true
            echo "✔️ Old backups removed."
            ;;
        S|s)
            echo "⏭ Skipping backup creation."
            SKIP_BACKUP=true
            ;;
        *)
            echo "❌ Cancelled by user."
            exit 1
            ;;
    esac
fi

# Warn if none of the KDE files exist on old system
FOUND_ANY=false
for file in "${KDE_FILES[@]}"; do
    if [[ -f "$OLD_HOME/.config/$file" ]]; then
        FOUND_ANY=true
        break
    fi
done

if [[ "$FOUND_ANY" = false ]]; then
    echo "❌ No KDE Plasma config files found in old home:"
    echo "   $OLD_HOME/.config/"
    exit 1
fi

echo "✔️ All pre-flight checks passed!"
echo

read -p "Proceed with migration? (y/n) " -r
if [[ ! "$REPLY" =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 0
fi

# ------------------------------------------------------------
# CREATE BACKUPS
# ------------------------------------------------------------
echo

SKIP_BACKUP=${SKIP_BACKUP:-false}

if [[ "$SKIP_BACKUP" = false ]]; then
    echo
    echo "Creating backups of current configuration..."
    cp -r "$HOME/.config" "$HOME/.config.backup-kde"
    cp -r "$HOME/.local/share" "$HOME/.local.share.backup-kde"
    echo "✔️ Backups created."
else
    echo "⚠️ Backups were skipped by user."
fi

echo "   $HOME/.config.backup-kde"
echo "   $HOME/.local.share.backup-kde"

# ------------------------------------------------------------
# COPY KDE CONFIG FILES (including keybinds)
# ------------------------------------------------------------
echo
echo "Copying KDE Plasma configuration files..."
echo

for file in "${KDE_FILES[@]}"; do
    if [[ -f "$OLD_HOME/.config/$file" ]]; then
        echo "→ Copying $file"
        cp "$OLD_HOME/.config/$file" "$HOME/.config/$file"
    else
        echo "→ Skipping $file (not found)"
    fi
done

# ------------------------------------------------------------
# COPY KDE KEYBIND ACCELERATOR DATA
# ------------------------------------------------------------
echo
echo "Copying KDE keyboard accelerator directories..."
echo

for dir in "${KGLOBALACCEL_DIRS[@]}"; do
    if [[ -d "$OLD_HOME/.local/share/$dir" ]]; then
        echo "→ Copying $dir"
        rm -rf "$HOME/.local/share/$dir" 2>/dev/null || true
        cp -r "$OLD_HOME/.local/share/$dir" "$HOME/.local/share/$dir"
    else
        echo "→ Skipping $dir (not found)"
    fi
done

echo
echo "✔️ KDE config migration finished safely!"
echo "Please log out and log back in to apply changes."
echo

exit 0
