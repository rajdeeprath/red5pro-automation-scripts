#!/bin/bash
#!/usr/bin/bash 
## --

cd ~

sudo apt-get install -y git
git clone -b  feature/unattended_automation https://github.com/rajdeeprath/red5pro-automation-scripts.git
cd ./red5pro-automation-scripts/installer/Linux
sudo chmod +x *.sh
sudo ./rpro-utils.sh -m 1 -o installurl -s 1 -p <red5pro-distribution-url>


