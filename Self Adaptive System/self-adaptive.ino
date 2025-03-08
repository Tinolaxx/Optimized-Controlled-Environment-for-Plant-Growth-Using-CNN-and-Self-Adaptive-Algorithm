#include <DHT11.h>
#include <Wire.h> 
#include <LiquidCrystal_I2C.h>
LiquidCrystal_I2C lcd(0x27, 20, 4);

DHT11 dht11(5); //DHT & fan
int fan = 6; 

int capacitive_sensor1 = A0; //signal from the soil moisture sensor
int capacitive_sensor2 = A1;
int capacitive_sensor3 = A2;
int capacitive_sensor4 = A3;
int output_value1; //value of the soil moisture sensor
int output_value2;
int output_value3;
int output_value4;

int pump1 = 8; //digital pin where the relay is plugged in
int pump2 = 9;    
int pump3 = 10;    
int pump4 = 11;    
int threshold = 25;  //threshold value to trigger pump
int temp_threshold = 28;

bool pump1_state = true; // HIGH = OFF, LOW = ON
bool pump2_state = true;
bool pump3_state = true;
bool pump4_state = true;

void setup() {
  Serial.begin(9600);
  pinMode(capacitive_sensor1, INPUT);  
  pinMode(capacitive_sensor2, INPUT);
  pinMode(capacitive_sensor3, INPUT);
  pinMode(capacitive_sensor4, INPUT);
  pinMode(pump1, OUTPUT);
  pinMode(pump2, OUTPUT);
  pinMode(pump3, OUTPUT);
  pinMode(pump4, OUTPUT);
  pinMode(fan, OUTPUT);
  Serial.println("\nThe system is starting...");
  delay(1000);  //1 second delay
  digitalWrite(pump1, HIGH); //pumps are off
  digitalWrite(pump2, HIGH);
  digitalWrite(pump3, HIGH);
  digitalWrite(pump4, HIGH);

  lcd.init();
  lcd.backlight();
  }

void loop() {
  int temperature = 0;
  int humidity = 0;
  int result = dht11.readTemperatureHumidity(temperature, humidity);

  output_value1 = map(analogRead(capacitive_sensor1), 550, 0, 0, 100);
  output_value2 = map(analogRead(capacitive_sensor2), 550, 0, 0, 100);
  output_value3 = map(analogRead(capacitive_sensor3), 550, 0, 0, 100);
  output_value4 = map(analogRead(capacitive_sensor4), 550, 0, 0, 100);
  Serial.println("\n====================================");
  Serial.println("        SOIL MOISTURE LEVELS          ");
  Serial.println("====================================");
  Serial.println("           Sensor 1: " + String(output_value1) + "%");
  Serial.println("           Sensor 2: " + String(output_value2) + "%");
  Serial.println("           Sensor 3: " + String(output_value3) + "%");
  Serial.println("           Sensor 4: " + String(output_value4) + "%");
  Serial.println("====================================");

  lcd.setCursor(1,0); 
  lcd.print("SML1:");
  if (output_value1 < 10) {
  lcd.print("0"); 
  }
  lcd.print(output_value1);
  lcd.print("%");

  lcd.setCursor(1,1); 
  lcd.print("SML2:");
  if (output_value2 < 10) {
  lcd.print("0"); 
  }
  lcd.print(output_value2);
  lcd.print("%");

  lcd.setCursor(11,0); 
  lcd.print("SML3:");
  if (output_value3 < 10) {
  lcd.print("0"); 
  }
  lcd.print(output_value3);
  lcd.print("%");

  lcd.setCursor(11,1); 
  lcd.print("SML4:");
  if (output_value4 < 10) {
  lcd.print("0"); 
  }
  lcd.print(output_value4);
  lcd.print("%");

  lcd.setCursor(1,2); 
  lcd.print("TEMP:" + String(temperature) + (char)223 + "C");
  lcd.setCursor(11,2); 
  lcd.print("RH:" + String(humidity) + "%");

  lcd.setCursor(7,3); 
  lcd.print("FAN:");
  lcd.print((temperature < temp_threshold) ? "ON" : "OFF");

  if (result == 0) {
        Serial.print("Temperature: ");
        Serial.print(temperature);
        Serial.print(" °C\tHumidity: ");
        Serial.print(humidity);
        Serial.println(" %");
    if (temperature < temp_threshold){
        digitalWrite(fan, LOW);
        Serial.println("Fan ON");
      }
    else {
        digitalWrite(fan, HIGH);
        Serial.println("Fan OFF");
      }
    } 
    else {
        // Print error message based on the error code.
        Serial.println(DHT11::getErrorString(result));
    }

  delay(3000); 
  bool new_pump1_state = (output_value1 >= threshold); 
  bool new_pump2_state = (output_value2 >= threshold);
  bool new_pump3_state = (output_value3 >= threshold);
  bool new_pump4_state = (output_value4 >= threshold);

  // Pump 1
  if (new_pump1_state != pump1_state) { 
    pump1_state = new_pump1_state;
    digitalWrite(pump1, pump1_state ? HIGH : LOW);
    Serial.println(pump1_state ? "Pump OFF for sensor 1" : "Pump ON for sensor 1");
  }

  // Pump 2
  if (new_pump2_state != pump2_state) { 
    pump2_state = new_pump2_state;
    digitalWrite(pump2, pump2_state ? HIGH : LOW);
    Serial.println(pump2_state ? "Pump OFF for sensor 2" : "Pump ON for sensor 2");
  }

  // Pump 3
  if (new_pump3_state != pump3_state) { 
    pump3_state = new_pump3_state;
    digitalWrite(pump3, pump3_state ? HIGH : LOW);
    Serial.println(pump3_state ? "Pump OFF for sensor 3" : "Pump ON for sensor 3");
  }

  // Pump 4
  if (new_pump4_state != pump4_state) { 
    pump4_state = new_pump4_state;
    digitalWrite(pump4, pump4_state ? HIGH : LOW);
    Serial.println(pump4_state ? "Pump OFF for sensor 4" : "Pump ON for sensor 4");
  }

}