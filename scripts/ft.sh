#!/bin/bash

# KGP 4x2209 Functional Test Script
#
# Code here is documented at: https://github.com/3dApothecary-xyz/FunctionalTest/tree/main?tab=readme-ov-file#functional-test-process

ftVersion() {
  ver="0.01" # Initial Version to Debug Firmware Load
  ver="0.02" # Confirm Klipper is Running
             # Start Testing
  ver="0.03" # Continue adding Test Code
             # Put in Software "Sealing" operation
  ver="0.04" # Add Test Log File 
             # Change Individual Functional Test Code to allow easy reordering
  ver="0.05" # Adding LED Check Screen Method
             # Added "trap '' SIGINT" to Prevent User from Ctrl-C

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
# Script Listing/
########################################################################
set -e  # Stop on Errors
#set -x  # Show all values 
# trap '' SIGINT

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
heatersOff() {

  echo -ne "OFFHEATER0\n" > "$TTY" || true

  TEST_RESPONSE=$(timeout 1 cat "$TTY") || true

  echo -ne "OFFHEATER1\n" > "$TTY" || true

  TEST_RESPONSE=$(timeout 1 cat "$TTY") || true
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

clearScreen() {
  printf "\ec"
}

echoE() {
  echo -e "$1" >&2
  
  tempInput="$1"
  tempOutput=""

  for (( i=0; i <= ${#tempInput}; ++i )); do
    if [[ "\\" == "${tempInput:$i:1}" ]]; then
      if [[ "e" == "${tempInput:(($i+1)):1}" ]]; then
        i=$(($i+7))
      else
        tempOutput="$tempOutput${tempInput:$i:1}"
      fi
    else
      tempOutput="$tempOutput${tempInput:$i:1}"
    fi
  done
  
  logFileImage="$logFileImage\n$tempOutput"
}

drawHeader() {
headerName="$1"

#                        111111111122222222223333333333444444444455555555556666666666
#              0123456789012345678901234567890123456789012345678901234567890123456789 
  echo -e "$outline$PHULLSTRING"
  version=$(ftVersion) 
  headerLength=${#headerName}
  versionLength=${#version}
  stringLength=$(( displayWidth - ( 4 + 4 + 4 + 1 + versionLength + headerLength )))
  echo -e "##$highlight  FT $version ${EMPTYSTRING:0:$stringLength} ${1}  $outline##"
  logsLength=${#logFileName}
  stringLength=$(( displayWidth - ( 4 + 4 + logsLength )))
  echo -e "##$highlight  $logFileName ${EMPTYSTRING:0:$stringLength} $outline##"

  echo -3 "$PHULLSTRING$BASE"
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

  echo -e "$PHULLSTRING$BASE"
  
  for argument in "$@"; do
    appendString=$argument
    if [ "!" != "${appendString:0:1}" ]; then
      $appendString
    fi
  done
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
drawPASS() {

  drawHeader "$errorHeaderMessage"
  echo -e "$outline##$BLUE                                                                      $outline##
##$BLUE            ########        ##        ######      ######              $outline##
##$BLUE            ########        ##        ######      ######              $outline##
##$BLUE            ##      ##    ##  ##    ##      ##  ##      ##            $outline##
##$BLUE            ##      ##    ##  ##    ##      ##  ##      ##            $outline##
##$BLUE            ##      ##  ##      ##  ##          ##                    $outline##
##$BLUE            ##      ##  ##      ##  ##          ##                    $outline##
##$BLUE            ########    ##      ##    ######      ######              $outline##
##$BLUE            ########    ##      ##    ######      ######              $outline##
##$BLUE            ##          ##########          ##          ##            $outline##
##$BLUE            ##          ##########          ##          ##            $outline##
##$BLUE            ##          ##      ##  ##      ##  ##      ##            $outline##
##$BLUE            ##          ##      ##  ##      ##  ##      ##            $outline##
##$BLUE            ##          ##      ##    ######      ######              $outline##
##$BLUE            ##          ##      ##    ######      ######              $outline##
##$BLUE                                                                      $outline##
$PHULLSTRING$BASE"
}
drawError() {
errorHeaderMessage="$1"
errorString="$2"

  drawHeader "$errorHeaderMessage"
  echo -e "$outline##                                                                      ##
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

  echo -e "$PHULLSTRING$BASE"
}
drawLED() {

  testNumber="$1"
  promptMsg=""
  if [[ "1" == "$2" ]]; then
    powerLED="$WHITE"
    powerBlock="$LIGHTCYAN"
    promptMsg="Confirm White Power LED Lit"
  else
    powerLED="$DARKGRAY"
    powerBlock="$DARKGRAY"
  fi
  if [[ "2" == "$2" ]]; then
    boot0LED="$LIGHTGREEN"
    boot0LED="$WHITE"
    boot0Button="$LIGHTCYAN"
    promptMsg="Confirm Pressing 'BOOT0' Turns Green LED On"
  else
    boot0LED="$DARKGRAY"
    boot0Button="$DARKGRAY"
  fi
  if [[ "3" == "$2" ]]; then
    resetLED="$ORANGE"
    resetLED="$WHITE"
    promptMsg="Confirm Orange LED Flashing"
  else
    resetLED="$DARKGRAY"
  fi
  if [[ "4" == "$2" ]]; then
    dsLED0="$YELLOW"
    dsLED0="$WHITE"
    dsCONN0="$YELLOW"
    promptMsg="Confirm Yellow DSENSOR0 LED Lit"
  else
    dsLED0="$DARKGRAY"
    dsCONN0="$DARKGRAY"
  fi
  if [[ "5" == "$2" ]]; then
    dsLED1="$YELLOW"
    dsLED1="$WHITE"
    dsCONN1="$YELLOW"
    promptMsg="Confirm Yellow DSENSOR1 LED Lit"
  else
    dsLED1="$DARKGRAY"
    dsCONN1="$DARKGRAY"
  fi
  if [[ "6" == "$2" ]]; then
    dsLED2="$YELLOW"
    dsLED2="$WHITE"
    dsCONN2="$YELLOW"
    promptMsg="Confirm Yellow DSENSOR2 LED Lit"
  else
    dsLED2="$DARKGRAY"
    dsCONN2="$DARKGRAY"
  fi
  if [[ "7" == "$2" ]]; then
    dsLED3="$YELLOW"
    dsLED3="$WHITE"
    dsCONN3="$YELLOW"
    promptMsg="Confirm Yellow DSENSOR3 LED Lit"
  else
    dsLED3="$DARKGRAY"
    dsCONN3="$DARKGRAY"
  fi
  if [[ "8" == "$2" ]]; then
    dsLED4="$YELLOW"
    dsLED4="$WHITE"
    dsCONN4="$YELLOW"
    promptMsg="Confirm Yellow DSENSOR4 LED Lit"
  else
    dsLED4="$DARKGRAY"
    dsCONN4="$DARKGRAY"
  fi
  if [[ "9" == "$2" ]]; then
    heater0LED="$LIGHTRED"
    heater0LED="$WHITE"
    heater0CONN="$RED"
    promptMsg="Confirm Red HEATER0 LED Flashing"
  else
    heater0LED="$DARKGRAY"
    heater0CONN="$DARKGRAY"
  fi
  if [[ "10" == "$2" ]]; then
    heater1LED="$LIGHTRED"
    heater1LED="$WHITE"
    heater1CONN="$RED"
    promptMsg="Confirm Red HEATER1 LED Flashing"
  else
    heater1LED="$DARKGRAY"
    heater1CONN="$DARKGRAY"
  fi
  if [[ "11" == "$2" ]]; then
    fan0LED="$LIGHTBLUE"
    fan0LED="$WHITE"
    fan0CONN="$BLUE"
    promptMsg="Confirm Blue FAN0 LED Lit"
  else
    fan0LED="$DARKGRAY"
    fan0CONN="$DARKGRAY"
  fi
  if [[ "12" == "$2" ]]; then
    fan1LED="$LIGHTBLUE"
    fan1LED="$WHITE"
    fan1CONN="$BLUE"
    promptMsg="Confirm Blue FAN1 LED Lit"
  else
    fan1LED="$DARKGRAY"
    fan1CONN="$DARKGRAY"
  fi
  if [[ "13" == "$2" ]]; then
    fan2LED="$LIGHTBLUE"
    fan2LED="$WHITE"
    fan2CONN="$BLUE"
    promptMsg="Confirm Blue FAN2 LED Lit"
  else
    fan2LED="$DARKGRAY"
    fan2CONN="$DARKGRAY"
  fi
  if [[ "14" == "$2" ]]; then
    fan3LED="$LIGHTBLUE"
    fan3LED="$WHITE"
    fan3CONN="$BLUE"
    promptMsg="Confirm Blue FAN3 LED Lit"
  else
    fan3LED="$DARKGRAY"
    fan3CONN="$DARKGRAY"
  fi
  if [[ "15" == "$2" ]]; then
    blLED="$LIGHTBLUE"
    blLED="$WHITE"
    blCONN="$WHITE"
    promptMsg="Confirm BL Touch LED Lit"
  else
    blLED="$DARKGRAY"
    blCONN="$DARKGRAY"
  fi
  if [[ "16" == "$2" ]]; then
    indLED="$LIGHTBLUE"
    indLED="$WHITE"
    indCONN="$WHITE"
    promptMsg="Confirm Inductive Sensor LED Lit"
  else
    indLED="$DARKGRAY"
    indCONN="$DARKGRAY"
  fi

  drawLEDSpace=$((${#PHULLSTRING} - (8 + 4 + 2 + 2 + ${#promptMsg})))

  echo -e "$outline$PHULLSTRING
##$highlight  TEST$testNumber: $promptMsg ${EMPTYSTRING:0:drawLEDSpace} $outline##
$PHULLSTRING
##$DARKGRAY      /----------|---|$dsCONN0|--|$DARKGRAY|---||--$fan0CONN|-|$heater0CONN|OO|$DARKGRAY|-|-|---|-|-----|-----\      $outline##
##$DARKGRAY      $dsCONN1-|$DARKGRAY$dsLED1 O $DARKGRAY       --- $dsCONN0 -- $DARKGRAY ---  --$fan0LED O$heater0CONN |__| $DARKGRAY   |   | |     |     |      $outline##
##$DARKGRAY      $dsCONN1-|$DARKGRAY               $dsLED0 O  $DARKGRAY           $heater0LED O $DARKGRAY    |___| |_____|  ---|      $outline##
##$DARKGRAY      -|                                                   |   |      $outline##
##$DARKGRAY      -|    _    ____                                      |   |      $outline##
##$DARKGRAY      -    | |  |    |                                      ---|      $outline##
##$DARKGRAY      ||   | |  |    |                                         |      $outline##
##$DARKGRAY      -    |_|  |____|                                         |      $outline##
##$DARKGRAY      $dsCONN2-|$DARKGRAY$dsLED2 O $DARKGRAY  $boot0LED O $DARKGRAY   $resetLED O $DARKGRAY                                         |      $outline##
##$DARKGRAY      $dsCONN2-|$DARKGRAY    $boot0Button |_| $DARKGRAY  |_|                       _________________ |      $outline##
##$DARKGRAY      -                              __    /                  \|      $outline##
##$DARKGRAY      ||                            |  |   |                  ||      $outline##
##$DARKGRAY      -               $dsLED3 O$dsCONN3 _ $DARKGRAY         |__|   |                  ||      $outline##
##$DARKGRAY     $heater1CONN - $DARKGRAY      _      $dsCONN3 |___| $DARKGRAY         __    |                  ||      $outline##
##$DARKGRAY     $heater1CONN O|$heater1LED O $DARKGRAY  | |                    |  |   |                  ||      $outline##
##$DARKGRAY     $heater1CONN O|$DARKGRAY     |_|      $dsLED4 O$dsCONN4 _ $DARKGRAY         |__|   |                  ||      $outline##
##$DARKGRAY     $heater1CONN - $DARKGRAY             $dsCONN4 |___| $DARKGRAY               \__________________/|      $outline##
##$DARKGRAY      -|                    $powerLED O  $DARKGRAY ____                          |      $outline##
##$DARKGRAY      -|     $powerBlock              _____$DARKGRAY|    |     x x x x x x x x x x |      $outline##
##$DARKGRAY      | $fan1LED O $blLED O $fan2LED O$indLED O$fan3LED O $DARKGRAY     $powerBlock|     $DARKGRAY|    |     x x x x x x x x x x |      $outline##
##$DARKGRAY      \_$fan1CONN|_$blCONN|___$fan2CONN|_$indCONN|_$fan3CONN|_$DARKGRAY|_____$powerBlock|_O_O_$DARKGRAY|____|_________________________/      $outline##
##$DARKGRAY                                                                      $outline##
$PHULLSTRING$BASE" >&2
  
echo -e -n "LED Behaving as Expected? (Y/N): " >&2
stty_original=$(stty -g)
stty raw -echo
response=""
while IFS= read -rsn1 character; do
  if [[ "$character" == $'\x08' || "$character" == $'\x7f' ]]; then
    if [[ -n "$response" ]]; then
      response=""
      echo -e -n "\b \b" >&2
    fi
  elif [[ "$character" == "" && -n "$response" ]]; then # Enter key
    break
  elif [[ "$character" == "y" || "$character" == "Y" ]]; then 
    if [[ -z "$response" ]]; then
      response="Y"
      echo -e -n "Y" >&2
    fi
  elif [[ "$character" == "n" || "$character" == "N" ]]; then 
    if [[ -z "$response" ]]; then
      response="N"
      echo -e -n "N" >&2
    fi
  fi
done

# Restore original terminal settings
stty "$stty_original"

echo "$response"
  
}




########################################################################
# Mainline Code Start/Setup Log File Name
########################################################################

sudo service klipper stop

currentDateTime=$(date -u "+%F-%H-%M-%S")

logsDirContents=$(ls ~/logs -l)
mapfile -t logsDirContentsArray <<< "$logsDirContents"
nextLogsNumber=${#logsDirContentsArray[@]}
logsNumber="0${nextLogsNumber}"
while [ 5 -gt ${#logsNumber} ]; do
  logsNumber="0$logsNumber"
done
logFileName="LOG$logsNumber-$currentDateTime.log"

clearScreen
drawSplashScreen


########################################################################
# Firmware Load Start
########################################################################

echoE "  "
echo -e  "$outline$PHULLSTRING"
doAppend "!Firmware Load"
logFileImage="Firmware Load"

lsusbResponse=$(lsusb)

echoE "  "
echoE "FLS:01"
echoE "$lsusbResponse"
echoE "  "

if echo "$lsusbResponse" | grep -q "0483:df11"; then
  loadKatapult=1
else
  python ~/python/enableKatapult.py
  
  sleep 1
  
  katapultResponse=$(ls /dev/serial/by-id) || true

  echoE "FLS:02"
  echoE "$katapultResponse"
  echoE "  "

  if echo "$katapultResponse" | grep -q "usb-katapult_stm32g0b1xx_"; then
    loadKatapult=0
  else
    python ~/python/enableDFU.py
  
    sleep 1
        
    lsusbResponse=$(lsusb) || true

    echoE "FLS:03"
    echoE "$lsusbResponse"
    echoE "  "

    if echo "$lsusbResponse" | grep -q "0483:df11"; then
      loadKatapult=1
    else
      drawError "Loading Firmware" "Unable to Activate DFU Mode or Katapult"
      logFileImage="$logFileImage\nUnable to Activate DFU Mode or Katapult"
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

  echoE "  "
  echoE "FLS:04"
  echoE "$katapultResponse"
  echoE "  "

  if echo "$katapultResponse" | grep -q "usb-katapult_stm32g0b1xx_"; then
    loadKatapult=1
  else
    drawError "Loading Firmware" "Error with Katapult Loading"
    logFileImage="$logFileImage\nError with Katapult Loading"
    exit
  fi
fi

python3 ~/katapult/scripts/flashtool.py -f ~/bin/KGP_4x2209_DFU.bin -d /dev/serial/by-id/$katapultResponse

sleep 1
    
python ~/python/enableKatapult.py
  
sleep 1
  
dfuResponse=$(ls /dev/serial/by-id)

echoE "  "
echoE "FLS:05"
echoE "$dfuResponse"
echoE "  "

if echo "$dfuResponse" | grep -q "usb-katapult_stm32g0b1xx_"; then
  loadKatapult=1
else
  drawError "Loading Firmware" "Unable to Restart Katapult after KGP_4x2209_DFU.bin Load"
  logFileImage="$logFileImage\nUnable to Restart Katapult after KGP_4x2209_DFU.bin Load"
  exit
fi

python3 ~/katapult/scripts/flashtool.py -f ~/bin/klipper.bin -d /dev/serial/by-id/$katapultResponse

sleep 1

configFolder=$(ls ~/printer_data/config)

echoE "  "
echoE "FLS:06"
echoE "$configFolder"
echoE "  "

if echo "$configFolder" | grep -q "mcu.cfg"; then
  rm ~/printer_data/config/mcu.cfg
fi

canUUID=$(~/klippy-env/bin/python ~/klipper/scripts/canbus_query.py can0)

echoE "FLS:07"
echoE "$canUUID"
echoE "  "

mapfile -t canUUIDArray <<< "$canUUID"

toolheadCfgUUID=$(<~/printer_data/config/toolhead.cfg)

mapfile -t toolheadCfgUUIDArray <<< "$toolheadCfgUUID"
toolheadUUID="${toolheadCfgUUIDArray[1]}"

toolheadUUID="${toolheadUUID#canbus_uuid: }"
toolheadUUID="${toolheadUUID%:0:12}"

echoE "FLS:08"
echoE "$toolheadUUID"
echoE "  "

mcuUUID=""
i=1
for arrayElement in "${canUUIDArray[@]}"; do
  if echo "$arrayElement" | grep "Found canbus_uuid="; then
    arrayElement="${arrayElement#Found canbus_uuid=}"  
    arrayElement="${arrayElement:0:12}"

    echoE "FLS:09-$i"
    i=$((i+1))
    echoE "$arrayElement"
    echoE "  "
    
    if [[ "$arrayElement" == "$toolheadUUID" ]]; then
      echoE "Match to Toolhead UUID"
    else
      mcuUUID="$arrayElement"
    fi
  fi
done

echoE "FLS:10"
echoE "$mcuUUID"
echoE "  "

printf "[mcu]\ncanbus_uuid: $mcuUUID\n" > ~/printer_data/config/mcu.cfg



########################################################################
# Verify Klipper is Running
########################################################################

echoE "  "
echo -e  "$outline$PHULLSTRING"
doAppend "!Klipper Startup"
logFileImage="$logFileImage\nKlipper Startup"

sudo service klipper start

klipperFlag=0
for ((i=1;10>=i;++i)); do
  if [ $klipperFlag -eq 0 ]; then
    sleep 2

    echo -ne "STATUS\n" > "$TTY" 
    RESPONSE=$(timeout 2 cat "$TTY") || true

    if echo "$RESPONSE" | grep -q "Klipper state: Ready"; then
      klipperFlag=1

      echoE "  "
      echoE "VKR:$i"
      echoE "STATUS RESPONSE=$RESPONSE"
      echoE "  "
    else
      if echo "$RESPONSE" | grep -q "Can not update MCU 'host' config as it is shutdown"; then
        sleep 2

        echo -ne "FIRMWARE_RESTART\n" > "$TTY" 
        RESTART_RESPONSE=$(timeout 2 cat "$TTY") || true

        if echo "$RESTART_RESPONSE" | grep -q "Klipper state: Ready"; then
          klipperFlag=1

          echoE "  "
          echoE "VKR:$i"
          echoE "FIRMWARE_RESTART RESPONSE=$RESTART_RESPONSE"
          echoE "  "
        else
          echoE "  "
          echoE "VKR:$i"
          echoE "STATUS RESPONSE=$RESPONSE"
          echoE "  "
          echoE "Sent FIRMWARE_RESTART"
          echoE "  "
        fi
      fi
    fi
  fi
done

if [ $klipperFlag -eq 1 ]; then
  echoE "VKR:Complete"
  echoE "Klipper Running"
  echoE "  "
else 
  drawError "VKR: Error.  Klipper Not Starting Up" "Contact Support"
  logFileImage="$logFileImage\nVKR: Error.  Klipper Not Starting Up"
  exit
fi



########################################################################
# Functional Tests Follows
########################################################################

echoE "  "
echo -e  "$outline$PHULLSTRING"
doAppend "!KGP 4x2209 Functional Test"
logFileImage="$logFileImage\nKGP 4x2209 Functional Test"
echoE "  "

########################################################################
testNUM="01"  # Ping
########################################################################

echo -e  "$outline$PHULLSTRING"
doAppend "!TEST$testNUM: Ping"
logFileImage="$logFileImage\nTEST$testNUM: Ping"

pingRESPONSE=$(ping -c 2 klipper.discourse.group)

if echo "$pingRESPONSE" | grep -q "klipper.hosted"; then
  echoE   "TEST$testNUM: Ping Test Complete"
  echoE "  "
else
  echoE "  "
  drawError "TEST$testNUM: Ping" "No Response"
  logFileImage="$logFileImage\nTEST$testNUM: Ping No Response"
  exit
fi

########################################################################
testNUM="02"  # VINMON
########################################################################

echo -e  "$outline$PHULLSTRING"
doAppend "!TEST$testNUM: VINMON"
logFileImage="$logFileImage\nTEST$testNUM: VINMON"

echo -ne "TEST02\n" > "$TTY" || true

TEST_RESPONSE=$(timeout 1 cat "$TTY") || true

echoE "$TEST_RESPONSE"

if echo "$TEST_RESPONSE" | grep -q "Test02: VINMON Test: PASS"; then
  echoE   "TEST$testNUM: VINMON Test Complete"
  echoE "  "
else
  echoE "  "
  drawError "TEST$testNUM: VINMON" "Invalid Voltage Read"
  logFileImage="$logFileImage\nTEST$testNUM: VINMON Invalid Voltage Read"
  exit
fi

########################################################################
testNUM="03"  # MCU Temperature
########################################################################

echo -e  "$outline$PHULLSTRING"
doAppend "!TEST$testNUM: MCU Temperature"
logFileImage="$logFileImage\nTEST$testNUM: MCU Temperature"

echo -ne "TEST03\n" > "$TTY" || true

TEST_RESPONSE=$(timeout 1 cat "$TTY") || true

echoE "$TEST_RESPONSE"

if echo "$TEST_RESPONSE" | grep -q "Test03: MCU Temperature Test: PASS"; then
  echoE "TEST$testNUM: MCU Temperature Test Complete"
  echoE "  "
else
  echoE "  "
  drawError "TEST$testNUM: MCU Temperature Test" "Invalid MCU Temperature Value Read"
  logFileImage="$logFileImage\nTEST$testNUM: Invalid MCU Temperature Value Read"
  exit
fi

########################################################################
testNUM="04"  # Toolhead Temperature
########################################################################

echo -e  "$outline$PHULLSTRING"
doAppend "!TEST$testNUM: Toolhead Temperature"
logFileImage="$logFileImage\nTEST$testNUM: Toolhead Temperature"

echo -ne "TEST04\n" > "$TTY" || true

TEST_RESPONSE=$(timeout 1 cat "$TTY") || true

echoE "$TEST_RESPONSE"

if echo "$TEST_RESPONSE" | grep -q "Test04: Toolhead Temperature Test: PASS"; then
  echoE "TEST$testNUM: Toolhead Temperature Test Complete"
  echoE "  "
else
  echoE "  "
  drawError "TEST$testNUM: Toolhead Temperature Test" "Invalid Toolhead Temperature Value Read"
  logFileImage="$logFileImage\nTEST$testNUM: Invalid Toolhead Temperature Value Read"
  exit
fi

########################################################################
testNUM="05"  # THERMO0 Temperature
########################################################################

echo -e  "$outline$PHULLSTRING"
doAppend "!TEST$testNUM: THERMO0 Temperature"
logFileImage="$logFileImage\nTEST$testNUM: THERMO0 Temperature"

echo -ne "TEST05\n" > "$TTY" || true

TEST_RESPONSE=$(timeout 1 cat "$TTY") || true

echoE "$TEST_RESPONSE"

if echo "$TEST_RESPONSE" | grep -q "Test05: THERMO0 Test: PASS"; then
  echoE "TEST$testNUM: THERMO0 Temperature Test Complete"
  echoE "  "
else
  if echo "$TEST_RESPONSE" | grep -q "Test05: Check THERMO0 Connection to Thermistor"; then
    echoE "  "
    drawError "TEST$testNUM: THERMO0 Temperature Test" "Check Thermistor THERMO0 Connection to Board Under Test"
    logFileImage="$logFileImage\nTEST$testNUM: Check Thermistor THERMO0 Connection to Board Under Test"
    exit
  else
    echoE "  "
    drawError "TEST$testNUM: THERMO0 Temperature Test" "Invalid THERMO0 Thermistor Temperature Value Read"
    logFileImage="$logFileImage\nTEST$testNUM: Invalid THERMO0 Thermistor Temperature Value Read"
    exit
  fi
fi

########################################################################
testNUM="06"  # THERMO1 Temperature
########################################################################

echo -e  "$outline$PHULLSTRING"
doAppend "!TEST$testNUM: THERMO1 Temperature"
logFileImage="$logFileImage\nTEST$testNUM: THERMO1 Temperature"

echo -ne "TEST06\n" > "$TTY" || true

TEST_RESPONSE=$(timeout 1 cat "$TTY") || true

echoE "$TEST_RESPONSE"

if echo "$TEST_RESPONSE" | grep -q "Test06: THERMO1 Test: PASS"; then
  echoE "TEST$testNUM: THERMO0 Temperature Test Complete"
  echoE "  "
else
  if echo "$TEST_RESPONSE" | grep -q "Test06: Check THERMO1 Connection to Thermistor"; then
    echoE "  "
    drawError "TEST$testNUM: THERMO1 Temperature Test" "Check Thermistor THERMO1 Connection to Board Under Test"
    logFileImage="$logFileImage\nTEST$testNUM: Check Thermistor THERMO1 Connection to Board Under Test"
    exit
  else
    echoE "  "
    drawError "TEST$testNUM: THERMO1 Temperature Test" "Invalid Thermistor Temperature Value Read"
    logFileImage="$logFileImage\nTEST$testNUM: Invalid THERMO1 Thermistor Temperature Value Read"
    exit
  fi
fi

########################################################################
testNUM="07"  # Set HEATER0 Temperature to 40C
########################################################################

echo -e  "$outline$PHULLSTRING"
doAppend "!TEST$testNUM: Set HEATER0 Temperature to 40C"
logFileImage="$logFileImage\nTEST$testNUM: Set HEATER0 Temperature to 40C"

echo -ne "TEST07\n" > "$TTY" || true

TEST_RESPONSE=$(timeout 1 cat "$TTY") || true

echoE "$TEST_RESPONSE"

if echo "$TEST_RESPONSE" | grep -q "Test07: HEATER0 Set to 40"; then
  echoE "TEST$testNUM: Set HEATER0 Temperature to 40C"
  echoE "  "
else
  echoE "  "
  drawError "TEST$testNUM: Set HEATER0 Temperature to 40C" "Unable to Set HEATER0 Temperature"
  logFileImage="$logFileImage\nTEST$testNUM: Unable to Set HEATER0 Temperature"
  heatersOff
  exit
fi

########################################################################
testNUM="08"  # Set HEATER1 Temperature to 40C
########################################################################

echo -e  "$outline$PHULLSTRING"
doAppend "!TEST$testNUM: Set HEATER1 Temperature to 40C"
logFileImage="$logFileImage\nTEST$testNUM: Set HEATER1 Temperature to 40C"

echo -ne "TEST08\n" > "$TTY" || true

TEST_RESPONSE=$(timeout 1 cat "$TTY") || true

echoE "$TEST_RESPONSE"

if echo "$TEST_RESPONSE" | grep -q "Test08: HEATER1 Set to 40"; then
  echoE "TEST$testNUM: Set HEATER1 Temperature to 40C"
  echoE "  "
else
  echoE "  "
  drawError "TEST$testNUM: Set HEATER1 Temperature to 40C" "Unable to Set HEATER1 Temperature"
  logFileImage="$logFileImage\nTEST$testNUM: Unable to Set HEATER1 Temperature"
  heatersOff
  exit
fi









########################################################################
## Turn Heaters off to ensure they're not left on
########################################################################

heatersOff

########################################################################
## Tests Complete: Conditional Execution from Here to Avoid Problems
########################################################################
sealingFlag=0

if [[ 1 -eq $sealingFlag ]]; then

########################################################################
## Tests Complete: Software Sealing
########################################################################

  echoE "$outline$PHULLSTRING"
  doAppend "!Software Sealing"
  logFileImage="$logFileImage\nSoftware Sealing"

  python ~/python/enableKatapult.py
  
  sleep 1
  
  katapultResponse=$(ls /dev/serial/by-id) || true

  echoE "SSS:01"
  echoE "$katapultResponse"
  echoE "  "

  if echo "$katapultResponse" | grep -q "usb-katapult_stm32g0b1xx_"; then
    python3 ~/katapult/scripts/flashtool.py -f ~/bin/nada.bin -d /dev/serial/by-id/$katapultResponse
  
    sleep 1
 
    python ~/python/cycleRESET.py
  
    sleep 2
 
    katapultResponse=$(ls /dev/serial/by-id) || true

    echoE " "
    echoE "$katapultResponse"

    echoE " "
    drawPASS   
   
#### - Need to Set NeoPixels to BLUE
    echoE " "
    echoE "#### Need to Set NeoPixels to BLUE"
  
  else
    echoE "  "
    drawError "Software Sealing" "Unable to Start Katapult"
    logFileImage="$logFileImage\nSoftware Sealing" "Unable to Start Katapult"
  fi
else
  echoE " "
  drawPASS   
fi

echoE " "
yN=$(drawLED "01" "1")

echoE " "
echoE "Yes/No Response is: $yN"

echo -e "$logFileImage" > ~/logs/$logFileName


exit
