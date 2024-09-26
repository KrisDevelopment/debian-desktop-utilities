#!/bin/bash
sizeoftrash=$(du -sh ~/.local/share/Trash | awk '{print $1}')
echo "Deleting $sizeoftrash from Trash ? (y/n)"
read answer
if [ "$answer" != "${answer#[Yy]}" ] ;then
    echo "Emptying Trash..."
else
    echo "Exiting..."
    exit 0
fi
sudo rm -rf ~/.local/share/Trash/*
