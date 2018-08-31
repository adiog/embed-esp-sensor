// This file is a part of embed-esp-sensor project.
// Copyright 2018 Aleksander Gajewski <adiog@brainfuck.pl>.

#include <Arduino.h>
#include <ESP8266WiFi.h>
#include <MPU9250.h>
#include <MPU9250Helper.h>
#include <WiFiClient.h>
#include <WiFiUdp.h>


const int SPI_PIN = 5;
const int sampleRateDivider = SAMPLE_RATE_50HZ;

const char* ssid = "ssid";
const char* password = "password";

const char host[16] = "192.168.0.101";
const int port = 1234;


WiFiUDP udp;
MPU9250 IMU(SPI, SPI_PIN);


inline void writeFloat(uint8_t* target, float value)
{
    *reinterpret_cast<float*>(target) = value;
}

inline void writeSensor(uint8_t* buffer)
{
    writeFloat(&buffer[0], IMU.getAccelX_mss());
    writeFloat(&buffer[4], IMU.getAccelY_mss());
    writeFloat(&buffer[8], IMU.getAccelZ_mss());
    writeFloat(&buffer[12], IMU.getGyroX_rads());
    writeFloat(&buffer[16], IMU.getGyroY_rads());
    writeFloat(&buffer[20], IMU.getGyroZ_rads());
    writeFloat(&buffer[24], IMU.getMagX_uT());
    writeFloat(&buffer[28], IMU.getMagY_uT());
    writeFloat(&buffer[32], IMU.getMagZ_uT());
}

inline void send(uint8_t* buffer)
{
    udp.beginPacket(host, port);
    udp.write(buffer, 36);
    udp.endPacket();
}

void handler(void)
{
    uint8_t buffer[36];
    IMU.readSensor();
    writeSensor(buffer);
    send(buffer);
}


void setup(void)
{
    Serial.begin(115200);
    Serial.println("Connecting to Wifi..");

    WiFi.mode(WIFI_STA);
    WiFi.begin(ssid, password);

    while (WiFi.status() != WL_CONNECTED)
    {
        delay(500);
        Serial.print(".");
    }

    Serial.println(".. WiFi connected.");
    Serial.println("");

    Serial.print("Connected to: ");
    Serial.println(ssid);
    Serial.print("IP address: ");
    Serial.println(WiFi.localIP());
    Serial.println("");

    Serial.println("Connecting to IMU..");
    int status = IMU.begin();
    if (status < 0)
    {
        Serial.println("IMU connection failed.");
        Serial.print("Status: ");
        Serial.println(status);
        return;
    }
    Serial.println(".. IMU connected.");

    Serial.println("Setting Sample Rate Divider..");
    IMU.setSrd(sampleRateDivider);

    Serial.println("Enabling IMU Interrupt..");
    IMU.enableDataReadyInterrupt();

    Serial.println("Attaching IMU Interrup..");
    attachInterrupt(digitalPinToInterrupt(4), handler, RISING);
}

void loop()
{
}

