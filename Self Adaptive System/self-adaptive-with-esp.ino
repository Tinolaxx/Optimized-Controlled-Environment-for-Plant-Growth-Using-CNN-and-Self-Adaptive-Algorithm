#include <DHT11.h>
#include <Wire.h> 
#include <LiquidCrystal_I2C.h>
#include <SoftwareSerial.h>

#define RX 2 // TX of ESP8266 connected to Arduino pin 2
#define TX 3 // RX of ESP8266 connected to Arduino pin 3

String WIFI_SSID = ""; // WIFI Name
String WIFI_PASS = ""; // WIFI Password
String API = ""; // Write API Key
String HOST = "api.thingspeak.com";
String PORT = "80";

bool isConnected = false; // Track ESP8266 WiFi connection state
SoftwareSerial esp8266(RX, TX); 

LiquidCrystal_I2C lcd(0x27, 20, 4);

DHT11 dht11(5); // DHT & fan
int fan = 6; 

int capacitive_sensor1 = A0; // Soil moisture sensor
int capacitive_sensor2 = A1; 
int capacitive_sensor3 = A2;
int capacitive_sensor4 = A3;
int output_value1; 
int output_value2;
int output_value3;
int output_value4;

int pump1 = 8; // Digital pins for pump
int pump2 = 9; 
int pump3 = 10;
int pump4 = 11;
int threshold = 25; // Threshold for soil moisture to trigger pump
int temp_threshold = 28;

bool pump1_state = true; // HIGH = OFF, LOW = ON
bool pump2_state = true;
bool pump3_state = true;
bool pump4_state = true;

unsigned long lastDisplayUpdate = 0;
unsigned long lastThingSpeakUpdate = 0;

void setup() {
  Serial.begin(9600);
  esp8266.begin(9600);
  lcd.init();
  lcd.backlight();
  pinMode(capacitive_sensor1, INPUT);  
  pinMode(capacitive_sensor2, INPUT);  
  pinMode(capacitive_sensor3, INPUT);  
  pinMode(capacitive_sensor4, INPUT);  
  pinMode(pump1, OUTPUT);
  pinMode(pump2, OUTPUT);
  pinMode(pump3, OUTPUT);
  pinMode(pump4, OUTPUT);
  pinMode(fan, OUTPUT); 
  digitalWrite(pump1, HIGH); // Pumps OFF
  digitalWrite(pump2, HIGH); 
  digitalWrite(pump3, HIGH);
  digitalWrite(pump4, HIGH);  
  digitalWrite(fan, HIGH); // Fan OFF
  delay(1000); 

  lcd.setCursor(3, 1); 
  lcd.print("The system is");
  lcd.setCursor(4, 2); 
  lcd.print("starting...");
  Serial.println("\nThe system is starting...");
  sendCommand("AT", 5, "OK");
  sendCommand("AT+CWMODE=1", 5, "OK");
  connectWiFi();
  lcd.clear();
}

void loop() {
  checkConnection(); // Check WiFi connection status

  int temperature = 0;
  int humidity = 0;
  int result = dht11.readTemperatureHumidity(temperature, humidity);

  output_value1 = map(analogRead(capacitive_sensor1), 550, 0, 0, 100);
  output_value2 = map(analogRead(capacitive_sensor2), 550, 0, 0, 100);
  output_value3 = map(analogRead(capacitive_sensor3), 550, 0, 0, 100);
  output_value4 = map(analogRead(capacitive_sensor4), 550, 0, 0, 100);
  unsigned long currentMillis = millis();
  if (currentMillis - lastDisplayUpdate >= 5000) { // Update every 5 seconds
  lastDisplayUpdate = currentMillis;
  displaySoilMoistureLevels(temperature, humidity);   // Display soil moisture levels and temperature/humidity on LCD
  controlFan(temperature);
  controlPumps();
  }
  // Sending data to ThingSpeak
  if (currentMillis - lastThingSpeakUpdate >= 20000) { // Update data in thingspeak every 20 seconds
  lastThingSpeakUpdate = currentMillis;
  if (isConnected) {
    String getData = "GET /update?api_key=" + API + "&field1=" + String(temperature) + "&field2=" + String(humidity) + "&field3=" + String(output_value1) +  "&field4=" + String(output_value2) +
      "&field5=" + String(output_value3) + "&field6=" + String(output_value4);
    
    if (sendToThingSpeak(getData)) {                     
      Serial.println("✅ Data sent to ThingSpeak!");
      lcd.setCursor(11, 3);
      lcd.print("IOT:ON ");
    } else {
      Serial.println("❌ Error: Failed to send data to ThingSpeak.");
      lcd.setCursor(11, 3);
      lcd.print("IOT:OFF");
    }
    delay(30000); 
  }
  }
}

// Display soil moisture and temperature data on the LCD
void displaySoilMoistureLevels(int temperature, int humidity) {
  Serial.println("\n====================================");
  Serial.println("        SOIL MOISTURE LEVELS        ");
  Serial.println("====================================");
  Serial.println("           Sensor 1: " + String(output_value1) + "%");
  Serial.println("           Sensor 2: " + String(output_value2) + "%");
  Serial.println("           Sensor 3: " + String(output_value3) + "%");
  Serial.println("           Sensor 4: " + String(output_value4) + "%");
  Serial.println("====================================");

  lcd.setCursor(1, 0); 
  lcd.print("SML1:");
  if (output_value1 < 10) { lcd.print("0"); }
  lcd.print(output_value1);
  lcd.print("%");

  lcd.setCursor(1, 1); 
  lcd.print("SML2:");
  if (output_value2 < 10) { lcd.print("0"); }
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

  lcd.setCursor(1, 2); 
  lcd.print("TEMP:" + String(temperature) + (char)223 + "C");
  lcd.setCursor(11, 2); 
  lcd.print("RH:" + String(humidity) + "%");
}

// Control the fan based on temperature
void controlFan(int temperature) {
  lcd.setCursor(1, 3); 
  lcd.print("FAN:");
  if (temperature < temp_threshold) {
    digitalWrite(fan, LOW);
    lcd.print("ON");
    Serial.println("Fan ON");
  } else {
    digitalWrite(fan, HIGH);
    lcd.print("OFF");
    Serial.println("Fan OFF");
  }
}

void controlPumps() {
  bool new_pump1_state = (output_value1 >= threshold);
  bool new_pump2_state = (output_value2 >= threshold);
  bool new_pump3_state = (output_value3 >= threshold);
  bool new_pump4_state = (output_value4 >= threshold);

  if (new_pump1_state != pump1_state) {
    pump1_state = new_pump1_state;
    digitalWrite(pump1, pump1_state ? HIGH : LOW);
  }
  if (new_pump2_state != pump2_state) {
    pump2_state = new_pump2_state;
    digitalWrite(pump2, pump2_state ? HIGH : LOW);
  }
  if (new_pump3_state != pump3_state) {
    pump3_state = new_pump3_state;
    digitalWrite(pump3, pump3_state ? HIGH : LOW);
  }
  if (new_pump4_state != pump4_state) {
    pump4_state = new_pump4_state;
    digitalWrite(pump4, pump4_state ? HIGH : LOW);
  }
}

void connectWiFi() { // Function to connect to WiFi
  if (sendCommand("AT+CWJAP=\"" + WIFI_SSID + "\",\"" + WIFI_PASS + "\"", 20, "OK")) {
    Serial.println("✅ WiFi Connected!");
    isConnected = true;
  } else {
    Serial.println("❌ Error: WiFi connection failed.");
    isConnected = false;
  }
}

void checkConnection() { // Function to check if the ESP8266 is connected
  sendCommand("AT+CWJAP?", 5, "OK"); // Check connection status

  bool newConnectionState = !esp8266ResponseContains("No AP");

  if (newConnectionState != isConnected) {
    isConnected = newConnectionState;
    Serial.println(isConnected ? "✅ WiFi Connected!" : "❌ WiFi Disconnected!");
  }
}

bool sendToThingSpeak(String data) { // Function to send data to ThingSpeak
  if (!sendCommand("AT+CIPMUX=1", 5, "OK")) return false;
  if (!sendCommand("AT+CIPSTART=0,\"TCP\",\"" + HOST + "\"," + PORT, 15, "OK")) return false;
  if (!sendCommand("AT+CIPSEND=0," + String(data.length() + 4), 4, ">")) return false;

  esp8266.println(data);
  delay(1500);

  return sendCommand("AT+CIPCLOSE=0", 5, "OK");
}

bool sendCommand(String command, int maxTime, String expectedResponse) { // Function to send AT commands to the ESP8266
  esp8266.println(command);
  long startTime = millis();

  while (millis() - startTime < maxTime * 1000) {
    if (esp8266ResponseContains(expectedResponse)) {
      return true;
    }
  }
  return false; // Command failed
}

bool esp8266ResponseContains(String keyword) { // Function to check if ESP8266 response contains expected keyword
  String response = "";
  long startTime = millis();

  while (millis() - startTime < 5000) { 
    while (esp8266.available()) {
      char c = esp8266.read();
      response += c;
    }
    if (response.indexOf(keyword) != -1) {
      return true; 
    }
  }
  return false; // Response not found
}
