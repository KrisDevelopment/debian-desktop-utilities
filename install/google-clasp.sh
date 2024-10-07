#!/bin/bash

# Installs Google clasp

# How to use: https://developers.google.com/apps-script/guides/clasp

# check if npm is installed
if ! [ -x "$(command -v npm)" ]; then
    echo "Error: npm is not installed. Installing npm..."
    sudo apt-get install npm
fi

sudo npm install -g @google/clasp
