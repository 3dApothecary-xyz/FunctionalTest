#!/bin/bash

# KGP 4x2209 Functional Test Script
#
# Code here is documented at: https://github.com/3dApothecary-xyz/FunctionalTest/tree/main?tab=readme-ov-file#functional-test-process

ftVersion() {
  ver="0.01" # Initial Version to Debug Firmware Load
  ver="0.02" # Confirm Klipper is Running
             # Start Testing

  echo "$ver"
}

# Written by: myke predko
# mykepredko@3dapothecary.xyz
# (C) Copyright 2025 for File Contents and Data Formatting

# NOTE for logic debugging use the Bash Debugger running on a CB2 Host

# To Load the Bash Debugger:
# BashDB Information: https://bashdb.sourceforge.net/
# BashDB Git Repository: https://sourceforge.net/p/bashdb/code/ci/master/tree/
# To Download, Modify to work with Bash 5.1 and install BashDB:
# BashDB Download: https://sourceforge.net/projects/bashdb/files/bashdb/5.0-1.1.2/bashdb-5.0-1.1.2.tar.gz/download
# To Extract BashDB: tar -xvzf bashdb-5.0-1.1.2.tar.gz
# sudo nano ~/bashdb-5.0-1.1.2/configure 
#     Search for ".0'" using ^W and change to ".1' | '5.1')"
# ./configure
# make
# Run "./bashdb filename.sh" from the ~/bashdb-5.0-1.1.2 directory
#
# May have to run as root user: sudo su
#
# bashdb Commands
#  action     condition  edit     frame    load     run     source  unalias  
#  alias      continue   enable   handle   next     search  step    undisplay
#  backtrace  debug      eval     help     print    set     step+   untrace  
#  break      delete     examine  history  pwd      shell   step-   up       
#  clear      disable    export   info     quit     show    tbreak  watch    
#  commands   display    file     kill     return   signal  trace   watche   
#  complete   down       finish   list     reverse  skip    tty   
#
#  "s[tep]" single steps/"Steps in"
#  "n[ext]" skips over methods
#  "c[ontinue]" executes to next breakpoint or end
#  "info break" lists active breakpoints

# Some Syntax checking options:
# "bash -n ./ft.sh" to check for Logic errors
# "bash -u ./ft.sh -something" to check for "unbounded variables" (ie not initialized) during execution


########################################################################
# Initialization Code Start 
########################################################################
set -e  # Stop on Errors
#set -x  # Show all values 

sudo service klipper stop

########################################################################
# Setup Environment to execute in the User Home Directory
########################################################################
originalDir="$(pwd)"
cd ~
homeDirectory=`pwd`
rootFile=`ls ~ -al`
newLine="
"
TTY=~/printer_data/comms/klippy.serial


########################################################################
# Global Values
########################################################################
true=0
false=1


########################################################################
# Standard Messages
########################################################################
applicationDoneMsg="User Requested Application Exit"


########################################################################
# Test Methods
########################################################################
Test1() {

  pingResponse=$(ping -c 2 klipper.discourse.group)

  if echo "$pingResponse" | grep -q "2 packets transmitted, 2 received,"; then
    result=true
  else
    result=false
  fi
  
  echo "$result"
}


########################################################################
# Standard Display Messages & Methods
########################################################################
applicationDoneMsg="User Requested Application Exit"

#                      1111111111222222222233333333334444444444555555555566666666667777
#            01234567890123456789012345678901234567890123456789012345678901234567890123
EMPTYSTRING="                                                                          "
PHULLSTRING="##########################################################################"
displayWidth=${#EMPTYSTRING}

BLACK='\e[0;30m'
RED='\e[0;31m'
GREEN='\e[0;32m'
BROWN='\e[0;33m'
BLUE='\e[0;34m'
PURPLE='\e[0;35m'
CYAN='\e[0;36m'
LIGHTGRAY='\e[0;37m'
DARKGRAY='\e[1;30m'
LIGHTRED='\e[1;31m'
LIGHTGREEN='\e[1;32m'
YELLOW='\e[1;33m'
LIGHTBLUE='\e[1;34m'
LIGHTPURPLE='\e[1;35m'
LIGHTCYAN='\e[1;36m'
WHITE='\e[1;37m'
BASE='\e[0m'

outline=$RED
highlight=$LIGHTBLUE
active=$LIGHTGRAY
inactive=$DARKGRAY
em=$YELLOW
re=$LIGHTGRAY

# Color tag definition
# %b - black, use $DARKGRAY
# %w - white, use $LIGHTGRAY (Basic color for ASCII Graphics)
# %y - yellow, use $YELLOW as baasic high light Color
# %r - red, use $RED
# %l - light red, use $LIGHTRED
# %g - green, use $GREEN
# %c - Blueish/green, use $CYAN

clearScreen() {
  printf "\ec"
}
echoGreen(){
    echo -e "\e[32m${1}\e[0m"
}
echoRed(){
    echo -e "\e[31m${1}\e[0m"
}
echoBlue(){
    echo -e "\e[34m${1}\e[0m"
}
echoYellow(){
    echo -e "\e[33m${1}\e[0m"
}
drawHeader() {
headerName="$1"

  clearScreen
#                        111111111122222222223333333333444444444455555555556666666666
#              0123456789012345678901234567890123456789012345678901234567890123456789 
  echo -e "$outline$PHULLSTRING"
  version=$(ftVersion) 
  headerLength=${#headerName}
  versionLength=${#version}
  stringLength=$(( displayWidth - ( 4 + 4 + 4 + 1 + versionLength + headerLength )))
  echo -e "##$highlight  FT $version ${EMPTYSTRING:0:$stringLength} ${1}  $outline##"

  echo -e "$PHULLSTRING$BASE"
}
doAppend() {
#$# $1 strings to display/execute

  for argument in "$@"; do
    appendString=$argument
    appendLength=${#appendString}
    if [ "!" == "${appendString:0:1}" ]; then
      appendString="${appendString:1}"
      appendLength=$(( $appendLength - 1 ))
    fi
    stringLength=$(( displayWidth - ( 4 + 4 + 1 + appendLength )))
    echo -e "$outline##$highlight  $appendString ${EMPTYSTRING:0:$stringLength}  $outline##"
  done

  echo -e     "$PHULLSTRING$BASE"
  
  for argument in "$@"; do
    appendString=$argument
    if [ "!" != "${appendString:0:1}" ]; then
      $appendString
    fi
  done
}
drawError() {
errorHeaderMessage="$1"
errorString="$2"

  echo -e "$outline$PHULLSTRING"
  version=$(ftVersion) 
  headerLength=${#errorHeaderMessage}
  versionLength=${#version}
  stringLength=$(( displayWidth - ( 4 + 4 + 4 + 1 + versionLength + headerLength )))
  echo -e "##$highlight  FT $version ${EMPTYSTRING:0:$stringLength} $errorHeaderMessage  $outline##"
  echo -e "$outline$PHULLSTRING
##  EEEEEEEEEEE   RRRRRRRR      RRRRRRRR         OOOOO      RRRRRRRR    ##
##  EEEEEEEEEEE   RRRRRRRRRR    RRRRRRRRRR     OOOOOOOOO    RRRRRRRRRR  ##
##  EEE     EEE   RRR     RRR   RRR     RRR   OOOO   OOOO   RRR     RRR ##
##  EEE           RRR     RRR   RRR     RRR   OOO     OOO   RRR     RRR ##
##  EEE           RRR     RRR   RRR     RRR   OOO     OOO   RRR     RRR ##
##  EEE            RRR   RRRR   RRR    RRR    OOO     OOO   RRR    RRR  ##
##  EEEEEE        RRRRRRRR      RRRRRRRR      OOO     OOO   RRRRRRRR    ##
##  EEEEEE        RRRRRRRR      RRRRRRRR      OOO     OOO   RRRRRRRR    ##
##  EEE           RRR RRR       RRR RRR       OOO     OOO   RRR RRR     ##
##  EEE           RRR  RRR      RRR  RRR      OOO     OOO   RRR  RRR    ##
##  EEE           RRR   RRR     RRR   RRR     OOO     OOO   RRR   RRR   ##
##  EEE     EEE   RRR    RRR    RRR    RRR    OOOO   OOOO   RRR    RRR  ##
##  EEEEEEEEEEE   RRR     RRR   RRR     RRR    OOOOOOOOO    RRR     RRR ##
##  EEEEEEEEEEE   RRR     RRR   RRR     RRR      OOOOO      RRR     RRR ##
##                                                                      ##
$PHULLSTRING"

  currentString="$errorString"
  while [[ $currentString != "" ]]; do
    read -a currentStringArray <<< $currentString
    currentStringArraySize=${#currentStringArray[@]}
    i=0
    currentString=""
    currentStringLength=0
    currentWord=${currentStringArray[$i]}
    currentWordLength=${#currentWord}
    while [ $displayWidth -gt $(( $currentStringLength + $currentWordLength + 6 )) ] && [ $i -lt $currentStringArraySize ]; do
      currentString="$currentString $currentWord"
      currentStringLength=${#currentString}
      i=$(( $i + 1 ))
      currentWord=${currentStringArray[$i]}
      currentWordLength=${#currentWord}
    done
    stringLength=$(( $displayWidth - ( 4 + 1 + $currentStringLength )))
    echo -e     "##$highlight $currentString${EMPTYSTRING:0:stringLength}$outline##"
    currentString=""
    while [ $i -lt $currentStringArraySize ]; do
      if [[ $currentString != "" ]]; then
        currentString="$currentString ${currentStringArray[$i]}"
      else 
        currentString="${currentStringArray[$i]}"
      fi
      i=$(( $i + 1 ))
    done
  done

  echo -e     "$PHULLSTRING$BASE"
}
drawSplashScreen() {

  drawHeader "KGP 4x2209 Functional Test"
#                                       11111111112222222222333333333344444444445555555555666666666677        77
#                    01         2345678901234567890123456789012345678901234567890123456789012345678901        23 
  echo -e "$outline##$inactive                                                                      $outline##
##$LIGHTRED     #   #  ###  ####           #         ###   ###   ###   ###       $outline##
##$LIGHTRED     #  #  #     #   #         ##        #   # #   # #   # #   #      $outline##
##$LIGHTRED     # #   #     #   #        # #  #   #     #     # #   # #   #      $outline##
##$LIGHTRED     ##    #  ## ####        #  #   # #    ##    ##  # # #  ####      $outline##
##$LIGHTRED     # #   #   # #           #####   #    #     #    #   #     #      $outline##
##$LIGHTRED     #  #  #   # #              #   # #  #     #     #   #    #       $outline##
##$LIGHTRED     #   # ####  #              #  #   # ##### #####  ###   ##        $outline##
##$LIGHTRED                                                                      $outline##
##$LIGHTRED           #####                   #####              #               $outline##
##$LIGHTRED           #                         #                #               $outline##
##$LIGHTRED           #     #   # # ##   ###    #    ###   ###  ###              $outline##
##$LIGHTRED           ####  #   # ##  # #       #   #   # #      #               $outline##
##$LIGHTRED           #     #   # #   # #       #   #####  ###   #               $outline##
##$LIGHTRED           #     #  ## #   # #   #   #   #         #  #  #            $outline##
##$LIGHTRED           #      ## # #   #  ###    #    ###  ####    ##             $outline##
##$LIGHTRED                                                                      $outline##
$PHULLSTRING$BASE"
}




########################################################################
# Mainline Code Start
########################################################################
drawSplashScreen



########################################################################
# Firmware Load Start
########################################################################

echo -e "  "
echo -e "$outline$PHULLSTRING"
doAppend "!Firmware Load"

lsusbResponse=$(lsusb)

echo -e "  "
echo -e "FLS:01"
echo -e "$lsusbResponse"
echo -e "  "

if echo "$lsusbResponse" | grep -q "0483:df11"; then
  loadKatapult=1
else
  python ~/python/enableKatapult.py
  
  sleep 1
  
  katapultResponse=$(ls /dev/serial/by-id) || true

  echo -e "FLS:02"
  echo -e "$katapultResponse"
  echo -e "  "

  if echo "$katapultResponse" | grep -q "usb-katapult_stm32g0b1xx_"; then
    loadKatapult=0
  else
    python ~/python/enableDFU.py
  
    sleep 1
        
    lsusbResponse=$(lsusb) || true

    echo -e "FLS:03"
    echo -e "$lsusbResponse"
    echo -e "  "

    if echo "$lsusbResponse" | grep -q "0483:df11"; then
      loadKatapult=1
    else
      drawError "Loading Firmware" "Unable to Activate DFU Mode or Katapult"
      exit
    fi
  fi
fi

if [ 0 -ne $loadKatapult ]; then  
  sudo dfu-util -a 0 -D ~/bin/katapult.bin --dfuse-address 0x08000000:force:mass-erase:leave -d 0483:df11 || true

  sleep 1
    
  python ~/python/enableKatapult.py
  
  sleep 1
  
  katapultResponse=$(ls /dev/serial/by-id) || true

  echo -e "  "
  echo -e "FLS:04"
  echo -e "$katapultResponse"
  echo -e "  "

  if echo "$katapultResponse" | grep -q "usb-katapult_stm32g0b1xx_"; then
    loadKatapult=1
  else
    drawError "Loading Firmware" "Error with Katapult Loading"
    exit
  fi
fi

python3 ~/katapult/scripts/flashtool.py -f ~/bin/KGP_4x2209_DFU.bin -d /dev/serial/by-id/$katapultResponse

sleep 1
    
python ~/python/enableKatapult.py
  
sleep 1
  
dfuResponse=$(ls /dev/serial/by-id)

echo -e "  "
echo -e "FLS:05"
echo -e "$dfuResponse"
echo -e "  "

if echo "$dfuResponse" | grep -q "usb-katapult_stm32g0b1xx_"; then
  loadKatapult=1
else
  drawError "Loading Firmware" "Unable to Restart Katapult after KGP_4x2209_DFU.bin Load"
  exit
fi

python3 ~/katapult/scripts/flashtool.py -f ~/bin/klipper.bin -d /dev/serial/by-id/$katapultResponse

sleep 1

configFolder=$(ls ~/printer_data/config)

echo -e "  "
echo -e "FLS:06"
echo -e "$configFolder"
echo -e "  "

if echo "$configFolder" | grep -q "mcu.cfg"; then
  rm ~/printer_data/config/mcu.cfg
fi

canUUID=$(~/klippy-env/bin/python ~/klipper/scripts/canbus_query.py can0)

echo -e "FLS:07"
echo -e "$canUUID"
echo -e "  "

mapfile -t canUUIDArray <<< "$canUUID"

toolheadCfgUUID=$(<~/printer_data/config/toolhead.cfg)

mapfile -t toolheadCfgUUIDArray <<< "$toolheadCfgUUID"
toolheadUUID="${toolheadCfgUUIDArray[1]}"

toolheadUUID="${toolheadUUID#canbus_uuid: }"
toolheadUUID="${toolheadUUID%:0:12}"

echo -e "FLS:08"
echo -e "$toolheadUUID"
echo -e "  "

mcuUUID=""
i=1
for arrayElement in "${canUUIDArray[@]}"; do
  if echo "$arrayElement" | grep "Found canbus_uuid="; then
    arrayElement="${arrayElement#Found canbus_uuid=}"  
    arrayElement="${arrayElement:0:12}"

    echo -e "FLS:09-$i"
    i=$((i+1))
    echo -e "$arrayElement"
    echo -e "  "
    
    if [[ "$arrayElement" == "$toolheadUUID" ]]; then
      echo -e "Match to Toolhead UUID"
    else
      mcuUUID="$arrayElement"
    fi
  fi
done

echo -e "FLS:10"
echo -e "$mcuUUID"
echo -e "  "

printf "[mcu]\ncanbus_uuid: $mcuUUID\n" > ~/printer_data/config/mcu.cfg



########################################################################
# Verify Klipper is Running
########################################################################

echo -e "  "
echo -e "$outline$PHULLSTRING"
doAppend "!Klipper Startup"

sudo service klipper start

klipperFlag=0
for ((i=1;10>=i;++i)); do
  if [ $klipperFlag -eq 0 ]; then
    sleep 2

    echo -ne "STATUS\n" > "$TTY" 
    RESPONSE=$(timeout 2 cat "$TTY") || true

    if echo "$RESPONSE" | grep -q "Klipper state: Ready"; then
      klipperFlag=1

      echo -e "  "
      echo -e "VKR:$i"
      echo -e "STATUS RESPONSE=$RESPONSE"
      echo -e "  "
    else
      if echo "$RESPONSE" | grep -q "Can not update MCU 'host' config as it is shutdown"; then
        sleep 2

        echo -ne "FIRMWARE_RESTART\n" > "$TTY" 
        RESTART_RESPONSE=$(timeout 2 cat "$TTY") || true

        if echo "$RESTART_RESPONSE" | grep -q "Klipper state: Ready"; then
          klipperFlag=1

          echo -e "  "
          echo -e "VKR:$i"
          echo -e "FIRMWARE_RESTART RESPONSE=$RESTART_RESPONSE"
          echo -e "  "
        else
          echo -e "  "
          echo -e "VKR:$i"
          echo -e "STATUS RESPONSE=$RESPONSE"
          echo -e "  "
          echo -e "Sent FIRMWARE_RESTART"
          echo -e "  "
        fi
      fi
    fi
  fi
done

if [ $klipperFlag -eq 1 ]; then
  echo -e "VKR:Complete"
  echo -e "Klipper Running"
  echo -e "  "
else 
  drawError "Klipper Not Starting Up" "Contact Support"
  exit
fi



########################################################################
# Functional Tests Follows
########################################################################

echo -e "  "
echo -e "$outline$PHULLSTRING"
doAppend "!Klipper Functional Test"
echo -e "  "


########################################################################
# TEST01: Ping
########################################################################

echo -e "$outline$PHULLSTRING"
doAppend "!TEST01: Ping"

pingRESPONSE=$(ping -c 2 klipper.discourse.group)

if echo "$pingRESPONSE" | grep -q "klipper.hosted"; then
  echo "TEST01: Ping Test Complete"
  echo -e "  "
else
  echo -e "  "
  drawError "TEST01: Ping" "No Response"
  exit
fi





########################################################################
## STOP HERE WHILE DEVELOPING CODE
########################################################################
exit
