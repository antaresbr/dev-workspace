#!/bin/bash

echo "Get SUDO credentials"
sudo ls -alF > /dev/null

source base.lib.sh
source docker.lib.sh
source snaps.lib.sh
source x2go.lib.sh

