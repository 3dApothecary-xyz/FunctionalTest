#!/bin/bash

# Script to simplify Functional Test Micro SD Card setup
# Execute with "curl -s https://raw.githubusercontent.com/3dApothecary-xyz/FunctionalTest/refs/heads/main/scripts/ftload2.sh | bash"
cd ~/printer_data/config
wget -O dynamic.cfg https://github.com/3dApothecary-xyz/FunctionalTest/blob/main/configs/dynamic.cfg?raw=true
wget -O read_adxl.py https://github.com/3dApothecary-xyz/FunctionalTest/blob/main/configs/read_adxl.py?raw=true
wget -O read_blt.py https://github.com/3dApothecary-xyz/FunctionalTest/blob/main/configs/read_blt.py?raw=true
wget -O read_tmc_field.py https://github.com/3dApothecary-xyz/FunctionalTest/blob/main/configs/read_tmc_field.py?raw=true
chmod 777 dynamic.cfg
chmod 777 *.py
cd ~
git clone https://github.com/3DCoded/DynamicMacros
cd DynamicMacros
sh install.sh
sudo service klipper restart
cd ~
