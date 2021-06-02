/* HC-05 interfacing with NodeMCU ESP8266
    Author: Circuit Digest(circuitdigest.com)
*/
#include <SoftwareSerial.h>
#include "Servo.h"

//Servo servo_360;
Servo servo_180;
//int servo_360_pin = D1;  // for ESP8266 360 microcontroller
int servo_180_pin = D2;  // for ESP8266 180 microcontroller

int hc05_rx = D4;
int hc05_tx = D3;

int angle = 0;
int rotation_velocity = 0;
 
SoftwareSerial btSerial(hc05_rx, hc05_tx); // Rx,Tx

unsigned long previousMillis = 0;  // millis instaed of delay
const long interval = 500;  // blink after ecery 500ms

int input_index = 0;
char input[8] = "\0";

void setup() {
  servo_180.attach(servo_180_pin, 771, 2740);
  delay(1000);
  Serial.begin(9600);     
  btSerial.begin(9600);     // bluetooth module baudrate
  servo_180.write(0);  // initialized angle
}

void loop() {
  while (btSerial.available() > 0) {
    input[input_index] = btSerial.read();
    input_index++;
  }

  if (input[0] && input_index > (input[0] - '0')) {
    input[input[0] - '0' + 1] = NULL;
    int new_angle = atoi(input + 1);
    int angle_diff = new_angle < angle ? -1 : 1;
    input_index = 0;
    input[0] = NULL;
      
    Serial.print("new_angle: ");
    Serial.println(new_angle);
  
    Serial.print("angle: ");
    Serial.println(angle);
  
    Serial.print("angle_diff: ");
    Serial.println(angle_diff);
  
    Serial.println();
  
    while (angle != new_angle) {
      angle += angle_diff;
      servo_180.write(angle);
      delay(rotation_velocity);
    }
  }
}
