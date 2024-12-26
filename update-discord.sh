#!/bin/bash

sudo wget -O discord.deb "https://discordapp.com/api/download?platform=linux&format=deb"
# wait for download to finish
sleep 2
sudo dpkg -i discord.deb
sudo rm discord.deb
echo "Discord updated"
