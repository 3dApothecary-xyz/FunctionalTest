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
  ver="0.12" # Added Stepper Test
             # Added Flag to disable FirmwareLoad as part of Test Process
             #  This is to speed up testing different test steps 
             #  AND allow parameters set to be kept active during test
             # Cleaned up drawError Method Operation/Added Error to Log/Saved Log/Exit script
             # Removed any "Notes" for the test
  ver="0.13" # In Clean Up, "sudo service klipper start" was inadvetently deleted
  ver="0.14" # Added NeoPixel Test
  ver="0.15" # Added Product/Version Testing
             # Created readDlay Variable for:
             # - Product check
             # - Version Check
             # - VINMON Check
             # - sensorvalue Init Check
             # - MCU Temperature Read
             # - Toolhead Temperature read
             # - DSensor Test
             # - NeoPixel Test
             # Added Check for Klipper Running if Klippler Firmware is not loaded
             # Updated "FLS:" Numbering to better watch Flash Update Operations
             # Updated Firmware Load and eliminted the "enableDFU.py" operations
  ver="0.16" # Going through changes for HeaterBoardb
             # Changed Polarity of fan0complo in VIN Test
             # Changed Polarity of htr#complo/htr#compi/fan#complo/fan#comphi in Functional Tests
  ver="0.17" # Removed Commented Out Test Code
             # Put Ping Host and Response to Variables rather than hardcoded
             # Verified that Heater/Fan/DSensor/etc. are turned off if there is an (LED) error
             # Added Timeout value for LEDCheck methods
             # - Timeout is 20s for heaters and fans
             # - Timeout is 12 hours for all other checks
  echo "$ver"
}

# Written by: myke predko
# mykepredko@3dapothecary.xyz
# (C) Copyright 2025 for File Contents and Data Formatting

# Test Enable/Operation Variables 
doLEDCheck=1                        # Setting to Zero Disables the Manual LED Check
doFirmwareLoad=1
doToolheadTemperatureCheck=1
doThermoTemperatureCheck=1
doDSensorCheck=1
doNeoPixelCheck=1
doIndStopCheck=1
doBLTouchCheck=1
doSPICheck=1
doHeaterCheck=1                     # Setting to Zero Also Disables the VIN Check & Fan Check
doFanCheck=1
doStepperCheck=1
sealingFlag=0
readDlay=0.4
pingHost="klipper.discourse.group"
pingHostResponse="klipper.hosted"



# Raspberry Pi 40 Pin Header Pin Function Table
#
#--------------+-------------+-------------+-------------------------------------------------|
# Function     | Pin Number  | GPIO Number | Comment                                         |
#--------------+-------------+-------------+-------------------------------------------------|
# +3V3 Power   |  1          | N/A         |                                                 |
# +5V Power    |  2          | N/A         |                                                 |
neopixel0=3    #  3          | GPIO2       |                                                 |
# +5V Power    |  4          | N/A         |                                                 |
neopixel1=5    #  5          | GPIO3       |                                                 |
# GND          |  6          | N/A         |                                                 |
BOOT0=7        #  7          | GPIO4       |                                                 |
# UART0 TX     |  8          | N/A         |                                                 |
# GND          |  9          | N/A         |                                                 |
# UART0 RX     | 10          | N/A         |                                                 |
RESET=11       # 11          | GPIO17      |                                                 |
ssrcomphi=12   # 12          | GPIO18      |                                                 |
htr0complo=13  # 13          | GPIO27      |                                                 |
# GND          | 14          | N/A         |                                                 |
fan0comphi=15  # 15          | GPIO22      |                                                 |
htr0comphi=16  # 16          | GPIO23      |                                                 |
# +3V3 Power   | 17          | N/A         |                                                 |
fan0complo=18  # 18          | GPIO24      | VIN to HeaterBoard Provided using this pin      |
fan1comphi=19  # 19          | GPIO10      |                                                 |
# GND          | 20          | N/A         |                                                 |
DEMUX_C=21     # 21          | GPIO9       |                                                 |
fan2complo=22  # 22          | GPIO25      |                                                 |
DEMUX_B=23     # 23          | GPIO11      |                                                 |
htr1complo=24  # 24          | GPIO8       |                                                 |
# GND          | 25          | N/A         |                                                 |
DEMUX_A=26     # 26          | GPIO7       |                                                 |
# RESERVED     | 27          | N/A         |                                                 |
# RESERVED     | 28          | N/A         |                                                 |
htr1comphi=29  # 29          | GPIO5       |                                                 |
# GND          | 30          | N/A         |                                                 |
fan1complo=31  # 31          | GPIO6       |                                                 |
ssrcomplo=32   # 32          | GPIO12      |                                                 |
fan2comphi=33  # 33          | GPIO13      |                                                 |
# GND          | 34          | N/A         |                                                 |
blprobe=35     # 35          | GPIO19      |                                                 |
fan3complo=36  # 36          | GPIO16      |                                                 |
adxlmosi=37    # 37          | GPIO26      |                                                 |
blservo=38     # 38          | GPIO20      |                                                 |
# GND          | 39          | N/A         |                                                 |
fan3comphi=40  # 40          | GPI021      |                                                 |
#--------------+-------------+-------------+-------------------------------------------------|


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

  logFileImage="$logFileImage\n$errorHeaderMessage-$errorString"

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

  echo -e "$logFileImage" > ~/logs/$logFileName
  
  exit
}
checkLED() {

  testNumber="$1"
  promptMsg=""
  timeoutValue=43200  # 12 Hours
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
    timeoutValue=20
  else
    heater0LED="$DARKGRAY"
    heater0CONN="$DARKGRAY"
  fi
  if [[ "heater1" == "$2" ]]; then
    heater1LED="$LIGHTRED"
    heater1LED="$WHITE"
    heater1CONN="$RED"
    promptMsg="Confirm Red HEATER1 LED Flashing"
    timeoutValue=20
  else
    heater1LED="$DARKGRAY"
    heater1CONN="$DARKGRAY"
  fi
  if [[ "fan0" == "$2" ]]; then
    fan0LED="$LIGHTBLUE"
    fan0LED="$WHITE"
    fan0CONN="$BLUE"
    promptMsg="Confirm Blue FAN0 LED and LED Strip Lit"
    timeoutValue=20
  else
    fan0LED="$DARKGRAY"
    fan0CONN="$DARKGRAY"
  fi
  if [[ "fan1" == "$2" ]]; then
    fan1LED="$LIGHTBLUE"
    fan1LED="$WHITE"
    fan1CONN="$BLUE"
    promptMsg="Confirm Blue FAN1 LED and LED Strip Lit"
    timeoutValue=20
  else
    fan1LED="$DARKGRAY"
    fan1CONN="$DARKGRAY"
  fi
  if [[ "fan2" == "$2" ]]; then
    fan2LED="$LIGHTBLUE"
    fan2LED="$WHITE"
    fan2CONN="$BLUE"
    promptMsg="Confirm Blue FAN2 LED and LED Strip Lit"
    timeoutValue=20
  else
    fan2LED="$DARKGRAY"
    fan2CONN="$DARKGRAY"
  fi
  if [[ "fan3" == "$2" ]]; then
    fan3LED="$LIGHTBLUE"
    fan3LED="$WHITE"
    fan3CONN="$BLUE"
    promptMsg="Confirm Blue FAN3 LED and LED Strip Lit"
    timeoutValue=20
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
  breakValue="1"
  while [[ "1" == "$breakValue" ]]; do
    read -rsn1 -t $timeoutValue character
    readResponse=$?

    if [ $readResponse -ne 0 ]; then # Timeout
      response="T"
      breakValue="0"
    fi

    if [[ "$character" == $'\x08' || "$character" == $'\x7f' ]]; then
      if [[ -n "$response" ]]; then
        response=""
        echo -e -n "\b \b" >&2
      fi
    elif [[ "$character" == "" && -n "$response" ]]; then # Enter key
      breakValue="0"
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

  stty "$stty_original"  # Restore original terminal settings

  echo "$response"
  
}




########################################################################
# Mainline Code Start/Setup Log File Name
########################################################################

if [[ 0 != $doFirmwareLoad ]]; then
  sudo service klipper stop
fi

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

pingRESPONSE=$(ping -c 2 $pingHost)

if echo "$pingRESPONSE" | grep -q "$pingHostResponse"; then
  echoE   "TEST$testNumString: Ping Test Complete"
else
  echoE " "
  drawError "TEST$testNumString: Ping" "No Response"
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

  if echo "$RESPONSE" | grep -q "Pin State is HIGH"; then # Test Polarity Reversed for ver="0.16"
    echoE   "TEST$testNumString: VIN Connection Test Complete"
  else
    echoE " "
    drawError "TEST$testNumString: VIN Connection" "No VIN Detected on HeaterBoard"
  fi
########################################################################
fi


if [[ 0 != $doFirmwareLoad ]]; then
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
    DFU_response=$(sudo dfu-util -a 0 -D ~/bin/katapult.bin --dfuse-address 0x08000000:force:mass-erase:leave -d 0483:df11) || true  

    echoE " "                                                                                                                        
    echoE "FLS:02"                                                                                                                   
    echoE "$DFU_response"                                                                                                            
  
    sleep 1

  fi

    
  python ~/python/enableKatapult.py
  
  sleep 1
  
  katapultResponse=$(ls /dev/serial/by-id) || true

  echoE " "
  echoE "FLS:03"
  echoE "$katapultResponse"
  echoE " "

  if [! echo "$katapultResponse" | grep -q "usb-katapult_stm32g0b1xx_" ]; then
    drawError "Loading Firmware" "Error with Katapult Loading"
  fi

  python3 ~/katapult/scripts/flashtool.py -f ~/bin/KGP_4x2209_DFU.bin -d /dev/serial/by-id/$katapultResponse

  sleep 1
    
  python ~/python/enableKatapult.py
########################################################################
fi


if [[ 0 != $doLEDCheck ]]; then
########################################################################
# Check Power LED Lit
########################################################################
  testNum=$((testNum + 1))
  testNumString=$(makeTestNUMString "$testNum")

  echoE " "
  Yn=$(checkLED "$testNumString" "Power")

  if [[ "T" == "$Yn" ]]; then
    echoE " "
    drawError "TEST$testNumString: Power LED Active Check" "Input Timeout"
  elif [[ "Y" == "$Yn" ]]; then
    echoE " "
    echoE   "TEST$testNumString: Power LED Active"
    echoE " "
  else
    echoE " "
    drawError "TEST$testNumString: Power LED Active Check" "LED Not Lit"
  fi

########################################################################
# Check DFU LED Lit
########################################################################
  testNum=$((testNum + 1))
  testNumString=$(makeTestNUMString "$testNum")

  echoE " "
  Yn=$(checkLED "$testNumString" "Katapult")

  if [[ "T" == "$Yn" ]]; then
    echoE " "
    drawError "TEST$testNumString: DFU LED Flashing" "Input Timeout"
  elif [[ "Y" == "$Yn" ]]; then
    echoE " "
    echoE   "TEST$testNumString: "
    echoE " "
  else
    echoE " "
    drawError "TEST$testNumString: DFU LED Active Check" "LED Not Lit/Flashing"
  fi

########################################################################
# Check STATUS LED Operation and BOOT0 Button
########################################################################
  testNum=$((testNum + 1))
  testNumString=$(makeTestNUMString "$testNum")

  echoE " "
  Yn=$(checkLED "$testNumString" "BOOT0")

  if [[ "T" == "$Yn" ]]; then
    echoE " "
    drawError "TEST$testNumString: STATUS LED Operation Check" "Input Timeout"
  elif [[ "Y" == "$Yn" ]]; then
    echoE " "
    echoE   "TEST$testNumString: STATUS LED & Button Operating Normally"
    echoE " "
  else
    echoE " "
    drawError "TEST$testNumString: STATUS LED Operation Check" "LED Not Lighting when BOOT0 Button Pressed"
  fi
########################################################################
else
  sleep 1 # Put in to give MCU time to reboot into Katapult
fi

  
if [[ 0 != $doFirmwareLoad ]]; then
########################################################################
# If Katapult is Active, Load Klipper & Setup mcu.cfg 
########################################################################
  dfuResponse=$(ls /dev/serial/by-id)

  echoE " "
  echoE "FLS:04"
  echoE "$dfuResponse"
  echoE " "

  if [! echo "$dfuResponse" | grep -q "usb-katapult_stm32g0b1xx_" ]; then
    drawError "Loading Firmware" "Unable to Restart Katapult after KGP_4x2209_DFU.bin Load"
  fi

  python3 ~/katapult/scripts/flashtool.py -f ~/bin/klipper.bin -d /dev/serial/by-id/$katapultResponse

  sleep 1

  configFolder=$(ls ~/printer_data/config)

  echoE " "
  echoE "FLS:05"
  echoE "$configFolder"
  echoE " "

  if echo "$configFolder" | grep -q "mcu.cfg"; then
    rm ~/printer_data/config/mcu.cfg
  fi

  canUUID=$(~/klippy-env/bin/python ~/klipper/scripts/canbus_query.py can0)

  echoE "FLS:06"
  echoE "$canUUID"
  echoE " "

  mapfile -t canUUIDArray <<< "$canUUID"

  toolheadCfgUUID=$(<~/printer_data/config/toolhead.cfg)

  mapfile -t toolheadCfgUUIDArray <<< "$toolheadCfgUUID"
  toolheadUUID="${toolheadCfgUUIDArray[1]}"

  toolheadUUID="${toolheadUUID#canbus_uuid: }"
  toolheadUUID="${toolheadUUID%:0:12}"

  echoE "FLS:07"
  echoE "$toolheadUUID"
  echoE " "

  mcuUUID=""
  fls=1
  for arrayElement in "${canUUIDArray[@]}"; do
    if echo "$arrayElement" | grep "Found canbus_uuid="; then
      arrayElement="${arrayElement#Found canbus_uuid=}"  
      arrayElement="${arrayElement:0:12}"

      echoE "FLS:08-$fls"
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

  echoE "FLS:09"
  echoE "$mcuUUID"
  echoE " "

  printf "[mcu]\ncanbus_uuid: $mcuUUID\n" > ~/printer_data/config/mcu.cfg

  sudo service klipper start

########################################################################
# Wait for Klipper to start running
########################################################################
  echoE " "
  echo -e  "$outline$PHULLSTRING"
  doAppend "!Klipper Startup"
  logFileImage="$logFileImage\nKlipper Startup"

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
  fi
########################################################################
else
########################################################################
# No Firmware Load: Check that Klipper is running
########################################################################
  sleep 2

  echo -ne "STATUS\n" > "$TTY" 
  RESPONSE=$(timeout 2 cat "$TTY") || true

  if echo "$RESPONSE" | grep -q "Klipper state: Ready"; then
    echoE "STATUS RESPONSE=$RESPONSE"
    echoE " "
  else
    drawError "VKR: Error.  Klipper Not Running" "Contact Support"
  fi
fi



########################################################################
# Functional Tests Continue
########################################################################

sleep 1

########################################################################
# Check Product Type
########################################################################
testNum=$((testNum + 1))
testNumString=$(makeTestNUMString "$testNum")

echo -e  "$outline$PHULLSTRING"
doAppend "!TEST$testNumString: Product Type Check"
logFileImage="$logFileImage\nTEST$testNumString: Product Type Check"

echo -ne "RETURNPRODUCT\n" > "$TTY" || true

TEST_RESPONSE=$(timeout $readDlay cat "$TTY") || true

echoE "$TEST_RESPONSE"

if echo "$TEST_RESPONSE" | grep -q "Product: KGP 4x2209"; then
  echoE " "
else
  drawError "TEST$testNumString: Product Type Check" "Invalid Product Under Test"
fi

########################################################################
# printer.cfg Version Test
########################################################################
testNum=$((testNum + 1))
testNumString=$(makeTestNUMString "$testNum")

echo -e  "$outline$PHULLSTRING"
doAppend "!TEST$testNumString: printer.cfg Version Check"
logFileImage="$logFileImage\nTEST$testNumString: printer.cfg Version Check"

echo -ne "RETURNVERSION\n" > "$TTY" || true

TEST_RESPONSE=$(timeout $readDlay cat "$TTY") || true

echoE "$TEST_RESPONSE"

PCversion=$(ftVersion) 
echo -e "PCversion = $PCversion"
if echo "$TEST_RESPONSE" | grep -q "Version: $PCversion"; then
  echoE " "
else
  drawError "TEST$testNumString: printer.cfg Version Check" "Invalid printer.cfg Version"
fi

########################################################################
# VINMON
########################################################################
testNum=$((testNum + 1))
testNumString=$(makeTestNUMString "$testNum")

echo -e  "$outline$PHULLSTRING"
doAppend "!TEST$testNumString: VINMON"
logFileImage="$logFileImage\nTEST$testNumString: VINMON"

echo -ne "VINTEST\n" > "$TTY" || true

TEST_RESPONSE=$(timeout $readDlay cat "$TTY") || true

echoE "$TEST_RESPONSE"

if echo "$TEST_RESPONSE" | grep -q "VINTest: PASS"; then
  echoE " "
else
  drawError "TEST$testNumString: VINMON" "Invalid Voltage Read"
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
TEST_RESPONSE=$(timeout $readDlay cat "$TTY") || true
echoE "sensorvalue Initial State: $TEST_RESPONSE"

if echo "$TEST_RESPONSE" | grep -q "sensorvalue=0"; then
  echoE " "
else
  drawError "TEST$testNumString: sensorvalue Initial State Check" "sensorvalue NOT 0"
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

TEST_RESPONSE=$(timeout $readDlay cat "$TTY") || true

echoE "$TEST_RESPONSE"

if echo "$TEST_RESPONSE" | grep -q "MCUTest: PASS"; then
  echoE " "
else
  drawError "TEST$testNumString: MCU Temperature Test" "Invalid MCU Temperature Value Read"
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

  TEST_RESPONSE=$(timeout $readDlay cat "$TTY") || true

  echoE "$TEST_RESPONSE"

  if echo "$TEST_RESPONSE" | grep -q "ToolheadTest: PASS"; then
    echoE " "
  else
    drawError "TEST$testNumString: Toolhead Temperature Test" "Invalid Toolhead Temperature Value Read"
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

    TEST_RESPONSE=$(timeout $readDlay cat "$TTY") || true

    echoE "$TEST_RESPONSE"

    if echo "$TEST_RESPONSE" | grep -q "ThermTest: thermo$thermNum: PASS"; then
      echoE " "
    else
      if echo "$TEST_RESPONSE" | grep -q "ThermTest: Check thermo$thermNum Connection to HeaterBoard"; then
        drawError "TEST$testNumString: THERMO$thermNum Temperature Test" "Check Thermistor THERMO$thermNum Connection to Board Under Test"
      else
        drawError "TEST$testNumString: THERMO$thermNum Temperature Test" "Invalid THERMO$thermNum Thermistor Temperature Value Read"
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
    sleep $readDlay
    echo -ne "GETSENSORVALUE\n" > "$TTY" || true
    TEST_RESPONSE=$(timeout $readDlay cat "$TTY") || true
    
    if echo "$TEST_RESPONSE" | grep -q "sensorvalue=$expectedValue"; then
      if [[ 0 != $doLEDCheck ]]; then
        echoE " "
        Yn=$(checkLED "$testNumString" "$dSensorpin")
        echoE " "
      else
        Yn="Y"
      fi

      if [[ "T" == "$Yn" ]]; then
        echoE " "
        drawError "TEST$testNumString: $dSensorpin LED Active Check" "Input Timeout"
      elif [[ "Y" == "$Yn" ]]; then
        echoE   "TEST$testNumString: $dSensorpin LED Active"
        echoE " "

        echo -ne "SETDEMUX VALUE=0\n" > "$TTY" || true
        sleep $readDlay
        echo -ne "GETSENSORVALUE\n" > "$TTY" || true
        TEST_RESPONSE=$(timeout $readDlay cat "$TTY") || true
          
        if echo "$TEST_RESPONSE" | grep -q "sensorvalue=0"; then
          sleep 0.1
        else
          drawError "TEST$testNumString: $dSensorpin Not Reset" "$dSensorpin Not Reset"
        fi
      else
        echo -ne "SETDEMUX VALUE=0\n" > "$TTY" || true
        drawError "TEST$testNumString: $dSensorpin LED Active Check" "LED Not Lit"
      fi
    else
      echoE " "
      echo -ne "SETDEMUX VALUE=0\n" > "$TTY" || true
      drawError "TEST$testNumString: $dSensorpin Set Check" "$dSensorpin NOT Set"
    fi

    expectedPin=$((expectedPin + 1))
    expectedValue=$((expectedValue * 2))
  
  done
########################################################################
fi


if [[ 0 != $doNeoPixelCheck ]]; then
########################################################################
# Loop Through Check NEOPIXEL# Operation
########################################################################
  NeoPixelPins=("NeoPixel0pin" "NeoPixel1pin" ) 
  currentNeoPixel=0
  expectedValue=64
  for NeoPixelPin in "${NeoPixelPins[@]}"; do
    testNum=$((testNum + 1))
    testNumString=$(makeTestNUMString "$testNum")

    echo -e  "$outline$PHULLSTRING"
    doAppend "!TEST$testNumString: Check $NeoPixelPin Operation"
    logFileImage="$logFileImage\nTEST$testNumString: Check $NeoPixelPin Operation"

    echo -ne "SETNEOPIXEL NUMBER=$currentNeoPixel VALUE=1\n" > "$TTY" || true
    sleep $readDlay
    echo -ne "GETSENSORVALUE\n" > "$TTY" || true
    TEST_RESPONSE=$(timeout $readDlay cat "$TTY") || true
    
    if echo "$TEST_RESPONSE" | grep -q "sensorvalue=$expectedValue"; then
      echo -ne "SETNEOPIXEL NUMBER=$currentNeoPixel VALUE=0\n" > "$TTY" || true
      sleep $readDlay
      echo -ne "GETSENSORVALUE\n" > "$TTY" || true
      TEST_RESPONSE=$(timeout $readDlay cat "$TTY") || true
          
      if echo "$TEST_RESPONSE" | grep -q "sensorvalue=0"; then
        echoE " "
        sleep 0.1
      else
        drawError "TEST$testNumString: $NeoPixelPin Not Reset" "$NeoPixelPin Not Reset"
      fi
    else
      echoE " "
      echo -ne "SETDEMUX VALUE=0\n" > "$TTY" || true
      drawError "TEST$testNumString: $NeoPixelPin Set Check" "$NeoPixelPin NOT Set"
    fi

    currentNeoPixel=$((currentNeoPixel + 1))
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
  TEST_RESPONSE=$(timeout $readDlay cat "$TTY") || true
  echoE "Inductive Sensor Set State: $TEST_RESPONSE"
    
  if echo "$TEST_RESPONSE" | grep -q "sensorvalue=32"; then
    if [[ 0 != $doLEDCheck ]]; then
      echoE " "
      Yn=$(checkLED "$testNumString" "Inductive")
    else
      Yn="Y"
    fi

    if [[ "T" == "$Yn" ]]; then
      echoE " "
      drawError "TEST$testNumString: Inductive Sensor LED Active Check" "Input Timeout"
    elif [[ "Y" == "$Yn" ]]; then
      echoE " "
      echoE   "TEST$testNumString: Inductive Sensor LED Active"
      echoE " "
      echo -ne "SETDEMUX VALUE=0\n" > "$TTY" || true
      sleep 0.5
          
      echo -ne "GETSENSORVALUE\n" > "$TTY" || true
      TEST_RESPONSE=$(timeout $readDlay cat "$TTY") || true
      echoE "Inductive Sensor Reset State: $TEST_RESPONSE"
          
      if echo "$TEST_RESPONSE" | grep -q "sensorvalue=0"; then
        echoE " "
      else
        echoE " "
        drawError "TEST$testNumString: Inductive Sensor Not Reset" "Inductive Sensor Not Reset"
      fi
    else
      echoE " "
      echo -ne "SETDEMUX VALUE=0\n" > "$TTY" || true
      drawError "TEST$testNumString: Inductive Sensor LED Active Check" "LED Not Lit"
    fi
  else
    echoE " "
    echo -ne "SETDEMUX VALUE=0\n" > "$TTY" || true
    drawError "TEST$testNumString: Inductive Sensor Set Check" "Inductive Sensor NOT Set"
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
  TEST_RESPONSE=$(timeout $readDlay cat "$TTY") || true
  echoE "BLTouch Servo Set State: $TEST_RESPONSE"
    
  if echo "$TEST_RESPONSE" | grep -q "sensorvalue=512"; then
    echo -ne "SETBLSERVO VALUE=0\n" > "$TTY" || true
    sleep 0.5
    echo -ne "GETSENSORVALUE\n" > "$TTY" || true
    TEST_RESPONSE=$(timeout $readDlay cat "$TTY") || true
    echoE "BLTouch Servo Reset State: $TEST_RESPONSE"
          
    if echo "$TEST_RESPONSE" | grep -q "sensorvalue=0"; then
      echoE " "
    else
      echoE " "
      drawError "TEST$testNumString: BLTouch Servo Not Reset" "BLTouch Servo Not Reset"
    fi
  else
    echoE " "
    echo -ne "SETDEMUX VALUE=0\n" > "$TTY" || true
    drawError "TEST$testNumString: BLTouch Servo Set Check" "BLTouch Servo NOT Set"
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
  TEST_RESPONSE=$(timeout $readDlay cat "$TTY") || true
  echoE "BLTouch Probe Set State: $TEST_RESPONSE"
    
  if echo "$TEST_RESPONSE" | grep -q "sensorvalue=256"; then
    if [[ 0 != $doLEDCheck ]]; then
      echoE " "
      Yn=$(checkLED "$testNumString" "BLTouch")
    else
      Yn="Y"
    fi

    if [[ "T" == "$Yn" ]]; then
      echoE " "
      drawError "TEST$testNumString:  BLTouch Probe LED Active Check" "Input Timeout"
    elif [[ "Y" == "$Yn" ]]; then
      echoE " "
      echoE   "TEST$testNumString: BLTouch Probe LED Active"
      echoE " "

      echo -ne "SETBLPROBE VALUE=0\n" > "$TTY" || true
      sleep 0.5
          
      echo -ne "GETSENSORVALUE\n" > "$TTY" || true
      TEST_RESPONSE=$(timeout $readDlay cat "$TTY") || true
      echoE "BLTouch Probe Reset State: $TEST_RESPONSE"
          
      if echo "$TEST_RESPONSE" | grep -q "sensorvalue=0"; then
        echoE " "
      else
        echoE " "
        drawError "TEST$testNumString: BLTouch Probe Not Reset" "BLTouch Probe Not Reset"
      fi
    else
      echoE " "
      echo -ne "SETDEMUX VALUE=0\n" > "$TTY" || true
      drawError "TEST$testNumString: BLTouch Probe LED Active Check" "LED Not Lit"
    fi
  else
    echoE " "
    echo -ne "SETDEMUX VALUE=0\n" > "$TTY" || true
    drawError "TEST$testNumString: BLTouch Probe Set Check" "BLTouch Probe NOT Set"
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
    echo -ne "SETADXLMOSI VALUE=$spi\n" > "$TTY" || true
    sleep 0.5
    echo -ne "GETSENSORVALUE\n" > "$TTY" || true
    TEST_RESPONSE=$(timeout $readDlay cat "$TTY") || true
    echoE "SPI CS/MOSI OR Gate Set $spi: $TEST_RESPONSE"
    
    if echo "$TEST_RESPONSE" | grep -q "sensorvalue=1024"; then
      echoE " "
    else
      echoE " "
      echo -ne "SETADXLMOSI VALUE=0\n" > "$TTY" || true
      drawError "TEST$testNumString: SPI CS/MOSI OR Gate Set $spi Check" "SPI CS/MOSI OR Gate NOT Set"
    fi
  done

  echo -ne "SETADXLMOSI VALUE=0\n" > "$TTY" || true
  sleep 0.5
  echo -ne "GETSENSORVALUE\n" > "$TTY" || true
  TEST_RESPONSE=$(timeout $readDlay cat "$TTY") || true
  echoE "SPI CS/MOSI OR Gate Set 0: $TEST_RESPONSE"
    
  if echo "$TEST_RESPONSE" | grep -q "sensorvalue=0"; then
    echoE " "
  else
    echoE " "
    drawError "TEST$testNumString: SPI CS/MOSI OR Gate Not Reset" "SPI CS/MOSI OR Gate Not Reset"
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

    if echo "$RESPONSE_LO" | grep -q "Pin State is HIGH"; then  #  Polarity Changed for ver="0.16"
      if echo "$RESPONSE_HI" | grep -q "Pin State is low"; then  #  Polarity Changed for ver="0.16"
        echo -ne "SETHEATER NUMBER=$htr VALUE=1\n" > "$TTY" || true  
        sleep 0.5
        RESPONSE_LO=$(python ~/python/gpioread.py ${htrcomplo[$htr]}) || true
        RESPONSE_HI=$(python ~/python/gpioread.py ${htrcomphi[$htr]}) || true

        if [[ 0 != $doLEDCheck ]]; then
          echoE " "
          Yn=$(checkLED "$testNumString" "heater$htr")
          echoE " "
        else
          Yn="Y"
        fi

        echo -ne "SETHEATER NUMBER=$htr VALUE=0\n" > "$TTY" || true
        sleep 0.5

        if [[ "T" == "$Yn" ]]; then
          echoE " "
          drawError "TEST$testNumString:  Heater$htr LED Active Check" "Input Timeout"
        elif [[ "Y" == "$Yn" ]]; then
          echoE "TEST$testNumString: Heater$htr Probe LED Active"
          echoE " "

          if echo "$RESPONSE_LO" | grep -q "Pin State is low"; then  #  Polarity Changed for ver="0.16"
            if echo "$RESPONSE_HI" | grep -q "Pin State is low"; then  #  Polarity Changed for ver="0.16"
              RESPONSE_LO=$(python ~/python/gpioread.py ${htrcomplo[$htr]}) || true
              RESPONSE_HI=$(python ~/python/gpioread.py ${htrcomphi[$htr]}) || true

              if echo "$RESPONSE_LO" | grep -q "Pin State is HIGH"; then  #  Polarity Changed for ver="0.16"
                if echo "$RESPONSE_HI" | grep -q "Pin State is low"; then  #  Polarity Changed for ver="0.16"
                  sleep 0.1
                else
                  drawError "TEST$testNumString: Heater$htr High Comparator Reset Output Test" "Heater$htr High Comparator NOT in Correct Reset State"
                fi    
              else
                drawError "TEST$testNumString: Heater$htr Low Comparator Reset Output Test" "Heater$htr Low Comparator NOT in Correct Reset State"
              fi    

            else
              drawError "TEST$testNumString: Heater$htr High Comparator Set Output Test" "Heater$htr High Comparator NOT in Correct Set State"
            fi    
          else
            drawError "TEST$testNumString: Heater$htr Low Comparator Set Output Test" "Heater$htr Low Comparator NOT in Correct Set State"
          fi    

        else
          echoE " "
          drawError "TEST$testNumString: Heater$htr LED Active Check" "LED Not Lit"
        fi

      else
        echoE " "
        drawError "TEST$testNumString: Heater$htr High Comparator Initial Output Test" "Heater$htr High Comparator NOT in Correct Initial State"
      fi    
    else
      echoE " "
      drawError "TEST$testNumString: Heater$htr Low Comparator Initial Output Test" "Heater$htr Low Comparator NOT in Correct Initial State"
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

    if echo "$RESPONSE_LO" | grep -q "Pin State is HIGH"; then  #  Polarity Changed for ver="0.16"
      if echo "$RESPONSE_HI" | grep -q "Pin State is low"; then  #  Polarity Changed for ver="0.16"
        echo -ne "SETFAN NUMBER=$fan VALUE=1\n" > "$TTY" || true  
        sleep 0.5
        RESPONSE_LO=$(python ~/python/gpioread.py ${fancomplo[$fan]}) || true
        RESPONSE_HI=$(python ~/python/gpioread.py ${fancomphi[$fan]}) || true

        if [[ 0 != $doLEDCheck ]]; then
          echoE " "
          Yn=$(checkLED "$testNumString" "fan$fan")
          echoE " "
        else
          Yn="Y"
        fi

        echo -ne "SETFAN NUMBER=$fan VALUE=0\n" > "$TTY" || true
        sleep 0.5

        if [[ "T" == "$Yn" ]]; then
          echoE " "
          drawError "TEST$testNumString:   Fan$fan LED Active Check" "Input Timeout"
        elif [[ "Y" == "$Yn" ]]; then
          echoE "TEST$testNumString: Fan$fan Probe LED Active"
          echoE " "

          if echo "$RESPONSE_LO" | grep -q "Pin State is low"; then  #  Polarity Changed for ver="0.16"
            if echo "$RESPONSE_HI" | grep -q "Pin State is low"; then  #  Polarity Changed for ver="0.16"
              RESPONSE_LO=$(python ~/python/gpioread.py ${fancomplo[$fan]}) || true
              RESPONSE_HI=$(python ~/python/gpioread.py ${fancomphi[$fan]}) || true

              if echo "$RESPONSE_LO" | grep -q "Pin State is HIGH"; then  #  Polarity Changed for ver="0.16"
                if echo "$RESPONSE_HI" | grep -q "Pin State is low"; then  #  Polarity Changed for ver="0.16"
                  sleep 0.1
                else
                  drawError "TEST$testNumString: Fan$fan High Comparator Reset Output Test" "Fan$fan High Comparator NOT in Correct Reset State"
                fi    
              else
                drawError "TEST$testNumString: Fan$fan Low Comparator Reset Output Test" "Fan$fan Low Comparator NOT in Correct Reset State"
              fi    

            else
              drawError "TEST$testNumString: Fan$fan High Comparator Set Output Test" "Fan$fan High Comparator NOT in Correct Set State"
            fi    
          else
            drawError "TEST$testNumString: Fan$fan Low Comparator Set Output Test" "Fan$fan Low Comparator NOT in Correct Set State"
          fi    

        else
          echoE " "
          drawError "TEST$testNumString: Fan$fan LED Active Check" "LED Not Lit"
        fi

      else
        echoE " "
        drawError "TEST$testNumString: Fan$fan High Comparator Initial Output Test" "Fan$fan High Comparator NOT in Correct Initial State"
      fi    
    else
      echoE " "
      drawError "TEST$testNumString: Fan$fan Low Comparator Initial Output Test" "Fan$fan Low Comparator NOT in Correct Initial State"
    fi    
  done  
########################################################################
fi


if [[ 0 != $doStepperCheck ]]; then
########################################################################
# Loop Through stepper# Operation Test
########################################################################
  EQUALS_STRING=" = "
  OK_STRING="
o"
  for stepper in {0..3}; do
    testNum=$((testNum + 1))
    testNumString=$(makeTestNUMString "$testNum")

    echo -e  "$outline$PHULLSTRING"
    doAppend "!TEST$testNumString: Test Stepper$stepper Driver Operation"
    logFileImage="$logFileImage\nTEST$testNumString: Test Stepper$stepper Driver Operation"

    echo -ne "read_tmc_field field=sgthrs stepper=\"manual_stepper stepper_$stepper\"\n" > "$TTY" || true
    INIT_SGTHRS==$(timeout 1 cat "$TTY") || true
    EXTRACTED_SGTHRS=${INIT_SGTHRS#*$EQUALS_STRING}
    EXTRACTED_SGTHRS=${EXTRACTED_SGTHRS%$OK_STRING*}

    echo -ne "MANUAL_STEPPER ENABLE=1 STEPPER=stepper_$stepper\n" > "$TTY" || true  
    sleep 0.1
    echo -ne "MANUAL_STEPPER SET_POSITION=0 STEPPER=stepper_$stepper\n" > "$TTY" || true  
    sleep 0.1
    echo -ne "MANUAL_STEPPER MOVE=40 STOP_ON_ENDSTOP=1 STEPPER=stepper_$stepper\n" > "$TTY" || true  
    sleep 1

    echo -ne "read_tmc_field field=sg_result stepper=\"manual_stepper stepper_$stepper\"\n" > "$TTY" || true
    INIT_SG_RESULT==$(timeout 1 cat "$TTY") || true
    EXTRACTED_INIT_SG_RESULT=${INIT_SG_RESULT#*$EQUALS_STRING}
    EXTRACTED_INIT_SG_RESULT=${EXTRACTED_INIT_SG_RESULT%$OK_STRING*}
    
    echo -ne "MANUAL_STEPPER MOVE=30 STEPPER=stepper_$stepper\n" > "$TTY" || true
    sleep 0.5
    echo -ne "read_tmc_field field=sg_result stepper=\"manual_stepper stepper_$stepper\"\n" > "$TTY" || true
    FINAL_SG_RESULT==$(timeout 1 cat "$TTY") || true
    EXTRACTED_FINAL_SG_RESULT=${FINAL_SG_RESULT#*$EQUALS_STRING}
    EXTRACTED_FINAL_SG_RESULT=${EXTRACTED_FINAL_SG_RESULT%$OK_STRING*}

    echo -ne "MANUAL_STEPPER ENABLE=0 STEPPER=stepper_$stepper\n" > "$TTY" || true  
    sleep 0.1

    doublesgthrs=$((EXTRACTED_SGTHRS * 2))
    init_sg_result=$(($EXTRACTED_INIT_SG_RESULT + 0))
    final_sg_result=$(($EXTRACTED_FINAL_SG_RESULT + 0))
    echoE "TEST$testNumString: Test Stepper$stepper Operation:"
    echoE "  sgthrs*2=$doublesgthrs,  init_sg_result=$init_sg_result,  final_sg_result=$final_sg_result."
    echoE " "

    if [[ "$doublesgthrs" -lt "$init_sg_result" ]]; then
      drawError "TEST$testNumString: Stepper$stepper Operation Test" "Stepper$stepper Did NOT Return Expect SG_RESULT Value AFTER Homing"
    elif [[ "$doublesgthrs" -gt "$final_sg_result" ]]; then
      drawError "TEST$testNumString: Stepper$stepper Operation Test" "Stepper$stepper Did NOT Return Expected SG_RESULT Value AFTER Movement"
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
  
  else
    echoE " "
    drawError "Software Sealing" "Unable to Start Katapult"
  fi
else
  echoE " "
  drawPASS   
fi

echo -e "$logFileImage" > ~/logs/$logFileName

exit
