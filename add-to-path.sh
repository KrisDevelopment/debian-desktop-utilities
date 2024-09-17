#!/bin/bash

# Prompt the user for a directory with read -e (enables tab completion for file paths)
read -e -p "Enter the directory to add to the PATH: " custom_dir

# Check if the directory exists
if [ ! -d "$custom_dir" ]; then
    echo "Directory does not exist. Please create it first."
    exit 1
fi

# Determine the shell being used (bash or zsh)
if [ "$SHELL" = "/bin/bash" ]; then
    profile_file="$HOME/.bashrc"
elif [ "$SHELL" = "/bin/zsh" ]; then
    profile_file="$HOME/.zshrc"
else
    echo "Unsupported shell. This script works with bash or zsh only."
    exit 1
fi

# Backup the current profile file
cp "$profile_file" "$profile_file.bak"

# Add the custom directory to the PATH if not already added
if grep -q "export PATH=\"$custom_dir" "$profile_file"; then
    echo "Directory is already in the PATH."
else
    echo "export PATH=\"$custom_dir:\$PATH\"" >> "$profile_file"
    echo "Directory added to the PATH in $profile_file"
fi

# Source the profile file to apply changes immediately
source "$profile_file"

echo "The PATH has been updated successfully."
