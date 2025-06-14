# KGP 4x2209 FunctionalTest

![KGP 4x2209 Image](images/KGP_4x2209_3D.png)

## Functional Test Apparatus

* Manufacturer Supplied: KGP 4x2209 "Board Under Test"
* Manufacturer Supplied: 24V/5A "Bench Power Supply" with Digital Outputs and Overcurrent Protection
* Manufacturer Supplied: 1920 x 1080p "HDMI Monitor"
* Manufacturer Supplied: Full Sized HDMI Cable (for Board Under Test to HDMI Monitor)
* Manufacturer supplied: Ethernet Cable with RJ45 Connector to Active Internet Connection
* Company Supplied: USB Keyboard (US Key Layout)
* Company Supplied: Silicon Solder Pad with Test Apparatus Markings and Parts
* Company Supplied: [Raspberry Pi CM4 (CM4101000)](https://datasheets.raspberrypi.com/cm4/cm4-product-brief.pdf)
* Company Supplied: Micro SD Card 64GB or larger
* Company Supplied: Red/Black Power Wiring from Bench Power Supply to Board Under Test
* Company Supplied: ["NewHat2" Raspberry Pi GPIO Hat](https://github.com/3dApothecary-xyz/NewHat2)
* Company Supplied: 6 Pin Ribbon Cable from NewHat2 to Board Under Test
* Company Supplied: Red JST XH 3 Pin to Dupont 3 Pin Socket Wire
* Company Supplied: Black JST XH 3 Pin to Dupont 3 Pin Socket Wire
* Company Supplied: Yellow JST XH 3 Pin to Dupont 3 Pin Socket Wire
* Company Supplied: Blue JST XH 3 Pin to Dupont 3 Pin Socket Wire
* Company Supplied: Green JST XH 3 Pin to Dupont 3 Pin Socket Wire
* Company Supplied: 4x 15cm long 24V LED Strip Lighting on 2 Pin Dupont Connector
* Company Supplied: 2x 8 NeoPixel LED strips on 3 Pin Dupont Connector
* Company Supplied: ADXL345 Prototype Board with 8 Pin Header 
* Company Supplied: 6Pin Ribbon Cable with 8 Pin Dupont Connector and 6 Pin Dupont Connector
* Company Supplied: BTT EBB42 Toolhead Controller
* Company Supplied: CANBus Cable to Connect Board Under Test to BTT EBB42 Toolhead Controller
* Company Supplied: [Antclabs "BLTouch" v3.1 Sensor](https://www.antclabs.com/bltouch-v3) Mounted to "BLTouch" Stepper Motor Base
* Company Supplied: "BLTouch" Custom Stepper Motor Base with Striker Mount on Stepper Motor
* Company Supplied: 12V+ Inductive Probe Mounted to Stepper Motor Base
* Company Supplied: 12V+ Inductive Probe Custom Stepper Motor Base with Striker on Stepper Motor
* Company Supplied: 2x Custom Motor Base with Striker
* Company Supplied: 4x Lerdge NEMA 17 42mm Motors with Dupont Connectors

## Functional Test Process

* `sudo service klipper stop`
  
* loadFlag = 7

* Show "FIRMWARE LOAD" Message

* sleep 5s

* Enable DFU Mode on Board Under Test's MCU (Hold `BOOT0` high, cycle `RESET`)

* sleep 2s

*     if **NOT** in DFU Mode
*         Cycle Reset 2x (Enable Katapult in MCU)
*         if Katapult Active
*             loadFlag = 3
*         else
*             ERROR - Unable to load firmware into Board Under Test's MCU

*     if (loadFlag & 4)  //  Board will be in DFU Mode
*         Flash `katapult.bin` using dfu-util
*         sleep 1s
*         Cycle Reset 2x (Enable Katapult in MCU)
*         sleep 1s

*     if NOT Katapult Active
*         ERROR - Unable to load firmware into Board Under Test's MCU

*     if (loadFlag & 2)  //  Flash DFU Enable in Option Bytes
*         Flash `SKR_Mini_E3_V3_DFU.bin` using Katapult
*         sleep 1s
*         Cycle Reset 2x (Enable Katapult in MCU)
*         sleep 1s

*     if NOT Katapult Active
*         ERROR - Unable to load firmware into Board Under Test's MCU

*     if (loadFlag & 1)  //  Flash Klipper Firmware
*         Flash `klipper.bin` using Katapult
*         sleep 1s
*         Cycle Reset 2x (Enable Katapult in MCU)
*         sleep 1s

* Show "KLIPPER START" Message

*     if `mcu.cfg` exists
*         erase `mcu.cfg`

* Using `ls /dev/serial/by-id` Create `mcu.cfg`

* `sudo service klipper start`

* sleep 5s // **NOTE:** This needs to be timed to understand how long it takes for Klipper to come up

*     for (i = 0; 5 > i; ++i)
*         if klipper "READY"
*             break
*         endif
*         sleep 1s
*         execute FIRMWARE_RESTART
*         sleep 5s // **NOTE:** This needs to be time to understand how long is required for Klipper to come up
*     if 5 <= i
*         ERROR - Klipper not coming up after MCU Flashed with Katapult, DFU Mode Enable, Klipper firmware

* Show "FUNCTIONAL TEST START" Message

* `TEST01:` Network Connections (Ping Internet Site to test Board Under Test's Ethernet Port using `sineosPING.sh`)
* `TEST02:` Read Power Input (`VINMON`) Level (Check Input Power Level)
* `TEST03:` Read MCU Temperature (MCU Presence Check)
* `TEST04:` Read Toolhead MCU Temperature (Toolhead Presence Check)
* `TEST05:` Ensure (`HEATER0` temp < 30C) && (`HEATER0` temp > 0C) (`HEATER0` thermistor Presence Check and at temperature appropriate for `HEATER0` functional test)
* `TEST06:` Ensure (`HEATER1` temp < 30C) && (`HEATER1` temp > 0C) (`HEATER1` thermistor Presence Check and at temperature appropriate for `HEATER1` functional test)
* `TEST07:` Set `HEATER0` to 40C (This is an operation that cannot pass or fail but given the label "TEST" so it can use the standard test macro formatting)
* `TEST08:` Set `HEATER1` to 40C (This is an operation that cannot pass or fail but given the label "TEST" so it can use the standard test macro formatting)
* `TEST09:` ADXL345 Presence Check
* `TEST10:` BLTouch Presence Check (Also Set Probe Position and check probe status)
* `TEST11:` `NEOPIXEL0` Presence Check (User Operator must confirm `NEOPIXEL0` has a red output.  `NEOPIXEL0` is turned off after test)
* `TEST12:` `NEOPIXEL1` Presence Check (User Operator must confirm `NEOPIXEL1` has a red output.  `NEOPIXEL1` is turned off after test)
* `TEST13:` `DSENSOR0` Functional Test (Operator to confirm that Yellow LED by Connector is lit)
* `TEST14:` `DSENSOR1` Functional Test (Operator to confirm that Yellow LED by Connector is lit)
* `TEST15:` `DSENSOR2` Functional Test (Operator to confirm that Yellow LED by Connector is lit)
* `TEST16:` `DSENSOR3` Functional Test (Operator to confirm that Yellow LED by Connector is lit)
* `TEST17:` `DSENSOR4` Functional Test (Operator to confirm that Yellow LED by Connector is lit)
* `TEST18:` 'FAN0' Operations Check (Operator to confirm Blue LED on Board Under Test is lit and LED strip is lit.  After confirmation `DSENSOR1` is no longer driven so that Blue LED and LED strip are off)
* `TEST19:` 'FAN1' Operations Check (Operator to confirm Blue LED on Board Under Test is lit and LED strip is lit.  After confirmation `DSENSOR1` is no longer driven so that Blue LED and LED strip are off)
* `TEST20:` 'FAN2' Operations Check (Operator to confirm Blue LED on Board Under Test is lit and LED strip is lit.  After confirmation `DSENSOR2` is no longer driven so that Blue LED and LED strip are off)
* `TEST21:` 'FAN3' Operations Check (Operator to confirm Blue LED on Board Under Test is lit and LED strip is lit.  After confirmation `DSENSOR3` is no longer driven so that Blue LED and LED strip are off)
* `TEST22:` 'G28 X` Test to check stepper movement and sensorless homing operation 
* `TEST23:` 'G28 Y` Test to check stepper movement and sensorless homing operation
* `TEST24:` 'G28 Z` Test to check stepper movement and sensorless homing operation
* `TEST25:` Functional Test of Inductive Sensor on Y-Axis stepper 
* `TEST26:` Functional Test of BLTouch on Z-Axis stepper
* `TEST27:` Ensure 'HEATER0` > 30C (When complete, set `HEATER0` to 0C)
* `TEST28:` Ensure 'HEATER1` > 30C (When complete, set `HEATER1` to 0C)

* Show "TEST COMPLETE" Message
* `NEOPIXEL0` and `NEOPIXEL1` set to output blue light

* Show "FIRMWARE SEALING" Message

* `sudo service klipper stop`
* sleep 2s
* Cycle Reset 2x (Enable Katapult in MCU - Assume that this will work and there's no need to check it's active)
* sleep 2s
* load `nada.bin`
* sleep 5s

* `sudo shutdown now`

## Raspberry Pi CM4 Configuration Instructions

### Setup Raspberry Pi CM4 Operating System

1. Assume Raspberry Pi CM4 as the KGP 4x2209 Klipper "Host"
   
3. Use 64GB+ Micro SD Card for loading OS for the Raspberry Pi

4. Start up the Raspberry Pi Imager

5. Insert Micro SD Card for use with Raspberry Pi Imager

6. In Raspberry Pi Imager's Main Page, specify:
   * `RASPBERRY PI 4` for "Raspberry Pi Device"
   * `RASPBERRY PI OS LITE (64-BIT)` for "Operating System"
   * `Micro SD Card for use with Raspberry Pi Imager` for "Storage"
  
![Raspberry Pi Imager Top Level](images/Raspberry_Pi_Imager_1.png)

7. Click "Next" in Raspberry Pi Imager

8. The "OS Customisation" Window comes up.  Make the following entries:
   * "Set hostname:" to `kgpft1`
   * "Set username and password"
      * "Username:" to `biqu`
      * "Password:" to `biqu`
   * Deselect "Configure wireless LAN"
   * "Set locale settings"
      * "Time zone:" to `America/Toronto`
      * "Keyboard layout:" to `us`

![Raspberry Pi Imager Specifying User and Network Parameters](images/Raspberry_Pi_Imager_2.png)

9. Click on `SAVE` in the "OS Customisation" Window and then click `Yes` to "apply OS customisation settings?"

10. Click on `Yes` to "Are you sure you want to continue?"

11. Wait for Micro SD Card to be configured

12. When finished, install the Micro SD Card into a `KGP 4x2209` board which has a Raspberry Pi CM4 installed

13. Connect the `KGP 4x2209` to an Ethernet internet connection
   
14. Apply power (ideally 24V) to the `KGP 4x2209`

15. Wait 5 minutes for first boot of the Raspberry Pi CM4

16. Using a computer which is connected to the same network as the Ethernet internet connection used by the `KGP 4x2209`:
    * Start up a terminal window (No need for PuTTY)
    * SSH into the board using `ssh biqu@kgpft1`
    * Enter `yes` if the question appears: "The authenticity of host 'kgpft1 ... Are you sure you want to continue connecting (yes/no/[fingerprint])?"
    * Enter the password `biqu`
      
![First Functional System Test SSH Login](images/First_FT_System_Login.png)

17. Enter `sudo apt update`

18. Enter `sudo apt upgrade -y`

### Enable CANBus Operation

* Following instructions found at: [Estoterical CANBus Guide](https://canbus.esoterical.online/Getting_Started.html)

19. `sudo systemctl enable systemd-networkd`

20. `sudo systemctl start systemd-networkd`

21. Check to see that networkd is operating using the command `systemctl | grep systemd-networkd`

![SSH of the Previous Three Commands](images/networkd_Running.png)

22. `sudo systemctl disable systemd-networkd-wait-online.service`

23. `echo -e 'SUBSYSTEM=="net", ACTION=="change|add", KERNEL=="can*"  ATTR{tx_queue_len}="128"' | sudo tee /etc/udev/rules.d/10-can.rules > /dev/null`

24. Check to see that the CAN rules were applied correctly using: `cat /etc/udev/rules.d/10-can.rules`

![CAN Rules Check Response](images/CAN_rules_check.png)

25. `echo -e "[Match]\nName=can*\n\n[CAN]\nBitRate=1M\nRestartSec=0.1s\n\n[Link]\nRequiredForOnline=no" | sudo tee /etc/systemd/network/25-can.network > /dev/null`

26. Check to see that the CAN Network Parameters were set correctly using: `cat /etc/systemd/network/25-can.network`

![CAN Network Check Response](images/CAN_network_check.png)

27. `sudo reboot now`

28. Wait 2 minutes for Raspberry Pi CM4 to reboot

29. `ssh biqu@kgpft1` and enter password `biqu` when prompted

### Download Necessary Files from GitHub

* Following instructions found at: [Pi My Life Up/raspberry-pi-gpio](https://pimylifeup.com/raspberry-pi-gpio/)

30. `sudo apt-get update && sudo apt-get install git -y`

### Download Python Raspberry Pi CM4/NewHat2 GPIO Utilities

* Following instructions found at: [Pi My Life Up/raspberry-pi-gpio](https://pimylifeup.com/raspberry-pi-gpio/)

31. Dowload python utilities:
    * `mkdir python`
    * `cd python`
    * `wget -O cycle38.py https://github.com/3dApothecary-xyz/FunctionalTest/blob/main/python/cycle38.py?raw=true`
    * `wget -O cycleRESET.py https://github.com/3dApothecary-xyz/FunctionalTest/blob/main/python/cycleRESET.py?raw=true`
    * `wget -O enableDFU.py https://github.com/3dApothecary-xyz/FunctionalTest/blob/main/python/enableDFU.py?raw=true`
    * `wget -O enableKatapult.py https://github.com/3dApothecary-xyz/FunctionalTest/blob/main/python/enableKatapult.py?raw=true`
    * `cd ~`
      
32. Test python operation with: `python python/cycle38.py`
    * Check Pin 38 on KGP 4x2209's Raspberry Pi 40Pin Connector with a DMM: Pin should be cycling between 0V and 3.3V every 2 Seconds

### Load Klipper using KIAUH

* Following instructions found at: [GitHub KIAUH Repository](https://github.com/dw-0/kiauh)

33. `git clone https://github.com/dw-0/kiauh.git`

34. `./kiauh/kiauh.sh`
    * If asked to try out KIAUH 6 enter `3` which is `3) Yes, remember my choice for next time`
    * Select `2) [Update]`
    * if Option `9) System` does NOT say `No upgrades available.` then:
    *       Select `9) System`
    *       Wait for System Updates to complete
    *       Select `B) << Back` to exit Update Panel
    *       Select `Q) Quit` to leave KIAUH
    *       `./kiauh/kiauh.sh` to restart KIAUH
    *       Select `2)[Update]` to return to KIAUH Update Screen
   
35. Select `B) << Back` to exit Update Panel
    * Select `1) [Install]` to go to Klipper Installation Panel
    * Select `1) [Klipper]` to Install Klipper on the Raspberry Pi CM4.  Select default options when prompted
    * Select `2) [Moonraker]` to Install Moonraker on the Raspberry Pi CM4.  Select default options when prompted
    * Select `3) [Mainsail]` to Install Mainsail on the Raspberry Pi CM4.  Select default options when prompted
    * Select `B << Back` to return to the main menu
    * Select `Q) Quit` to exit KIAUH

36. Check Klipper installation by loading the Mainsail webpage: `http://kgpft1`

37. Load Pyserial for Katapult operation using `sudo apt install python3 python3-serial -y`

![kgpft1 Mainsail Webpage](images/Mainsail_Webpage.png)

### Load Numpy for ADXL345 Testing

* Following instructions found at: [Measuring Resonances: Software Installation](https://www.klipper3d.org/Measuring_Resonances.html#software-installation)

38. `sudo apt install python3-numpy python3-matplotlib libatlas-base-dev libopenblas-dev -y`

39. `~/klippy-env/bin/pip install -v "numpy<1.26"`

40. Check Numpy installation using: `~/klippy-env/bin/python -c 'import numpy;'` - Result should be a simple return:

![Numpy Check - Simple Return](images/Numpy_Check.png)

### Install Klipper on Raspberry Pi CM4 to allow Klipper to access the CM4's GPIO pins

* Following instructions found at: [Klipper: Install the RC Script](https://www.klipper3d.org/RPi_microcontroller.html?h=raspb#install-the-rc-script)

41. `sudo cp klipper/scripts/klipper-mcu.service /etc/systemd/system/`

42. `sudo systemctl enable klipper-mcu.service`

43. `cd klipper`

44. `make menuconfig` and select "Linux process" for "MCU Architecture":

![Make Linux Process](images/Make_Linux_Process.png)

45. Enter `Q` and then `Y` to quit and save the settings.

46. `make clean`

47. `make`

48. `sudo service klipper stop`

49. `make flash`

50. `sudo service klipper start`

### Load Katapult

* Following instructions found at: [GitHub Katapult Repository](https://github.com/Arksine/katapult)

51. `git clone https://github.com/Arksine/katapult`

### Make Firmware Images

52. Download Premade Firmare Images
    * `mkdir bin`
    * `cd bin`
    * `wget -O nada.bin https://github.com/3dApothecary-xyz/FunctionalTest/blob/main/bin/nada.bin?raw=true`
    * `wget -O KGP_4x2209_DFU.bin https://github.com/3dApothecary-xyz/FunctionalTest/blob/main/bin/KGP_4x2209_DFU.bin?raw=true`
    * `cd ~`

**NOTE:** `KGP_4x2209_DFU.bin` was modeled on `MINI_E3_V3_DFU.bin`

53. Make `katapult.bin` for Board Under Test 
    * `cd katapult`
    * `make menuconfig` - Match settings with screen shot below and enter `Q` followed by `Y` to save
![Katapult menuconfig settings](images/katapult_menuconfig.png)
    * `make clean`
    * `make`
    * `cp out/katapult.bin ~/bin`
    * `cd ~`

54. Make `klipper.bin` for Board Under Test 
    * `cd klipper`
    * `make menuconfig` - Match settings with screen shot below and enter `Q` followed by `Y` to save
![Katapult menuconfig settings](images/klipper_menuconfig_2.png)
    * `make clean`
    * `make`
    * `cp out/klipper.bin ~/bin`
    * `cd ~`

55. `chmod 777 bin/*.bin`

### Flash MCU on KGP 4x2209

56. Stop Klipper while Flashing the KGP 4x2209 using `sudo service klipper stop`
    
57. `lsusb` and check to see that there is a device with "ID" `0483:df11`:

![KGP 4x2209 Initial DFU Mode Check](images/KGP_4x2209_DFU_Mode.png)

58. Flash Katapult into the KGP 4x2209 board using the command: `sudo dfu-util -a 0 -D ~/katapult/out/katapult.bin --dfuse-address 0x08000000:force:mass-erase:leave -d 0483:df11`

59. Check for Katapult active by verifying the flashing LED on KGP 4x2209 and use the `ls /dev/serial/by-id` to check if has a USB address using `ls /dev/serial/by-id`

![Katapult Active](images/Katapult_Active.png)

60. Using the USB Serial Address found in the Previous Step, Flash the DFU Mode Enable firmware using the command `python3 ~/katapult/scripts/flashtool.py -f ~/bin/KGP_4x2209_DFU.bin -d /dev/serial/by-id/usb-katapult_stm32g0b1xx_1A003E001050505933383420-if00` (which is using the USB address found previously)

61. This will result in the DFU repeatedly Flashing three times quickly followed by one lone flash

62. `python ~/python/enableKatapult.py` which will enable Katapult and the DFU LED will flash on and off regularly
    
63. Using the USB Serial Address found in the Previous Steps, Flash Klipper using the command `python3 ~/katapult/scripts/flashtool.py -f ~/bin/klipper.bin -d /dev/serial/by-id/usb-katapult_stm32g0b1xx_1A003E001050505933383420-if00` (which is using the USB address found previously)

64. Check to see that Klipper was installed using the command 'ip -s -d link show can0` with the expected result:

![Klipper Flashed into KGP 4x2209](images/CAN_Link_Active.png)

65. Get the CAN UUID using the command: `~/klippy-env/bin/python ~/klipper/scripts/canbus_query.py can0` with the expected result:

![Klipper CAN Bus UUID](images/CAN_UUID.png)

66. Create an `mcu.cfg` file using the command: `printf "[mcu]\ncanbus_uuid: fc86d6d0415a" > ~/printer_data/config/mcu.cfg` with the correct UUID for the KGP 4x2209 that was found previously

67. `sudo service klipper start`

68. Copy the `printer.cfg` file from this GitHub repository in the `configs` folder into the `http://kgpft1` Mainsail "MACHINE" web page.

69. Comment out the `[include toolhead.cfg]` and `[temperature_sensor toolhead_temp]` statements in the `printer.cfg` in `http://kgpft1` for testing.

70. Click on "SAVE AND RESTART` and Klipper should come up with the screen:

![Klipper No CAN](images/Klipper_No_CAN.png)

### Flash Toolhead Controller

71. On EBB42, Put in `120R` and `VBUS` Jumpers

72. Connect EBB42 to KGP 4x209 using USB C to USB A Cable

73. Press the `BOOT` Button followed by cycling `RST` to put the EBB42 into DFU Mode as shown in the following image:

![EBB42 Topside](images/EBB42_topside.png)

74. Check that the Toolhead Controller is in DFU Mode by using the command `lsusb` which should produce the result:

![Toolhead Controller DFU Mode](images/Toolhead_Controller_DFU_Mode.png)

75. Move to the Katapult Folder using the command `cd ~/katapult`

76. Configure Katapult for the Toolhead Controller using `make menuconfig` with the Paramters:

![Toolhead Controller Katapult Parameters](images/Toolhead_Katapult_Menuconfig.png)

77. Save menuconfig paramters by entering `Q` and then `Y`
   
78. `make clean`

79. `make`

80. Flash the Toolhead Controller with Katapult using the command: `sudo dfu-util -a 0 -D ~/katapult/out/katapult.bin --dfuse-address 0x08000000:force:mass-erase:leave -d 0483:df11`

81. Power Down the KGP 4x2209 after `sudo shutdown now` has executed

82. With Power off, unplug the Toolhead Controller from the KGP 4x2209 USB port and reattach it using the CAN connection

83. Power Up, wait for the Raspberry Pi CM4 to come up and login using SSH

84. Check that the Toolhead Controller is active and properly wired using the command `~/klippy-env/bin/python ~/klipper/scripts/canbus_query.py can0` which should return:

![Toolhead Control CAN Connection](images/Toolhead_Controller_Initial_CAN_Connection.png)

85. `cd ~/klipper`

86. Configure Klipper for the Toolhead Controller using `make menuconfig` with the Parameters:

![Toolhead Controller Klipper Paramters](images/Toolhead_Klipper_Menuconfig.png)

87. Save menuconfig paramters by entering `Q` and then `Y`
   
88. `make clean`

89. `make`

90. `sudo service klipper stop`

91. `python3 ~/katapult/scripts/flashtool.py -i can0 -q` which should return something like:

![Toolhead Controller Katapult UUID](images/Toolhead_Controller_Klipper_Paramters.png)

92. Flash the Toolhead Controller using `python3 ~/katapult/scripts/flashtool.py -i can0 -f ~/klipper/out/klipper.bin -u 821165b91308` using the UUID found in the previous step

93. Check for the CAN UUID using `python3 ~/katapult/scripts/flashtool.py -i can0 -q` which will return the Klipper CAN UUID:

![Toolhead Controller CAN UUID](images/Toolhead_Controller_CAN_UUID.png)

94. Using the CAN UUID found in the previous step, create the `toolhead.cfg` file using the command `printf "[mcu toolhead]\ncanbus_uuid: 821165b91308" > ~/printer_data/config/toolhead.cfg`

95. Edit `printer.cfg` on the Mainsail webpage and Remove comments on the `[include toolhead.cfg]` and `[temperature_sensor toolhead_temp]` statements

96. `sudo service klipper start` and Klipper should start up as:

![Test SD Card All Setup](images/Test_SD_Card_All_Setup.png)
