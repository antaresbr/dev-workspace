#!/bin/bash

#-- install dependencies
sudo apt install -y libswt-gtk-4-java

#-- dbeaver
wget wget https://dbeaver.io/files/dbeaver-ce_latest_amd64.deb --output-document=/tmp/dbeaver-amd64.deb
sudo dpkg -i /tmp/dbeaver-amd64.deb
rm /tmp/dbeaver-amd64.deb
