#!/usr/bin/python3

# Includes
import RPi.GPIO as GPIO
import time

# Pin Definitions
TESTPIN = 35

# Enable IO Pins
GPIO.setmode(GPIO.BOARD)
GPIO.setup(TESTPIN, GPIO.OUT)


# Application Functionality
for i in range(20):
  GPIO.output(TESTPIN, GPIO.HIGH)
  time.sleep(0.25)
  GPIO.output(TESTPIN, GPIO.LOW)
  GPIO.sleep(0.25)

# Restore Pin State
GPIO.cleanup()
