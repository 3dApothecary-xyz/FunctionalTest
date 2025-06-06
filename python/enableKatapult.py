#!/usr/bin/python3

# Includes
import RPi.GPIO as GPIO
import time

# Pin Definitions
RESET = 5

# Enable IO Pins
GPIO.setmode(GPIO.BOARD)
GPIO.setup(RESET, GPIO.OUT)


# Application Functionality
GPIO.output(RESET, GPIO.HIGH)
time.sleep(0.5)
GPIO.output(RESET, GPIO.LOW)
time.sleep(0.5)
GPIO.output(RESET, GPIO.HIGH)
time.sleep(0.5)
GPIO.output(RESET, GPIO.LOW)

# Restore Pin State
GPIO.cleanup()
