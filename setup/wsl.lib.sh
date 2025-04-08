#!/bin/bash

echo "Get SUDO credentials"
sudo ls -alF > /dev/null

#-- wsl.conf
if [ ! -f "/etc/wsl.conf" ]
then
  sudo cp -p files/wsl.conf /etc/wsl.conf
  sudo chown root:root /etc/wsl.conf
fi
if [ ! -d "/etc/wsl.d" ]
then
  sudo mkdir /etc/wsl.d
  sudo cp -p files/wsl.d/* /etc/wsl.d/
  sudo chown root:root /etc/wsl.d/*
fi

#-- dnsmasq
if [ ! -f /etc/wsl.d/hosts ]
then
  sudo cp /etc/hosts /etc/wsl.d/
  sudo rm /etc/hosts
  sudo ln -s wsl.d/hosts /etc/hosts
fi

if ! which dnsmasq &> /dev/null
then
  sudo systemctl disable systemd-resolved.service
  sudo systemctl stop systemd-resolved.service
  sudo rm /etc/resolv.conf
  echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf

  sudo apt update
  sudo apt install -y dnsmasq
  
  [ ! /etc/dnsmasq.conf ] || sudo mv /etc/dnsmasq.conf /etc/dnsmasq.conf.original
  sudo ln -s wsl.d/dnsmasq.conf /etc/dnsmasq.conf
  
  sudo rm /etc/resolv.conf
  sudo ln -s wsl.d/resolv.conf /etc/resolv.conf

  sudo systemctl enable dnsmasq
  sudo systemctl restart dnsmasq
fi
