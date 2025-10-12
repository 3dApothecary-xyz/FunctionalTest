#!/bin/bash
# Script to simplify Functional Test Micro SD Card setup
# Execute with "curl -s https://raw.githubusercontent.com/3dApothecary-xyz/FunctionalTest/refs/heads/main/scripts/ftloadcan1.sh | bash"

expectedNetworkd="systemd-networkd.service"
expectedSocket="systemd-networkd.socket"
expectedNetworkdResponse5="loaded active"
expectedNetworkdResponse6="running"
canRules='SUBSYSTEM=="net", ACTION=="change|add", KERNEL=="can*"  ATTR{tx_queue_len}="128"'
canNetwork="[Match]
Name=can*

[CAN]
BitRate=1M

[Link]
RequiredForOnline=no"

sudo systemctl enable systemd-networkd

sudo systemctl start systemd-networkd

networkdResponse=$(systemctl | grep systemd-networkd) || true

cutnetworkdResponse="${networkdResponse#*${expectedNetworkd}}" 
cutnetworkdResponse="${cutnetworkdResponse%${expectedSocket}*}" 
echo -e "\"$cutnetworkdResponse\""

if echo "$cutnetworkdResponse" | grep -q "$expectedNetworkdResponse5"; then
  if echo "$cutnetworkdResponse" | grep -q "$expectedNetworkdResponse6"; then
    echo -e "  "
  else
    echo -e "  "
    echo -e "\"systemctl | grep systemd-networkd\" RESPONSE INVALID"
    exit
  fi
else
  echo -e "  "
  echo -e "\"systemctl | grep systemd-networkd\" RESPONSE INVALID"
  exit
fi

sudo systemctl disable systemd-networkd-wait-online.service

echo -e "$canRules"  | sudo tee /etc/udev/rules.d/10-can.rules > /dev/null

canrulesResponse=$(cat /etc/udev/rules.d/10-can.rules)
echo -e "\"$canrulesResponse\""

if [[ "$canrulesResponse" != "$canRules" ]]; then
  echo -e "  "
  echo -e "cat 10-can.rules VERSION INVALID"
  exit
fi

echo -e "$canNetwork" | sudo tee /etc/systemd/network/25-can.network > /dev/null

cannetworkResponse=$(cat /etc/systemd/network/25-can.network)
echo -e "\"$cannetworkResponse\""

if [[ "$cannetworkResponse" != "$canNetwork" ]]; then
  echo -e "  "
  echo -e "cat 25-can.network VERSION INVALID"
  exit
fi

echo -e "  "
echo -e "ftcanload1.sh EXECUTED SUCCESSFULLY"
