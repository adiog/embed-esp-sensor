# ESP8266 project scaffold:
Repo contains arduino SDK (via submodules: use git clone --recursive while cloning or after git submodule update --init --recursive).
Script build.sh compiles and flashes the project.
If needed flash the firmware with ```esp/firmware/flash_firmware.sh```.
Use ```esp/filesystem/flash_filesystem.sh``` to flash the folder ```esp-project/data``` onto esp8266.

## Latest version of board manager for arduino SDK:
```http://arduino.esp8266.com/stable/package_esp8266com_index.json```

## Pinout
![esp8266 pinout](https://raw.githubusercontent.com/adiog/embed-esp-project/master/pinout.png "ESP8266 NodeMCU v3 Lolin Pinout")

