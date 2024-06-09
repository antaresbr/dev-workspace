#!/bin/bash

echo "Obtém credenciais SUDO"
sudo ls -alF > /dev/null

source base.lib.sh
source docker.lib.sh
source snaps.lib.sh

