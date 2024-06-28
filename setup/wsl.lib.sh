#!/bin/bash

echo "Get SUDO credentials"
sudo ls -alF > /dev/null

#-- wsl.conf
if [ ! -f "/etc/wsl.conf" ]
then
  sudo cp -p files/wsl.conf /etc/wsl.conf
  sudo chown root:root /etc/wsl.conf
fi

#-- docker group
sudo usermod -aG docker "${USER}"

