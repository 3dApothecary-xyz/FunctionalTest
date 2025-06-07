#!/bin/bash

TTY=~/printer_data/comms/klippy.serial

# Send STATUS command
echo -ne "TEST5\n" > "$TTY"

# Listen for the response (timeout after 2 seconds)
RESPONSE=$(timeout 2 cat "$TTY")

# Print the response
echo "$RESPONSE"

# Check if it contains "accelerometer values"
if echo "$RESPONSE" | grep -q "accelerometer values"; then
    echo "Accelerometer Present"
else
    echo "NO MATCH"
fi
