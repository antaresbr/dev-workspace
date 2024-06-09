#!/bin/bash

echo "Get SUDO access"
sudo ls -alF > /dev/null

source base.lib.sh
source docker.lib.sh
source wsl.lib.sh

source dbeaver.lib.sh
