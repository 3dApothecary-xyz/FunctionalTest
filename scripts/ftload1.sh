#!/bin/bash
# Script to simplify Functional Test Micro SD Card setup
# Execute with "curl -s https://raw.githubusercontent.com/3dApothecary-xyz/FunctionalTest/refs/heads/main/scripts/ftload1.sh | bash"
# 2025.08.27 - Updated to place ft.sh in the home folder/not in a "scripts" folder
sudo apt-get install git -y
sudo apt install python3 python3-serial -y
mkdir python
cd python
wget -O cycle38.py https://github.com/3dApothecary-xyz/FunctionalTest/blob/main/python/cycle38.py?raw=true
wget -O cycleBLPROBE.py https://github.com/3dApothecary-xyz/FunctionalTest/blob/main/python/cycleBLPROBE.py?raw=true
wget -O cycleRESET.py https://github.com/3dApothecary-xyz/FunctionalTest/blob/main/python/cycleRESET.py?raw=true
wget -O enableDFU.py https://github.com/3dApothecary-xyz/FunctionalTest/blob/main/python/enableDFU.py?raw=true
wget -O enableKatapult.py https://github.com/3dApothecary-xyz/FunctionalTest/blob/main/python/enableKatapult.py?raw=true
wget -O gpioread.py https://github.com/3dApothecary-xyz/FunctionalTest/blob/main/python/gpioread.py?raw=true
wget -O toggleBOOT0.py https://github.com/3dApothecary-xyz/FunctionalTest/blob/main/python/toggleBOOT0.py?raw=true
chmod 777 *.py
cd ~
#mkdir scripts
#cd scripts
wget -O ft.sh https://github.com/3dApothecary-xyz/FunctionalTest/blob/main/scripts/ft.sh?raw=true
chmod 777 *.sh
#cd ~
mkdir logs
mkdir bin
cd bin
wget -O nada.bin https://github.com/3dApothecary-xyz/FunctionalTest/blob/main/bin/nada.bin?raw=true
wget -O KGP_4x2209_DFU.bin https://github.com/3dApothecary-xyz/FunctionalTest/blob/main/bin/KGP_4x2209_DFU.bin?raw=true
cd ~
git clone https://github.com/dw-0/kiauh.git
git clone https://github.com/Arksine/katapult

# Reverse Steps 57 and 58 (might as well force the board into DFU Mode)
# Step 69: Note that printer.cfg can also be cut and pasted into printer.cfg on Mainsail
# Step 71: ./scripts/loaddynamicmacros.sh
# Step 74: ./scripts/installdynamicmacros.sh
