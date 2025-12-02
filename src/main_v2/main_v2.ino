#include <LSM6DS3.h>
#include <Wire.h>
#include <ArduinoBLE.h>

// ============================================================================
// Global Variables & Constants
// ============================================================================

// IMU Instance
LSM6DS3 myIMU(I2C_MODE, 0x6A);

// BLE Service & Characteristic
// UUIDs from reference code
BLEService imuService("0769bb8e-b496-4fdd-b53b-87462ff423d0");
BLECharacteristic imuDataChar("8ee82f5b-76c7-4170-8f49-fff786257090", BLERead | BLENotify, 30);

// Voltage Reading
const int VBAT_ENABLE_PIN = P0_14; // Low to enable, High to disable
const int VBAT_READ_PIN = A0;
unsigned long lastVoltageReadTime = 0;
const unsigned long VOLTAGE_READ_INTERVAL = 10000; // 10 seconds

// Voltage Filter (Exponential Moving Average)
// alpha = 0.1 means new value has 10% weight, old value has 90% weight.
// This provides significant smoothing.
float voltageFiltered = 0.0f;
const float VOLTAGE_FILTER_ALPHA = 0.1f; 
bool firstVoltageRead = true;

// BLE Data Transmission
unsigned long lastBleSendTime = 0;
const unsigned long BLE_SEND_INTERVAL = 20; // 20ms = 50Hz

// ============================================================================
// Setup
// ============================================================================
void setup() {
  // Serial
  Serial.begin(9600);
  // while (!Serial); // Optional: Wait for Serial if debugging is critical

  // 1. Initialize Voltage Pins
  pinMode(VBAT_ENABLE_PIN, OUTPUT);
  digitalWrite(VBAT_ENABLE_PIN, HIGH); // Disable initially

  // 2. Initialize IMU
  // Configure settings BEFORE begin
  myIMU.settings.accelRange = 16;      // 16g
  myIMU.settings.accelSampleRate = 416; // Higher sample rate for smooth data
  myIMU.settings.accelBandWidth = 100;
  
  myIMU.settings.gyroRange = 2000;     // 2000dps
  myIMU.settings.gyroSampleRate = 416;
  myIMU.settings.gyroBandWidth = 100;

  if (myIMU.begin() != 0) {
    Serial.println("IMU Device error");
  } else {
    Serial.println("IMU Device OK!");
  }

  // 3. Initialize BLE
  if (!BLE.begin()) {
    Serial.println("starting BLE failed!");
    while (1);
  }

  BLE.setLocalName("SmartRacket");
  // BLE.setAdvertisedService(imuService); // Removed to save space in advertising packet for Local Name
  imuService.addCharacteristic(imuDataChar);
  BLE.addService(imuService);
  
  // Initialize value
  uint8_t initialValue[30] = {0};
  imuDataChar.setValue(initialValue, 30);

  BLE.advertise();
  Serial.println("Bluetooth device active, waiting for connections...");
  
  // Initial Voltage Read
  readAndFilterVoltage();
}

// ============================================================================
// Loop
// ============================================================================
void loop() {
  // Handle BLE events
  BLE.poll();
  
  unsigned long now = millis();

  // 1. Voltage Reading (Every 10 seconds)
  if (now - lastVoltageReadTime >= VOLTAGE_READ_INTERVAL) {
    readAndFilterVoltage();
    lastVoltageReadTime = now;
  }

  // 2. BLE Data Transmission (Every 20ms)
  if (now - lastBleSendTime >= BLE_SEND_INTERVAL) {
    // Only send if connected (optional, but good practice to save power/cpu if needed, 
    // though BLE.poll() handles connection state)
    BLEDevice central = BLE.central();
    
    // Read IMU Data
    // Note: We read every loop cycle or every send interval. 
    // Reading at send interval is sufficient for 50Hz.
    float accX = myIMU.readFloatAccelX();
    float accY = myIMU.readFloatAccelY();
    float accZ = myIMU.readFloatAccelZ();
    float gyroX = myIMU.readFloatGyroX();
    float gyroY = myIMU.readFloatGyroY();
    float gyroZ = myIMU.readFloatGyroZ();

    // Print to Serial (for debugging/Python visualizer)
    // We keep the format for the Python script
    Serial.print("Timestamp:");
    Serial.print(now);
    Serial.print(", AccX:");
    Serial.print(accX, 4);
    Serial.print(", AccY:");
    Serial.print(accY, 4);
    Serial.print(", AccZ:");
    Serial.print(accZ, 4);
    Serial.print(", GyroX:");
    Serial.print(gyroX, 4);
    Serial.print(", GyroY:");
    Serial.print(gyroY, 4);
    Serial.print(", GyroZ:");
    Serial.println(gyroZ, 4);

    if (central && central.connected()) {
        // Prepare Data Packet (30 bytes)
        uint8_t buffer[30];
        
        // 0-3: Timestamp (4 bytes)
        uint32_t ts = (uint32_t)now;
        memcpy(buffer, &ts, 4);
        
        // 4-15: Accel (3 * 4 bytes)
        memcpy(buffer + 4, &accX, 4);
        memcpy(buffer + 8, &accY, 4);
        memcpy(buffer + 12, &accZ, 4);
        
        // 16-27: Gyro (3 * 4 bytes)
        memcpy(buffer + 16, &gyroX, 4);
        memcpy(buffer + 20, &gyroY, 4);
        memcpy(buffer + 24, &gyroZ, 4);
        
        // 28-29: Voltage (2 bytes)
        // Convert filtered float voltage back to raw-like uint16 for compatibility
        // or send as is if the receiver expects raw ADC.
        // The reference code sends 'voltageRaw' which is 12-bit ADC value.
        // We should send the filtered value converted back to that scale or similar.
        // Reference: voltage = raw * calibration / 4096. 
        // Let's send the filtered 'raw' equivalent.
        // Since we filter the raw value directly in readAndFilterVoltage, we can just cast it.
        uint16_t voltageToSend = (uint16_t)voltageFiltered;
        memcpy(buffer + 28, &voltageToSend, 2);
        
        imuDataChar.writeValue(buffer, 30);
    }
    
    lastBleSendTime = now;
  }
}

// ============================================================================
// Helper Functions
// ============================================================================
void readAndFilterVoltage() {
  // Enable Voltage Divider
  digitalWrite(VBAT_ENABLE_PIN, LOW);
  delayMicroseconds(500); // Wait for settle
  
  // Read ADC (10-bit by default on Arduino, 0-1023)
  // Reference code converts to 12-bit (0-4095) by multiplying by 4.
  // We will do the same to match the data format expectation.
  int raw = analogRead(VBAT_READ_PIN);
  int raw12bit = raw * 4;
  
  // Disable Voltage Divider
  digitalWrite(VBAT_ENABLE_PIN, HIGH);
  
  // Filter
  if (firstVoltageRead) {
    voltageFiltered = (float)raw12bit;
    firstVoltageRead = false;
  } else {
    // EMA Filter
    voltageFiltered = (VOLTAGE_FILTER_ALPHA * (float)raw12bit) + ((1.0f - VOLTAGE_FILTER_ALPHA) * voltageFiltered);
  }
  
  // Debug Output
  // Serial.print("Voltage Raw (12bit): "); Serial.print(raw12bit);
  // Serial.print(" Filtered: "); Serial.println(voltageFiltered);
}
