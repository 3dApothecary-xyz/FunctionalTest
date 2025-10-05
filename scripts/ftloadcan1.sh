#!/bin/bash
# Script to simplify Functional Test Micro SD Card setup
# Execute with "curl -s https://raw.githubusercontent.com/3dApothecary-xyz/FunctionalTest/refs/heads/main/scripts/ftloadcan1.sh | bash"

expectedNetworkdResponse3="  systemd-networkd.service                                                                                                                       loaded active running   Network Configuration  systemd-networkd.socket                                                                                                                        loaded active running   Network Service Netlink Socket"
expectedNetworkdResponse4="loaded active running"
expectedCanrulesResponse='SUBSYSTEM=="net", ACTION=="change|add", KERNEL=="can*"  ATTR{tx_queue_len}="128"'
expectedCannetworkResponse="[Match]
Name=can*

[CAN]
BitRate=1M
RestartSec=0.1s

[Link]
RequiredForOnline=no"

sudo systemctl enable systemd-networkd

sudo systemctl start systemd-networkd

networkdResponse=$(systemctl | grep systemd-networkd) || true
cleanedNetworkdResponse=$(echo "$networkdResponse" | tr -dc '[:print:]')
echo -e "\"$cleanedNetworkdResponse\""

#if [[ "$cleanedNetworkdResponse" != "$expectedNetworkdResponse3" ]]; then
if echo "$cleanedNetworkdResponse" | grep -q "expectedNetworkdResponse4"; then
  echo -e "  "
else
  echo -e "  "
  echo -e "\"systemctl | grep systemd-networkd\" RESPONSE INVALID"
  exit
fi

sudo systemctl disable systemd-networkd-wait-online.service

echo -e 'SUBSYSTEM=="net", ACTION=="change|add", KERNEL=="can*"  ATTR{tx_queue_len}="128"' | sudo tee /etc/udev/rules.d/10-can.rules > /dev/null

canrulesResponse=$(cat /etc/udev/rules.d/10-can.rules)
echo -e "\"$canrulesResponse\""

if [[ "$canrulesResponse" != "$expectedCanrulesResponse" ]]; then
  echo -e "  "
  echo -e "cat 10-can.rules VERSION INVALID"
  exit
fi

echo -e "[Match]\nName=can*\n\n[CAN]\nBitRate=1M\nRestartSec=0.1s\n\n[Link]\nRequiredForOnline=no" | sudo tee /etc/systemd/network/25-can.network > /dev/null

cannetworkResponse=$(cat /etc/systemd/network/25-can.network)
echo -e "\"$cannetworkResponse\""

if [[ "$cannetworkResponse" != "$expectedCannetworkResponse" ]]; then
  echo -e "  "
  echo -e "cat 25-can.network VERSION INVALID"
  exit
fi

echo -e "  "
echo -e "ftcanload1.sh EXECUTED SUCCESSFULLY"
