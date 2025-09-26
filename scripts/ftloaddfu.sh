#!/bin/bash
# Script to simplify Functional Test Micro SD Card setup
# Execute with "curl -s https://raw.githubusercontent.com/3dApothecary-xyz/FunctionalTest/refs/heads/main/scripts/ftloaddfu.sh | bash"

expectedSerialDevResponse="usb-katapult_stm32g0b1xx_"
serialDevResponse=$(ls /dev/serial/by-id)
echo -e "\"$serialDevResponse\""

if [[ "${serialDevResponse:0:25}" != "$expectedSerialDevResponse" ]]; then
  echo -e "  "
  echo -e "Invalid Response to \"ls /dev/serial/by-id\""
  exit
fi

python3 ~/katapult/scripts/flashtool.py -f ~/bin/KGP_4x2209_DFU.bin -d /dev/serial/by-id/$serialDevResponse

echo -e "  "
echo -e "ftloaddfu.sh EXECUTED SUCCESSFULLY"
