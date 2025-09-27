#!/bin/bash
# Script to simplify Functional Test Micro SD Card setup
# Execute with "curl -s https://raw.githubusercontent.com/3dApothecary-xyz/FunctionalTest/refs/heads/main/scripts/ftloadklipper.sh | bash"

expectedSerialDevResponse="usb-katapult_stm32g0b1xx_"
expectedCanLinkShowTopLine="can0: <NOARP,ECHO> mtu 16 qdisc noop state DOWN mode DEFAULT group default qlen 128"
expectedCANLinkShowBitrate="bitrate 1000000 sample-point 0.750"

serialDevResponse=$(ls /dev/serial/by-id)
echo -e "\"$serialDevResponse\""

if [[ "${serialDevResponse:0:25}" != "$expectedSerialDevResponse" ]]; then
  echo -e "  "
  echo -e "Invalid Response to \"ls /dev/serial/by-id\""
  exit
fi

python3 ~/katapult/scripts/flashtool.py -f ~/bin/klipper.bin -d /dev/serial/by-id/$serialDevResponse

sleep 1

canLinkShow=$(ip -s -d link show can0)
echo -e "\"$canLinkShow\""

if echo "$canLinkShow" | grep -q "$expectedCanLinkShowTopLine"; then
  if echo "$canLinkShow" | grep -q "$expectedCanLinkShowBitrate"; then
    echo -e " "
    echo -e "Have Correct CAN Link Show Response"
  else
    echo -e " "
    echo -e "Missing Bitrate Information in CAN Link Show Response"
    exit
  fi
else
  echo -e " "
  echo -e "Missing qlen  Information in CAN Link Show Response"
  exit
fi

mcuUUID=$(~/klippy-env/bin/python ~/klipper/scripts/canbus_query.py can0)
