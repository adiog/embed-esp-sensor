# ESP8266 + MPU9250 + udp

## ESP8266 project setup:
* Repo contains arduino SDK (via submodules: use ```git clone --recursive``` while cloning or after ```git submodule update --init --recursive```).
* Script build.sh compiles and flashes the project.
* If needed flash the firmware with ```esp/firmware/flash_firmware.sh```.
* Use ```esp/filesystem/flash_filesystem.sh``` to flash the folder ```esp-project/data``` onto esp8266.

## Latest version of board manager for arduino SDK:
```http://arduino.esp8266.com/stable/package_esp8266com_index.json```

## Pinout
![esp8266 nodemcu pinout](https://raw.githubusercontent.com/adiog/embed-esp-sensor/master/docs/esp8266-nodemcu-pinout.png "ESP8266 NodeMCU v3 Lolin Pinout")
![esp8266 wemos d1 mini pinout](https://raw.githubusercontent.com/adiog/embed-esp-sensor/master/docs/esp8266-wemos-d1-mini-pinout.png "ESP8266 Wemos D1 Mini Pinout")

## IMU Device
![MPU9250](https://raw.githubusercontent.com/adiog/embed-esp-sensor/master/docs/mpu9250.jpg "MPU9250")

## Wiring
|           | ESP8266   | MPU9250  |
| --------- |:---------:|:--------:|
| 5V        | VCC       | VCC      |
| GND       | GND       | GND      |
| SPI/CLK   | D5/14     | SCL/SCLK |
| SPI/MOSI  | D7/13     | SDA/SDI  |
| SPI/MISO  | D6/12     | ADO/SDO  |
| SPI/CS    | D1/5      | NCS      |
| INT       | D2/4      | INT      |

## Real photo of ESP8266+MPU9250
![Real photo of ESP8266+MPU9250](https://raw.githubusercontent.com/adiog/embed-esp-sensor/master/docs/esp8266-wemos-mpu9250-photo.jpg "Real photo of ESP8266+MPU9250")

