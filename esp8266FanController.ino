/* HC-05 interfacing with NodeMCU ESP8266
    Author: Circuit Digest(circuitdigest.com)
*/
#include <SoftwareSerial.h>
#include "Servo.h"

Servo servo_360;
Servo servo_180;
int servo_360_pin = D1;  // for ESP8266 360 microcontroller
int servo_180_pin = D2;  // for ESP8266 180 microcontroller

int hc05_rx = D4;
int hc05_tx = D3;

int angle = 0;
int rotation_degree = 12;
 
SoftwareSerial btSerial(hc05_rx, hc05_tx); // Rx,Tx

unsigned long previousMillis = 0;  // millis instaed of delay
const long interval = 500;  // blink after ecery 500ms

void setup() {
  servo_360.attach(servo_360_pin);
  servo_180.attach(servo_180_pin);
  Serial.println("Finishing configing Servos\n");
  delay(1000);
  Serial.begin(9600);     
  btSerial.begin(9600);     // bluetooth module baudrate
  Serial.println("Finishing configing Serials\n"); 
  Serial.println("Starting");
}

void loop() {
  if (btSerial.available() > 0) {    // check if bluetooth module sends some data to esp8266
    int new_angle = int(btSerial.read());  // read the data from HC-05
    Serial.println("I got a message: ");
    Serial.println(new_angle);
    int angle_diff = new_angle - angle;
    int num_iterations = angle_diff / rotation_degree;
    int leftover_angle = angle_diff % rotation_degree;
    for (int i = 0; i < num_iterations; i++)
    {
      angle += rotation_degree;
      servo_360.write(angle);
      servo_180.write(180-angle);
    }

    if (leftover_angle)
    {
      angle += leftover_angle;
      servo_360.write(angle);
      servo_180.write(180-angle);
    }
  }
}
