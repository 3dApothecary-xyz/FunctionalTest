#!/bin/bash
TTY=~/printer_data/comms/klippy.serial
# Send STATUS command
echo -ne "STATUS\n" > "$TTY"
# Listen for the response (timeout after 2 seconds)
RESPONSE=$(timeout 2 cat "$TTY")
# Print the response
echo "$RESPONSE"
# Check if it contains "Ready"
if echo "$RESPONSE" | grep -q "Ready"; then
    echo "HURRAY"
fi
