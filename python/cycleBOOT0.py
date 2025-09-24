#!/usr/bin/python3

import RPi.GPIO as GPIO
import time

#BOOT0 = 3  # For NewHat2
BOOT0 = 7  # For NewHat3

GPIO.setmode(GPIO.BOARD)
GPIO.setup(BOOT0, GPIO.OUT)

for i in range(10):
  GPIO.output(BOOT0, GPIO.HIGH)
  time.sleep(2)
  GPIO.output(BOOT0, GPIO.LOW)
  time.sleep(2)
  print('Interation: ', i + 1)

GPIO.cleanup()
