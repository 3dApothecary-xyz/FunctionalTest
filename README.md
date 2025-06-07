# KGP 4x2209 FunctionalTest

![KGP 4x2209 Image](images/KGP_4x2209_3D.png)

## Raspberry Pi CM4 Configuration Instructions

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

19. 


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

* `TEST01:` Network Connections (Ping Internet Site to test Board Under Test's Ethernet Port using `sineosPING.sh`)
* `TEST02:` Power Input (`VINMON`) Level (Check Input Power Level)
* `TEST03:` MCU Temperature (Read MCU Temperature as MCU Presence Check)
* `TEST04:` Toolhead MCU Temperature (Toolhead Presence Check)
* `TEST05:` `heater0` temp < 30C (`heater0` thermistor Presence Check)
* `TEST06:` `heater1` temp < 30C (`heater1` thermistor Presence Check)
* `TEST07:` ADXL345 Presence Check
* `TEST08:` BLTouch Presence Check (Set Probe Position)
* `TEST09:` `neopixel0` Presence Check (User Operator must confirm operation)
* `TEST10:` `neopixel1` Presence Check (User Operator must confirm operation)
* 
