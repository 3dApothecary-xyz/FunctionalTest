#!/usr/bin/python3

import sys
import argparse
import RPi.GPIO as GPIO

GPIO.setmode(GPIO.BOARD)

pinList = [3, 5, 7, 11, 13, 15, 19, 21, 23, 29, 31, 33, 35, 37, 12, 16, 18, 22, 24, 26, 32, 36, 38, 40]

if __name__ == "__main__":

  if not len(sys.argv) > 1:
    print("No Pin Number Passed")

  else:
    parser = argparse.ArgumentParser(description="Read Raspberry Pi GPIO.")
    parser.add_argument("pin", type=int)

    args = parser.parse_args()

    if not args.pin in pinList:
      print("Pin Passed Number is invalid: ", args.pin)

    else:
      print("Passed Pin Number is: ", args.pin)

      GPIO.setmode(GPIO.BOARD)
      GPIO.setup(args.pin, GPIO.IN)

      if 0 == GPIO.input(args.pin): 
        print("Pin State is low")

      else:
        print("Pin State is HIGH")

      GPIO.cleanup(args.pin)
