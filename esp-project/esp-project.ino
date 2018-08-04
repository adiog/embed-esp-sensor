#include "Arduino.h"
#include "WiFiUdp.h"
#include <WiFiClient.h>
#include <ESP8266WiFi.h>


WiFiUDP udp;

const char* ssid = "ssid";
const char* password = "pass";

char host[16] = "192.168.0.101";
const int port = 1234;

const char * message = "hello world\n";
const int messageSize = 12;

const int messageInterval = 1000;

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
}

void loop()
{
    udp.beginPacket(host, port);
    udp.write(message, messageSize);
    udp.endPacket();

    delay(messageInterval);
}

