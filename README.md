# KGP 4x2209 FunctionalTest

![KGP 4x2209 Image](images/KGP_4x2209_3D.png)

## Raspberry Pi CM4 Configuration Instructions

1. Assume Raspberry Pi CM4 as the KGP 4x2209 Klipper "Host"
   
3. Use 64GB+ Micro SD Card for loading OS for the Raspberry Pi

4. Start up the Raspberry Pi Imager

5. Insert Micro SD Card for use with Raspberry Pi Imager

6. In Raspberry Pi Imager's Main Page, Select:
   * "Raspberry Pi Device" -> "RASPBERRY PI 4"
   * "Operating System" -> "RASPBERRY PI OS LITE (64-BIT)"
   * "Storage" -> Micro SD Card for use with Raspberry Pi Imager
  
![Raspberry Pi Imager Top Level](images/Raspberry_Pi_Imager_1.png)

7. Click "Next" in Raspberry Pi Imager

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
*         endif
*     endif

*     if (loadFlag & 4)  //  Board will be in DFU Mode
*         Flash `katapult.bin` using dfu-util
*         sleep 1s
*         Cycle Reset 2x (Enable Katapult in MCU)
*         sleep 1s
*     endif

*     if NOT Katapult Active
*         ERROR - Unable to load firmware into Board Under Test's MCU
*     endif

*     if (loadFlag & 2)  //  Flash DFU Enable in Option Bytes
*         Flash `SKR_Mini_E3_V3_DFU.bin` using Katapult
*         sleep 1s
*         Cycle Reset 2x (Enable Katapult in MCU)
*         sleep 1s
*     endif

*     if NOT Katapult Active
*         ERROR - Unable to load firmware into Board Under Test's MCU
*     endif

*     if (loadFlag & 1)  //  Flash Klipper Firmware
*         Flash `klipper.bin` using Katapult
*         sleep 1s
*         Cycle Reset 2x (Enable Katapult in MCU)
*         sleep 1s
*     endif

* Show "KLIPPER START" Message

*     if `mcu.cfg` exists
*         erase `mcu.cfg`
*     endif

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
*     endfor
*     if 5 <= i
*         ERROR - Klipper not coming up after MCU Flashed with Katapult, DFU Mode Enable, Klipper firmware
*     endif

* Show "FUNCTIONAL TEST START" Message

* TEST01: Network Connections (Ping Internet Site to test Board Under Test's Ethernet Port using `sineosPING.sh`)
* TEST02: Power Input Level (Check Input Power Level)
* TEST03: MCU Temperature (Read MCU Temperature as MCU Presence Check)
* TEST04: Toolhead MCU Temperature (Toolhead Presence Check)
