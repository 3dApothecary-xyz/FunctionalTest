#!/usr/bin/python3

# Includes
import RPi.GPIO as GPIO
import time

# Pin Definitions
BOOT0 = 3
RESET = 5

# Enable IO Pins
GPIO.setmode(GPIO.BOARD)
GPIO.setup(BOOT0, GPIO.OUT)
GPIO.setup(RESET, GPIO.OUT)


# Application Functionality
GPIO.output(BOOT0, GPIO.HIGH)
time.sleep(0.2)
GPIO.output(RESET, GPIO.HIGH)
time.sleep(0.5)
GPIO.output(RESET, GPIO.LOW)
time.sleep(0.2)
GPIO.output(BOOT0, GPIO.LOW)

# Restore Pin State
GPIO.cleanup()
