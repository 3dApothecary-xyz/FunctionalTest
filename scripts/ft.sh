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
  ver="0.06" # Reorganizing Tests to better match the workflow
             # Instituting Dynamic Macros to the tests
  ver="0.07" # Added DSENSOR# Tests
  ver="0.08" # Added FAN# Tests/Check
             # Moved DSENSOR# Turn Off before Response Check
             # Changed "CheckLED" to use LED Net Name instead of Number
             # Added Increment testNUM before each test rather than set it
             # Put in Loop Code to Check DSENSORs rather than individual test blocks
  ver="0.09" # Added ability to allow Running Checks with simple flags
             # Updates for NewHat3
  ver="0.10" # Updates for NewHat3a/HeaterBoard
             # Updates for changes in printer.cfg for VIN, MCU and Toolhead presence/temperature/voltage checks
             # Removed expdlicit ADXL345 & BLTouch Tests
             # Removed "heatersoff" method
             # Updated "dsensor#" tests for NewHat3a demux wiring (with matching updates in printer.cfg)
             # Added Inductive Sensor Test
             # Added BLTouch Test
             # Added SPI OR Gate Test
  ver="0.11" # Added "heater#" and "fan# tests
             # Added rPi 40 Pin Header Pin Function Table for use in heater#/fan# tests
             # Moved all the test enable variables to start of script to make test customization simpler
             # Discovered that variables in methods aren't local, changed all "i" variables to reflect execution location
# NOTE: If Test Error - Logfile is not saved.             
  echo "$ver"
}

# Written by: myke predko
# mykepredko@3dapothecary.xyz
# (C) Copyright 2025 for File Contents and Data Formatting

# Test Enable Variables 
doLEDCheck=0                        # Setting to Zero Disables the Manual LED Check
doToolheadTemperatureCheck=1
doThermoTemperatureCheck=1
doDSensorCheck=1
doIndStopCheck=1
doBLTouchCheck=1
doSPICheck=1
doHeaterCheck=1                     # Setting to Zero Also Disables the VIN Check & Fan Check
doFanCheck=1
sealingFlag=0


# Raspberry Pi 40 Pin Header Pin Function Table
#
# -------------+-------------+-------------+-------------------------------------------------|
# Function     | Pin Number  | GPIO Number | Comment                                         |
# -------------+-------------+-------------+-------------------------------------------------|
# | +3V3 Power |  1          | N/A         |                                                 |
# | +5V Power  |  2          | N/A         |                                                 |
neopixel0=3    #  3          | GPIO2       |                                                 |
# | +5V Power  |  4          | N/A         |                                                 |
neopixel1=5    #  5          | GPIO3       |                                                 |
# | GND        |  6          | N/A         |                                                 |
BOOT0=7        #  7          | GPIO4       |                                                 |
# | UART0 TX   |  8          | N/A         |                                                 |
# | GND        |  9          | N/A         |                                                 |
# | UART0 RX   | 10          | N/A         |                                                 |
RESET=11       # 11          | GPIO17      |                                                 |
blprobe=12     # 12          | GPIO18      |                                                 |
spicsmosi=13   # 13          | GPIO27      |                                                 |
# | GND        | 14          | N/A         |                                                 |
blservo=15     # 15          | GPIO22      |                                                 |
htr1complo=16  # 16          | GPIO23      |                                                 |
# | +3V3 Power | 17          | N/A         |                                                 |
htr1comphi=18  # 18          | GPIO24      |                                                 |
fan0comphi=19  # 19          | GPIO19      |                                                 |
# | GND        | 20          | N/A         |                                                 |
DEMUX_C=21     # 21          | GPIO9       |                                                 |
fan0complo=22  # 22          | GPIO25      | VIN to HeaterBoard Provided using this pin      |
DEMUX_B=23     # 23          | GPIO11      |                                                 |
htr0complo=24  # 24          | GPIO8       |                                                 |
# | GND        | 25          | N/A         |                                                 |
DEMUX_A=26     # 26          | GPIO7       |                                                 |
# | RESERVED   | 27          | N/A         |                                                 |
# | RESERVED   | 28          | N/A         |                                                 |
fan2comphi=29  # 29          | GPIO5       |                                                 |
# | GND        | 30          | N/A         |                                                 |
fan3complo=31  # 31          | GPIO6       |                                                 |
fan3comphi=32  # 32          | GPOI012     |                                                 |
htr0comphi=33  # 33          | GPIO19      |                                                 |
# | GND        | 34          | N/A         |                                                 |
fan1complo=35  # 35          | GPIO19      |                                                 |
fan2complo=36  # 36          | GPIO16      |                                                 |
ssrcomphi=37   # 37          | GPIO26      |                                                 |
ssrcomplo=38   # 38          | GPIO20      |                                                 |
# | GND        | 39          | N/A         |                                                 |
fan1comphi=40  # 40          | GPIO21      |                                                 |
# -------------+-------------+-------------+-------------------------------------------------|


# NOTE for logic debugging use the Bash Debugger running on a CB2 Host

# To Load the Bash Debugger:
# BashDB Information: https://bashdb.sourceforge.net/
# BashDB Git Repository: https://sourceforge.net/p/bashdb/code/ci/master/tree/
# To Download, Modify to work with Bash 5.1 and install BashDB:
# BashDB Download: https://sourceforge.net/projects/bashdb/files/bashdb/5.0-1.1.2/bashdb-5.0-1.1.2.tar.gz/download
# To Extract BashDB: tar -xvzf bashdb-5.0-1.1.2.tar.gz
# sudo nano ~/bashdb-5.0-1.1.2/configure 
# if Raspberry Pi:
#     Search for ".0'" using ^W and change to ".2' | '5.2')"
# if BTT CB1:
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
#  "print $VariableName" Displays variable's contents

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
makeTestNUMString() {
  tempTestNUM="$1"
  if [[ 1 -eq ${#tempTestNUM} ]]; then
    tempTestNUM="0$tempTestNUM"
  fi
  echo "$tempTestNUM"
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

  for (( ee=0; ee <= ${#tempInput}; ++ee )); do
    if [[ "\\" == "${tempInput:$ee:1}" ]]; then
      if [[ "e" == "${tempInput:(($ee+1)):1}" ]]; then
        ee=$(($ee+7))
      else
        tempOutput="$tempOutput${tempInput:$ee:1}"
      fi
    else
      tempOutput="$tempOutput${tempInput:$ee:1}"
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
    de=0
    currentString=""
    currentStringLength=0
    currentWord=${currentStringArray[$de]}
    currentWordLength=${#currentWord}
    while [ $displayWidth -gt $(( $currentStringLength + $currentWordLength + 6 )) ] && [ $de -lt $currentStringArraySize ]; do
      currentString="$currentString $currentWord"
      currentStringLength=${#currentString}
      de=$(( $de + 1 ))
      currentWord=${currentStringArray[$de]}
      currentWordLength=${#currentWord}
    done
    stringLength=$(( $displayWidth - ( 4 + 1 + $currentStringLength )))
    echo -e     "##$highlight $currentString${EMPTYSTRING:0:stringLength}$outline##"
    currentString=""
    while [ $de -lt $currentStringArraySize ]; do
      if [[ $currentString != "" ]]; then
        currentString="$currentString ${currentStringArray[$de]}"
      else 
        currentString="${currentStringArray[$de]}"
      fi
      de=$(( $de + 1 ))
    done
  done

  echo -e "$PHULLSTRING$BASE"
}
checkLED() {

  testNumber="$1"
  promptMsg=""
  if [[ "Power" == "$2" ]]; then
    powerLED="$WHITE"
    powerBlock="$LIGHTCYAN"
    promptMsg="Confirm White Power LED Lit"
  else
    powerLED="$DARKGRAY"
    powerBlock="$DARKGRAY"
  fi
  if [[ "BOOT0" == "$2" ]]; then
    boot0LED="$LIGHTGREEN"
    boot0LED="$WHITE"
    boot0Button="$LIGHTCYAN"
    promptMsg="Confirm Pressing 'BOOT0' Turns Green LED On"
  else
    boot0LED="$DARKGRAY"
    boot0Button="$DARKGRAY"
  fi
  if [[ "Katapult" == "$2" ]]; then
    resetLED="$ORANGE"
    resetLED="$WHITE"
    promptMsg="Confirm Orange LED Flashing"
  else
    resetLED="$DARKGRAY"
  fi
  if [[ "dsensor0pin" == "$2" ]]; then
    dsLED0="$YELLOW"
    dsLED0="$WHITE"
    dsCONN0="$YELLOW"
    promptMsg="Confirm Yellow DSENSOR0 LED Lit"
  else
    dsLED0="$DARKGRAY"
    dsCONN0="$DARKGRAY"
  fi
  if [[ "dsensor1pin" == "$2" ]]; then
    dsLED1="$YELLOW"
    dsLED1="$WHITE"
    dsCONN1="$YELLOW"
    promptMsg="Confirm Yellow DSENSOR1 LED Lit"
  else
    dsLED1="$DARKGRAY"
    dsCONN1="$DARKGRAY"
  fi
  if [[ "dsensor2pin" == "$2" ]]; then
    dsLED2="$YELLOW"
    dsLED2="$WHITE"
    dsCONN2="$YELLOW"
    promptMsg="Confirm Yellow DSENSOR2 LED Lit"
  else
    dsLED2="$DARKGRAY"
    dsCONN2="$DARKGRAY"
  fi
  if [[ "dsensor3pin" == "$2" ]]; then
    dsLED3="$YELLOW"
    dsLED3="$WHITE"
    dsCONN3="$YELLOW"
    promptMsg="Confirm Yellow DSENSOR3 LED Lit"
  else
    dsLED3="$DARKGRAY"
    dsCONN3="$DARKGRAY"
  fi
  if [[ "dsensor4pin" == "$2" ]]; then
    dsLED4="$YELLOW"
    dsLED4="$WHITE"
    dsCONN4="$YELLOW"
    promptMsg="Confirm Yellow DSENSOR4 LED Lit"
  else
    dsLED4="$DARKGRAY"
    dsCONN4="$DARKGRAY"
  fi
  if [[ "heater0" == "$2" ]]; then
    heater0LED="$LIGHTRED"
    heater0LED="$WHITE"
    heater0CONN="$RED"
    promptMsg="Confirm Red HEATER0 LED Flashing"
  else
    heater0LED="$DARKGRAY"
    heater0CONN="$DARKGRAY"
  fi
  if [[ "heater1" == "$2" ]]; then
    heater1LED="$LIGHTRED"
    heater1LED="$WHITE"
    heater1CONN="$RED"
    promptMsg="Confirm Red HEATER1 LED Flashing"
  else
    heater1LED="$DARKGRAY"
    heater1CONN="$DARKGRAY"
  fi
  if [[ "fan0" == "$2" ]]; then
    fan0LED="$LIGHTBLUE"
    fan0LED="$WHITE"
    fan0CONN="$BLUE"
    promptMsg="Confirm Blue FAN0 LED and LED Strip Lit"
  else
    fan0LED="$DARKGRAY"
    fan0CONN="$DARKGRAY"
  fi
  if [[ "fan1" == "$2" ]]; then
    fan1LED="$LIGHTBLUE"
    fan1LED="$WHITE"
    fan1CONN="$BLUE"
    promptMsg="Confirm Blue FAN1 LED and LED Strip Lit"
  else
    fan1LED="$DARKGRAY"
    fan1CONN="$DARKGRAY"
  fi
  if [[ "fan2" == "$2" ]]; then
    fan2LED="$LIGHTBLUE"
    fan2LED="$WHITE"
    fan2CONN="$BLUE"
    promptMsg="Confirm Blue FAN2 LED and LED Strip Lit"
  else
    fan2LED="$DARKGRAY"
    fan2CONN="$DARKGRAY"
  fi
  if [[ "fan3" == "$2" ]]; then
    fan3LED="$LIGHTBLUE"
    fan3LED="$WHITE"
    fan3CONN="$BLUE"
    promptMsg="Confirm Blue FAN3 LED and LED Strip Lit"
  else
    fan3LED="$DARKGRAY"
    fan3CONN="$DARKGRAY"
  fi
  if [[ "BLTouch" == "$2" ]]; then
    blLED="$LIGHTBLUE"
    blLED="$WHITE"
    blCONN="$WHITE"
    promptMsg="Confirm BL Touch LED Lit"
  else
    blLED="$DARKGRAY"
    blCONN="$DARKGRAY"
  fi
  if [[ "Inductive" == "$2" ]]; then
    indLED="$LIGHTBLUE"
    indLED="$WHITE"
    indCONN="$WHITE"
    promptMsg="Confirm Inductive Sensor LED Lit"
  else
    indLED="$DARKGRAY"
    indCONN="$DARKGRAY"
  fi

  checkLEDSpace=$((${#PHULLSTRING} - (8 + 4 + 2 + 2 + ${#promptMsg})))

  echo -e "$outline$PHULLSTRING
##$highlight  TEST$testNumber: $promptMsg ${EMPTYSTRING:0:checkLEDSpace} $outline##
$PHULLSTRING
##$DARKGRAY                                                                      $outline##
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
##$DARKGRAY      -    $boot0Button BOOT0 $DARKGRAY                   __    /                  \|      $outline##
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


testNum=0


########################################################################
# Ping Test/Moved to start of tests as primary requirement
########################################################################
testNum=$((testNum + 1))
testNumString=$(makeTestNUMString "$testNum")

echoE " "
echo -e  "$outline$PHULLSTRING"
doAppend "!TEST$testNumString: Ping"
logFileImage="$logFileImage\nTEST$testNumString: Ping"

pingRESPONSE=$(ping -c 2 klipper.discourse.group)

if echo "$pingRESPONSE" | grep -q "klipper.hosted"; then
  echoE   "TEST$testNumString: Ping Test Complete"
else
  echoE " "
  drawError "TEST$testNumString: Ping" "No Response"
  logFileImage="$logFileImage\nTEST$testNumString: Ping No Response"
  exit
fi

if [[ 0 != $doHeaterCheck ]]; then
########################################################################
# Check VIN Power Available to HeaterBoard/Moved to start of tests as primary requirement
########################################################################
  testNum=$((testNum + 1))
  testNumString=$(makeTestNUMString "$testNum")

  echoE " "
  echo -e  "$outline$PHULLSTRING"
  doAppend "!TEST$testNumString: VIN Detection Test"
  logFileImage="$logFileImage\nTEST$testNumString: VIN Detection Test"

  RESPONSE=$(python ~/python/gpioread.py $fan0complo) || true

  if echo "$RESPONSE" | grep -q "Pin State is low"; then
    echoE   "TEST$testNumString: VIN Connection Test Complete"
  else
    echoE " "
    drawError "TEST$testNumString: VIN Connection" "No VIN Detected on HeaterBoard"
    logFileImage="$logFileImage\nTEST$testNumString: No VIN Detected on HeaterBoard"
    exit
  fi
########################################################################
fi


########################################################################
# Firmware Load Start
########################################################################

echoE " "
echo -e  "$outline$PHULLSTRING"
doAppend "!Firmware Load"
logFileImage="Firmware Load"

lsusbResponse=$(lsusb)

echoE " "
echoE "FLS:01"
echoE "$lsusbResponse"
echoE " "

if echo "$lsusbResponse" | grep -q "0483:df11"; then
  loadKatapult=1
else
  python ~/python/enableKatapult.py
  
  sleep 1
  
  katapultResponse=$(ls /dev/serial/by-id) || true

  echoE "FLS:02"
  echoE "$katapultResponse"
  echoE " "

  if echo "$katapultResponse" | grep -q "usb-katapult_stm32g0b1xx_"; then
    loadKatapult=0
  else
    python ~/python/enableDFU.py
  
    sleep 1
        
    lsusbResponse=$(lsusb) || true

    echoE "FLS:03"
    echoE "$lsusbResponse"
    echoE " "

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

  echoE " "
  echoE "FLS:04"
  echoE "$katapultResponse"
  echoE " "

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


if [[ 0 != $doLEDCheck ]]; then
########################################################################
# Check Power LED Lit
########################################################################
  testNum=$((testNum + 1))
  testNumString=$(makeTestNUMString "$testNum")

  echoE " "
  Yn=$(checkLED "$testNumString" "Power")

  if [[ "Y" == "$Yn" ]]; then
    echoE " "
    echoE   "TEST$testNumString: Power LED Active"
    echoE " "
  else
    echoE " "
    drawError "TEST$testNumString: Power LED Active Check" "LED Not Lit"
    logFileImage="$logFileImage\nTEST$testNumString: Power LED Active Check: LED Not Lit"
    exit
  fi

########################################################################
# Check DFU LED Lit
########################################################################
  testNum=$((testNum + 1))
  testNumString=$(makeTestNUMString "$testNum")

  echoE " "
  Yn=$(checkLED "$testNumString" "Katapult")

  if [[ "Y" == "$Yn" ]]; then
    echoE " "
    echoE   "TEST$testNumString: DFU LED Flashing"
    echoE " "
  else
    echoE " "
    drawError "TEST$testNumString: DFU LED Active Check" "LED Not Lit/Flashing"
    logFileImage="$logFileImage\nTEST$testNumString: DFU LED Active Check: LED Not Lit/Flashing"
    exit
  fi

########################################################################
# Check STATUS LED Operation and BOOT0 Button
########################################################################
  testNum=$((testNum + 1))
  testNumString=$(makeTestNUMString "$testNum")

  echoE " "
  Yn=$(checkLED "$testNumString" "BOOT0")

  if [[ "Y" == "$Yn" ]]; then
    echoE " "
    echoE   "TEST$testNumString: STATUS LED & Button Operating Normally"
    echoE " "
  else
    echoE " "
    drawError "TEST$testNumString: STATUS LED Operation Check" "LED Not Lighting when BOOT0 Button Pressed"
    logFileImage="$logFileImage\nTEST$testNumString: STATUS LED Operation Check: LED Not Lighting when BOOT0 Button Pressed"
    exit
  fi
########################################################################
else
  sleep 1 # Put in to give MCU time to reboot into Katapult
fi

  
dfuResponse=$(ls /dev/serial/by-id)

echoE " "
echoE "FLS:05"
echoE "$dfuResponse"
echoE " "

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

echoE " "
echoE "FLS:06"
echoE "$configFolder"
echoE " "

if echo "$configFolder" | grep -q "mcu.cfg"; then
  rm ~/printer_data/config/mcu.cfg
fi

canUUID=$(~/klippy-env/bin/python ~/klipper/scripts/canbus_query.py can0)

echoE "FLS:07"
echoE "$canUUID"
echoE " "

mapfile -t canUUIDArray <<< "$canUUID"

toolheadCfgUUID=$(<~/printer_data/config/toolhead.cfg)

mapfile -t toolheadCfgUUIDArray <<< "$toolheadCfgUUID"
toolheadUUID="${toolheadCfgUUIDArray[1]}"

toolheadUUID="${toolheadUUID#canbus_uuid: }"
toolheadUUID="${toolheadUUID%:0:12}"

echoE "FLS:08"
echoE "$toolheadUUID"
echoE " "

mcuUUID=""
fls=1
for arrayElement in "${canUUIDArray[@]}"; do
  if echo "$arrayElement" | grep "Found canbus_uuid="; then
    arrayElement="${arrayElement#Found canbus_uuid=}"  
    arrayElement="${arrayElement:0:12}"

    echoE "FLS:09-$fls"
    fls=$((fls+1))
    echoE "$arrayElement"
    echoE " "
    
    if [[ "$arrayElement" == "$toolheadUUID" ]]; then
      echoE "Match to Toolhead UUID"
    else
      mcuUUID="$arrayElement"
    fi
  fi
done

echoE "FLS:10"
echoE "$mcuUUID"
echoE " "

printf "[mcu]\ncanbus_uuid: $mcuUUID\n" > ~/printer_data/config/mcu.cfg



########################################################################
# Verify Klipper is Running
########################################################################

echoE " "
echo -e  "$outline$PHULLSTRING"
doAppend "!Klipper Startup"
logFileImage="$logFileImage\nKlipper Startup"

sudo service klipper start

klipperFlag=0
for ((vkr=1;10>=vkr;++vkr)); do
  if [[ 0 == $klipperFlag ]]; then
    sleep 2

    echo -ne "STATUS\n" > "$TTY" 
    RESPONSE=$(timeout 2 cat "$TTY") || true

    if echo "$RESPONSE" | grep -q "Klipper state: Ready"; then
      klipperFlag=1

      echoE " "
      echoE "VKR:$vkr"
      echoE "STATUS RESPONSE=$RESPONSE"
      echoE " "
    else
      if echo "$RESPONSE" | grep -q "Can not update MCU 'host' config as it is shutdown"; then
        sleep 2

        echo -ne "FIRMWARE_RESTART\n" > "$TTY" 
        RESTART_RESPONSE=$(timeout 2 cat "$TTY") || true

        if echo "$RESTART_RESPONSE" | grep -q "Klipper state: Ready"; then
          klipperFlag=1

          echoE " "
          echoE "VKR:$vkr"
          echoE "FIRMWARE_RESTART RESPONSE=$RESTART_RESPONSE"
          echoE " "
        else
          echoE " "
          echoE "VKR:$vkr"
          echoE "STATUS RESPONSE=$RESPONSE"
          echoE " "
          echoE "Sent FIRMWARE_RESTART"
          echoE " "
        fi
      fi
    fi
  fi
done

if [[ 0 != $klipperFlag ]]; then
  echoE "VKR:Complete"
  echoE "Klipper Running"
  echoE " "
else 
  drawError "VKR: Error.  Klipper Not Starting Up" "Contact Support"
  logFileImage="$logFileImage\nVKR: Error.  Klipper Not Starting Up"
  exit
fi



########################################################################
# Functional Tests Continue
########################################################################

#sleep 2
sleep 1

########################################################################
# VINMON
########################################################################
testNum=$((testNum + 1))
testNumString=$(makeTestNUMString "$testNum")

echo -e  "$outline$PHULLSTRING"
doAppend "!TEST$testNumString: VINMON"
logFileImage="$logFileImage\nTEST$testNumString: VINMON"

echo -ne "VINTEST\n" > "$TTY" || true

TEST_RESPONSE=$(timeout 1 cat "$TTY") || true

echoE "$TEST_RESPONSE"

if echo "$TEST_RESPONSE" | grep -q "VINTest: PASS"; then
  echoE " "
else
  drawError "TEST$testNumString: VINMON" "Invalid Voltage Read"
  logFileImage="$logFileImage\nTEST$testNumString: VINMON Invalid Voltage Read"
  exit
fi


########################################################################
# sensorvalue Initial State Check
########################################################################
testNum=$((testNum + 1))
testNumString=$(makeTestNUMString "$testNum")

echo -e  "$outline$PHULLSTRING"
doAppend "!TEST$testNumString: sensorvalue Initial State Check"
logFileImage="$logFileImage\nTEST$testNumString: Verify sensorvalue Initial State is 0"

echo -ne "GETSENSORVALUE\n" > "$TTY" || true
TEST_RESPONSE=$(timeout 1 cat "$TTY") || true
echoE "sensorvalue Initial State: $TEST_RESPONSE"

if echo "$TEST_RESPONSE" | grep -q "sensorvalue=0"; then
  echoE " "
else
  drawError "TEST$testNumString: sensorvalue Initial State Check" "sensorvalue NOT 0"
  logFileImage="$logFileImage\nTEST$testNumString: sensorvalue Initial State NOT 0"
  exit
fi



########################################################################
# MCU Temperature
########################################################################
testNum=$((testNum + 1))
testNumString=$(makeTestNUMString "$testNum")

echo -e  "$outline$PHULLSTRING"
doAppend "!TEST$testNumString: MCU Temperature"
logFileImage="$logFileImage\nTEST$testNumString: MCU Temperature"

echo -ne "MCUTEST\n" > "$TTY" || true

TEST_RESPONSE=$(timeout 1 cat "$TTY") || true

echoE "$TEST_RESPONSE"

if echo "$TEST_RESPONSE" | grep -q "MCUTest: PASS"; then
  echoE " "
else
  drawError "TEST$testNumString: MCU Temperature Test" "Invalid MCU Temperature Value Read"
  logFileImage="$logFileImage\nTEST$testNumString: Invalid MCU Temperature Value Read"
  exit
fi

if [[ 0 != $doToolheadTemperatureCheck ]]; then
########################################################################
# Toolhead Temperature
########################################################################
  testNum=$((testNum + 1))
  testNumString=$(makeTestNUMString "$testNum")

  echo -e  "$outline$PHULLSTRING"
  doAppend "!TEST$testNumString: Toolhead Temperature"
  logFileImage="$logFileImage\nTEST$testNumString: Toolhead Temperature"

  echo -ne "TOOLHEADTEST\n" > "$TTY" || true

  TEST_RESPONSE=$(timeout 1 cat "$TTY") || true

  echoE "$TEST_RESPONSE"

  if echo "$TEST_RESPONSE" | grep -q "ToolheadTest: PASS"; then
    echoE " "
  else
    drawError "TEST$testNumString: Toolhead Temperature Test" "Invalid Toolhead Temperature Value Read"
    logFileImage="$logFileImage\nTEST$testNumString: Invalid Toolhead Temperature Value Read"
    exit
  fi
########################################################################
fi

if [[ 0 != $doThermoTemperatureCheck ]]; then
########################################################################
# Loop Through Thermistor Precision Resistor "Temperature" Test
########################################################################
  ThermistorNumber=("0" "1") 
  for thermNum in "${ThermistorNumber[@]}"; do
    testNum=$((testNum + 1))
    testNumString=$(makeTestNUMString "$testNum")

    echo -e  "$outline$PHULLSTRING"
    doAppend "!TEST$testNumString: THERMO$thermNum Temperature"
    logFileImage="$logFileImage\nTEST$testNumString: THERMO$thermNum Temperature"

    echo -ne "THERMTEST VALUE=$thermNum\n" > "$TTY" || true

    TEST_RESPONSE=$(timeout 1 cat "$TTY") || true

    echoE "$TEST_RESPONSE"

    if echo "$TEST_RESPONSE" | grep -q "ThermTest: thermo$thermNum: PASS"; then
      echoE " "
    else
      if echo "$TEST_RESPONSE" | grep -q "ThermTest: Check thermo$thermNum Connection to HeaterBoard"; then
        drawError "TEST$testNumString: THERMO$thermNum Temperature Test" "Check Thermistor THERMO$thermNum Connection to Board Under Test"
        logFileImage="$logFileImage\nTEST$testNumString: Check Thermistor THERMO$thermNum Connection to Board Under Test"
        exit
      else
        drawError "TEST$testNumString: THERMO$thermNum Temperature Test" "Invalid THERMO$thermNum Thermistor Temperature Value Read"
        logFileImage="$logFileImage\nTEST$testNumString: Invalid THERMO$thermNum Thermistor Temperature Value Read"
        exit
      fi
    fi
  done
########################################################################
fi


if [[ 0 != $doDSensorCheck ]]; then
########################################################################
# Loop Through Check DSENSOR# Operation
########################################################################
  dSensorPins=("dsensor0pin" "dsensor1pin" "dsensor2pin" "dsensor3pin" "dsensor4pin") 
  expectedPin=1
  expectedValue=1
  for dSensorpin in "${dSensorPins[@]}"; do
    testNum=$((testNum + 1))
    testNumString=$(makeTestNUMString "$testNum")

    echo -e  "$outline$PHULLSTRING"
    doAppend "!TEST$testNumString: Check $dSensorpin Operation"
    logFileImage="$logFileImage\nTEST$testNumString: Check $dSensorpin Operation"

    echo -ne "SETDEMUX VALUE=$expectedPin\n" > "$TTY" || true
    sleep 0.5
    echo -ne "GETSENSORVALUE\n" > "$TTY" || true
    TEST_RESPONSE=$(timeout 1 cat "$TTY") || true
    echoE "$dSensorPin Set State: $TEST_RESPONSE"
    
    if echo "$TEST_RESPONSE" | grep -q "sensorvalue=$expectedValue"; then
      if [[ 0 != $doLEDCheck ]]; then
        echoE " "
        Yn=$(checkLED "$testNumString" "$dSensorpin")
      else
        Yn="Y"
      fi

      if [[ "Y" == "$Yn" ]]; then
        echoE " "
        echoE   "TEST$testNumString: $dSensorpin LED Active"
        echoE " "

        echo -ne "SETDEMUX VALUE=0\n" > "$TTY" || true
        sleep 0.5
        echo -ne "GETSENSORVALUE\n" > "$TTY" || true
        TEST_RESPONSE=$(timeout 1 cat "$TTY") || true
        echoE "$dSensorPin Reset State: $TEST_RESPONSE"
          
        if echo "$TEST_RESPONSE" | grep -q "sensorvalue=0"; then
          echoE " "
        else
          echoE " "
          drawError "TEST$testNumString: $dSensorpin Not Reset" "$dSensorpin Not Reset"
          logFileImage="$logFileImage\nTEST$testNumString: $dSensorpin Test: Not Reset"
          exit
        fi
      else
        echoE " "
        echo -ne "SETDEMUX VALUE=0\n" > "$TTY" || true
        drawError "TEST$testNumString: $dSensorpin LED Active Check" "LED Not Lit"
        logFileImage="$logFileImage\nTEST$testNumString: $dSensorpin LED Active Check: LED Not Lit"
        exit
      fi
    else
      echoE " "
      echo -ne "SETDEMUX VALUE=0\n" > "$TTY" || true
      drawError "TEST$testNumString: $dSensorpin Set Check" "$dSensorpin NOT Set"
      logFileImage="$logFileImage\nTEST$testNumString: $dSensorpin Set Check: $dSensorpin NOT Set"
      exit
    fi

    expectedPin=$((expectedPin + 1))
    expectedValue=$((expectedValue * 2))
  
  done
########################################################################
fi


if [[ 0 != $doIndStopCheck ]]; then
########################################################################
# Check the Inductive Endstop Sensor Hardware
########################################################################
  testNum=$((testNum + 1))
  testNumString=$(makeTestNUMString "$testNum")

  echo -e  "$outline$PHULLSTRING"
  doAppend "!TEST$testNumString: Check Inductive Sensor Operation"
  logFileImage="$logFileImage\nTEST$testNumString: Check Inductive Sensor Operation"

  echo -ne "SETDEMUX VALUE=6\n" > "$TTY" || true
  sleep 0.5
  echo -ne "GETSENSORVALUE\n" > "$TTY" || true
  TEST_RESPONSE=$(timeout 1 cat "$TTY") || true
  echoE "Inductive Sensor Set State: $TEST_RESPONSE"
    
  if echo "$TEST_RESPONSE" | grep -q "sensorvalue=32"; then
    if [[ 0 != $doLEDCheck ]]; then
      echoE " "
      Yn=$(checkLED "$testNumString" "Inductive")
    else
      Yn="Y"
    fi

    if [[ "Y" == "$Yn" ]]; then
      echoE " "
      echoE   "TEST$testNumString: Inductive Sensor LED Active"
      echoE " "
      echo -ne "SETDEMUX VALUE=0\n" > "$TTY" || true
      sleep 0.5
          
      echo -ne "GETSENSORVALUE\n" > "$TTY" || true
      TEST_RESPONSE=$(timeout 1 cat "$TTY") || true
      echoE "Inductive Sensor Reset State: $TEST_RESPONSE"
          
      if echo "$TEST_RESPONSE" | grep -q "sensorvalue=0"; then
        echoE " "
      else
        echoE " "
        drawError "TEST$testNumString: Inductive Sensor Not Reset" "Inductive Sensor Not Reset"
        logFileImage="$logFileImage\nTEST$testNumString: Inductive Sensor Test: Not Reset"
        exit
      fi
    else
      echoE " "
      echo -ne "SETDEMUX VALUE=0\n" > "$TTY" || true
      drawError "TEST$testNumString: Inductive Sensor LED Active Check" "LED Not Lit"
      logFileImage="$logFileImage\nTEST$testNumString: Inductive Sensor LED Active Check: LED Not Lit"
      exit
    fi
  else
    echoE " "
    echo -ne "SETDEMUX VALUE=0\n" > "$TTY" || true
    drawError "TEST$testNumString: Inductive Sensor Set Check" "Inductive Sensor NOT Set"
    logFileImage="$logFileImage\nTEST$testNumString: Inductive Sensor Set Check: Inductive Sensor NOT Set"
    exit
  fi
########################################################################
fi


if [[ 0 != $doBLTouchCheck ]]; then
########################################################################
# Check the BLTouch Servo
########################################################################
  testNum=$((testNum + 1))
  testNumString=$(makeTestNUMString "$testNum")

  echo -e  "$outline$PHULLSTRING"
  doAppend "!TEST$testNumString: Check BLTouch Servo Operation"
  logFileImage="$logFileImage\nTEST$testNumString: Check BLTouch Servo Operation"

  echo -ne "SETBLSERVO VALUE=1\n" > "$TTY" || true
  sleep 0.5
  echo -ne "GETSENSORVALUE\n" > "$TTY" || true
  TEST_RESPONSE=$(timeout 1 cat "$TTY") || true
  echoE "BLTouch Servo Set State: $TEST_RESPONSE"
    
  if echo "$TEST_RESPONSE" | grep -q "sensorvalue=512"; then
    echo -ne "SETBLSERVO VALUE=0\n" > "$TTY" || true
    sleep 0.5
    echo -ne "GETSENSORVALUE\n" > "$TTY" || true
    TEST_RESPONSE=$(timeout 1 cat "$TTY") || true
    echoE "BLTouch Servo Reset State: $TEST_RESPONSE"
          
    if echo "$TEST_RESPONSE" | grep -q "sensorvalue=0"; then
      echoE " "
    else
      echoE " "
      drawError "TEST$testNumString: BLTouch Servo Not Reset" "BLTouch Servo Not Reset"
      logFileImage="$logFileImage\nTEST$testNumString: BLTouch Servo Test: Not Reset"
      exit
    fi
  else
    echoE " "
    echo -ne "SETDEMUX VALUE=0\n" > "$TTY" || true
    drawError "TEST$testNumString: Inductive Sensor Set Check" "Inductive Sensor NOT Set"
    logFileImage="$logFileImage\nTEST$testNumString: Inductive Sensor Set Check: Inductive Sensor NOT Set"
    exit
  fi
########################################################################
# Check the BLTouch Probe
########################################################################
  testNum=$((testNum + 1))
  testNumString=$(makeTestNUMString "$testNum")

  echo -e  "$outline$PHULLSTRING"
  doAppend "!TEST$testNumString: Check BLTouch Probe Operation"
  logFileImage="$logFileImage\nTEST$testNumString: Check BLTouch Probe Operation"

  echo -ne "SETBLPROBE VALUE=1\n" > "$TTY" || true
  sleep 0.5
  echo -ne "GETSENSORVALUE\n" > "$TTY" || true
  TEST_RESPONSE=$(timeout 1 cat "$TTY") || true
  echoE "BLTouch Probe Set State: $TEST_RESPONSE"
    
  if echo "$TEST_RESPONSE" | grep -q "sensorvalue=256"; then
    if [[ 0 != $doLEDCheck ]]; then
      echoE " "
      Yn=$(checkLED "$testNumString" "BLTouch")
    else
      Yn="Y"
    fi

    if [[ "Y" == "$Yn" ]]; then
      echoE " "
      echoE   "TEST$testNumString: BLTouch Probe LED Active"
      echoE " "

      echo -ne "SETBLPROBE VALUE=0\n" > "$TTY" || true
      sleep 0.5
          
      echo -ne "GETSENSORVALUE\n" > "$TTY" || true
      TEST_RESPONSE=$(timeout 1 cat "$TTY") || true
      echoE "BLTouch Probe Reset State: $TEST_RESPONSE"
          
      if echo "$TEST_RESPONSE" | grep -q "sensorvalue=0"; then
        echoE " "
      else
        echoE " "
        drawError "TEST$testNumString: BLTouch Probe Not Reset" "BLTouch Probe Not Reset"
        logFileImage="$logFileImage\nTEST$testNumString: BLTouch Probe Test: Not Reset"
        exit
      fi
    else
      echoE " "
      echo -ne "SETDEMUX VALUE=0\n" > "$TTY" || true
      drawError "TEST$testNumString: BLTouch Probe LED Active Check" "LED Not Lit"
      logFileImage="$logFileImage\nTEST$testNumString: BLTouch Probe LED Active Check: LED Not Lit"
      exit
    fi
  else
    echoE " "
    echo -ne "SETDEMUX VALUE=0\n" > "$TTY" || true
    drawError "TEST$testNumString: BLTouch Probe Set Check" "BLTouch Probe NOT Set"
    logFileImage="$logFileImage\nTEST$testNumString: BLTouch Probe Set Check: BLTouch Probe NOT Set"
    exit
  fi
########################################################################
fi


if [[ 0 != $doSPICheck ]]; then
########################################################################
# Check the SPI CS/MOSI OR Gate
########################################################################
  testNum=$((testNum + 1))
  testNumString=$(makeTestNUMString "$testNum")

  echo -e  "$outline$PHULLSTRING"
  doAppend "!TEST$testNumString: Check SPI CS/MOSI OR Gate Operation"
  logFileImage="$logFileImage\nTEST$testNumString: Check SPI CS/MOSI OR Gate Operation"

  for spi in {3..1}; do
    echo -ne "SETSPICSMOSI VALUE=$spi\n" > "$TTY" || true
    sleep 0.5
    echo -ne "GETSENSORVALUE\n" > "$TTY" || true
    TEST_RESPONSE=$(timeout 1 cat "$TTY") || true
    echoE "SPI CS/MOSI OR Gate Set $spi: $TEST_RESPONSE"
    
    if echo "$TEST_RESPONSE" | grep -q "sensorvalue=1024"; then
      echoE " "
    else
      echoE " "
      echo -ne "SETSPICSMOSI VALUE=0\n" > "$TTY" || true
      drawError "TEST$testNumString: SPI CS/MOSI OR Gate Set $spi Check" "SPI CS/MOSI OR Gate NOT Set"
      logFileImage="$logFileImage\nTEST$testNumString: SPI CS/MOSI OR Gate Set $spi Check: SPI CS/MOSI OR Gate NOT Set"
      exit
    fi
  done

  echo -ne "SETSPICSMOSI VALUE=0\n" > "$TTY" || true
  sleep 0.5
  echo -ne "GETSENSORVALUE\n" > "$TTY" || true
  TEST_RESPONSE=$(timeout 1 cat "$TTY") || true
  echoE "SPI CS/MOSI OR Gate Set 0: $TEST_RESPONSE"
    
  if echo "$TEST_RESPONSE" | grep -q "sensorvalue=0"; then
    echoE " "
  else
    echoE " "
    drawError "TEST$testNumString: SPI CS/MOSI OR Gate Not Reset" "SPI CS/MOSI OR Gate Not Reset"
    logFileImage="$logFileImage\nTEST$testNumString: SPI CS/MOSI OR Gate Test: Not Reset"
    exit
  fi
########################################################################
fi


if [[ 0 != $doHeaterCheck ]]; then
########################################################################
# Loop Through heater# Check Operation
########################################################################
  htrcomplo=( $htr0complo $htr1complo )
  htrcomphi=( $htr0comphi $htr1comphi )

  for htr in {0..1}; do
    testNum=$((testNum + 1))
    testNumString=$(makeTestNUMString "$testNum")

    echo -e  "$outline$PHULLSTRING"
    doAppend "!TEST$testNumString: Test Heater$htr Driver Operation"
    logFileImage="$logFileImage\nTEST$testNumString: Test Heater$htr Driver Operation"

    RESPONSE_LO=$(python ~/python/gpioread.py ${htrcomplo[$htr]}) || true
    RESPONSE_HI=$(python ~/python/gpioread.py ${htrcomphi[$htr]}) || true

    if echo "$RESPONSE_LO" | grep -q "Pin State is low"; then
      if echo "$RESPONSE_HI" | grep -q "Pin State is HIGH"; then
        echoE " "
        echo -ne "SETHEATER NUMBER=$htr VALUE=1\n" > "$TTY" || true  
        sleep 0.5
        RESPONSE_LO=$(python ~/python/gpioread.py ${htrcomplo[$htr]}) || true
        RESPONSE_HI=$(python ~/python/gpioread.py ${htrcomphi[$htr]}) || true

        if [[ 0 != $doLEDCheck ]]; then
          echoE " "
          Yn=$(checkLED "$testNumString" "heater$htr")
        else
          Yn="Y"
        fi

        echo -ne "SETHEATER NUMBER=$htr VALUE=0\n" > "$TTY" || true
        sleep 0.5

        if [[ "Y" == "$Yn" ]]; then
          echoE " "
          echoE "TEST$testNumString: Heater$htr Probe LED Active"
          echoE " "

          if echo "$RESPONSE_LO" | grep -q "Pin State is HIGH"; then
            if echo "$RESPONSE_HI" | grep -q "Pin State is HIGH"; then
              echoE " "
              RESPONSE_LO=$(python ~/python/gpioread.py ${htrcomplo[$htr]}) || true
              RESPONSE_HI=$(python ~/python/gpioread.py ${htrcomphi[$htr]}) || true

              if echo "$RESPONSE_LO" | grep -q "Pin State is low"; then
                if echo "$RESPONSE_HI" | grep -q "Pin State is HIGH"; then
                  echoE " "
                else
                  echoE " "
                  drawError "TEST$testNumString: Heater$htr High Comparator Reset Output Test" "Heater$htr High Comparator NOT in Correct Reset State"
                  logFileImage="$logFileImage\nTEST$testNumString: Heater$htr High Comparator NOT in Correct Reset State"
                  exit
                fi    
              else
                echoE " "
                drawError "TEST$testNumString: Heater$htr Low Comparator Reset Output Test" "Heater$htr Low Comparator NOT in Correct Reset State"
                logFileImage="$logFileImage\nTEST$testNumString: Heater$htr Low Comparator NOT in Correct Reset State"
                exit
              fi    

            else
              echoE " "
              drawError "TEST$testNumString: Heater$htr High Comparator Set Output Test" "Heater$htr High Comparator NOT in Correct Set State"
              logFileImage="$logFileImage\nTEST$testNumString: Heater$htr High Comparator NOT in Correct Set State"
              exit
            fi    
          else
            echoE " "
            drawError "TEST$testNumString: Heater$htr Low Comparator Set Output Test" "Heater$htr Low Comparator NOT in Correct Set State"
            logFileImage="$logFileImage\nTEST$testNumString: Heater$htr Low Comparator NOT in Correct Set State"
            exit
          fi    

        else
          echoE " "
          drawError "TEST$testNumString: Heater$htr LED Active Check" "LED Not Lit"
          logFileImage="$logFileImage\nTEST$testNumString: Heater$htr LED Active Check: LED Not Lit"
          exit
        fi

      else
        echoE " "
        drawError "TEST$testNumString: Heater$htr High Comparator Initial Output Test" "Heater$htr High Comparator NOT in Correct Initial State"
        logFileImage="$logFileImage\nTEST$testNumString: Heater$htr High Comparator NOT in Correct Initial State"
        exit
      fi    
    else
      echoE " "
      drawError "TEST$testNumString: Heater$htr Low Comparator Initial Output Test" "Heater$htr Low Comparator NOT in Correct Initial State"
      logFileImage="$logFileImage\nTEST$testNumString: Heater$htr Low Comparator NOT in Correct Initial State"
      exit
    fi    
  done
########################################################################
fi



if [[ 0 != $doFanCheck ]] && [[ 0 != $doHeaterCheck ]]; then
########################################################################
# Loop Through Check FAN# Operation
########################################################################
  fancomplo=( $fan0complo $fan1complo $fan2complo $fan3complo )
  fancomphi=( $fan0comphi $fan1comphi $fan2comphi $fan3comphi )

  for fan in {0..3}; do
    testNum=$((testNum + 1))
    testNumString=$(makeTestNUMString "$testNum")

    echo -e  "$outline$PHULLSTRING"
    doAppend "!TEST$testNumString: Test Fan$fan Driver Operation"
    logFileImage="$logFileImage\nTEST$testNumString: Test Fan$fan Driver Operation"

    RESPONSE_LO=$(python ~/python/gpioread.py ${fancomplo[$fan]}) || true
    RESPONSE_HI=$(python ~/python/gpioread.py ${fancomphi[$fan]}) || true
    
    echo -e "LO: fan=$fan,  pin=${fancomplo[$fan]},  RESPONSE_LO=$RESPONSE_LO"
    echo -e "HI: fan=$fan,  pin=${fancomphi[$fan]},  RESPONSE_HI=$RESPONSE_HI"

    if echo "$RESPONSE_LO" | grep -q "Pin State is low"; then
      if echo "$RESPONSE_HI" | grep -q "Pin State is HIGH"; then
        echoE " "
        echo -ne "SETFAN NUMBER=$fan VALUE=1\n" > "$TTY" || true  
        sleep 0.5
        RESPONSE_LO=$(python ~/python/gpioread.py ${fancomplo[$fan]}) || true
        RESPONSE_HI=$(python ~/python/gpioread.py ${fancomphi[$fan]}) || true

        if [[ 0 != $doLEDCheck ]]; then
          echoE " "
          Yn=$(checkLED "$testNumString" "fan$fan")
        else
          Yn="Y"
        fi

        echo -ne "SETFAN NUMBER=$fan VALUE=0\n" > "$TTY" || true
        sleep 0.5

        if [[ "Y" == "$Yn" ]]; then
          echoE " "
          echoE "TEST$testNumString: Fan$fan Probe LED Active"
          echoE " "

          if echo "$RESPONSE_LO" | grep -q "Pin State is HIGH"; then
            if echo "$RESPONSE_HI" | grep -q "Pin State is HIGH"; then
              echoE " "
              RESPONSE_LO=$(python ~/python/gpioread.py ${fancomplo[$fan]}) || true
              RESPONSE_HI=$(python ~/python/gpioread.py ${fancomphi[$fan]}) || true

              if echo "$RESPONSE_LO" | grep -q "Pin State is low"; then
                if echo "$RESPONSE_HI" | grep -q "Pin State is HIGH"; then
                  echoE " "
                else
                  echoE " "
                  drawError "TEST$testNumString: Fan$fan High Comparator Reset Output Test" "Fan$fan High Comparator NOT in Correct Reset State"
                  logFileImage="$logFileImage\nTEST$testNumString: Fan$fan High Comparator NOT in Correct Reset State"
                  exit
                fi    
              else
                echoE " "
                drawError "TEST$testNumString: Fan$fan Low Comparator Reset Output Test" "Fan$fan Low Comparator NOT in Correct Reset State"
                logFileImage="$logFileImage\nTEST$testNumString: Fan$fan Low Comparator NOT in Correct Reset State"
                exit
              fi    

            else
              echoE " "
              drawError "TEST$testNumString: Fan$fan High Comparator Set Output Test" "Fan$fan High Comparator NOT in Correct Set State"
              logFileImage="$logFileImage\nTEST$testNumString: Fan$fan High Comparator NOT in Correct Set State"
              exit
            fi    
          else
            echoE " "
            drawError "TEST$testNumString: Fan$fan Low Comparator Set Output Test" "Fan$fan Low Comparator NOT in Correct Set State"
            logFileImage="$logFileImage\nTEST$testNumString: Fan$fan Low Comparator NOT in Correct Set State"
            exit
          fi    

        else
          echoE " "
          drawError "TEST$testNumString: Fan$fan LED Active Check" "LED Not Lit"
          logFileImage="$logFileImage\nTEST$testNumString: Fan$fan LED Active Check: LED Not Lit"
          exit
        fi

      else
        echoE " "
        drawError "TEST$testNumString: Fan$fan High Comparator Initial Output Test" "Fan$fan High Comparator NOT in Correct Initial State"
        logFileImage="$logFileImage\nTEST$testNumString: Fan$fan High Comparator NOT in Correct Initial State"
        exit
      fi    
    else
      echoE " "
      drawError "TEST$testNumString: Fan$fan Low Comparator Initial Output Test" "Fan$fan Low Comparator NOT in Correct Initial State"
      logFileImage="$logFileImage\nTEST$testNumString: Fan$fan Low Comparator NOT in Correct Initial State"
      exit
    fi    
  done  
########################################################################
fi












########################################################################
## Tests Complete
########################################################################


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
  echoE " "

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
    echoE " "
    drawError "Software Sealing" "Unable to Start Katapult"
    logFileImage="$logFileImage\nSoftware Sealing" "Unable to Start Katapult"
  fi
else
  echoE " "
  drawPASS   
fi

echo -e "$logFileImage" > ~/logs/$logFileName


exit
