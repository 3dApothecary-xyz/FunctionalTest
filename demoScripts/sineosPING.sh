#!/bin/bash

# TTY=~/printer_data/comms/klippy.serial

# Send STATUS PING command and Store Result
pingResponse=$(ping -c 2 klipper.discourse.group)

# Print the response
echo "$pingResponse"

# Check if it contains "klipper.hosted"
if echo "$pingResponse" | grep -q "klipper.hosted"; then
    echo "Ping Works!"
else
    echo "Ping Bad"
fi
