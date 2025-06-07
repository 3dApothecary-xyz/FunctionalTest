#!/bin/bash

TTY=~/printer_data/comms/klippy.serial

# Send SETINDICATOR command
echo -ne "SETINDICATOR INDICATOR=0 VALUE=1\n" > "$TTY"

# Listen for the response (timeout after 2 seconds)
RESPONSE=$(timeout 2 cat "$TTY")

# Print the response
echo "$RESPONSE"

# Check if it contains "ok"
if echo "$RESPONSE" | grep -q "ok"; then
    echo "Macro Responded in the Affirmative"
else
    echo "Problem with Macro Response"
    exit
fi

sleep 2

# Repeat SETINDICATOR command
echo -ne "SETINDICATOR INDICATOR=0 VALUE=0\n" > "$TTY"

# Listen for the response
RESPONSE=$(timeout 2 cat "$TTY")
echo "$RESPONSE"

# Check the response
if echo "$RESPONSE" | grep -q "ok"; then
  echo "Second Response in the Affirmative"
else
  echo "Second Response NOT in the Affirmative"
fi
