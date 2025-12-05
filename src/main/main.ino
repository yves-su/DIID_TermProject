/*****************************************************************************/
//  SmartRacket IMU BLE 傳輸系統
//  Hardware:      Seeed XIAO nRF52840 Sense + LSM6DS3 6軸IMU感測器
//	Arduino IDE:   Arduino-1.8.19+
//	Author:	       DIID Term Project Team
//	Date: 	       2024
//	Version:       v2.0 (BLE版本)
//
//  Description:   智慧羽毛球拍IMU感測器系統
//                 - 讀取LSM6DS3加速度計和陀螺儀資料
//                 - 透過Bluetooth Low Energy (BLE) 即時傳輸資料
//                 - 包含IMU校正、電壓監控、充電模式控制
//                 - 支援50Hz高頻率資料傳輸
//
//  BLE服務架構:
//  - 服務UUID: 0769bb8e-b496-4fdd-b53b-87462ff423d0
//  - 特徵UUID: 8ee82f5b-76c7-4170-8f49-fff786257090
//  - 資料格式: 30 bytes (時間戳4 + 加速度12 + 陀螺儀12 + 電壓2)
//
//  硬體連接:
//  - LSM6DS3: I2C (SDA, SCL) 地址 0x6A
//  - 電壓監控: P0.31 (AIN7 / PIN_VBAT) - XIAO nRF52840 Sense 內建電池電壓分壓電路
//  - 電壓啟用: P0.14 (VBAT_ENABLE) - 設為 LOW 啟用分壓電路，HIGH 關閉省電
//  - 充電控制: P0_13 數位輸出
//  - 電池: 501230, 3.7V, 150mAh
//
//  Note:          LSM6DS3函式庫相容性修正 (LSM6DS3.cpp line 108):
//                 #if !defined(ARDUINO_ARCH_MBED)
//                     SPI.setBitOrder(MSBFIRST);
//                     SPI.setDataMode(SPI_MODE3);
//                     SPI.setClockDivider(SPI_CLOCK_DIV16);
//                 #endif
//
/*******************************************************************************/

// ============================================================================
// 函式庫引入
// ============================================================================
#include "LSM6DS3.h"      // LSM6DS3 6軸IMU感測器函式庫
#include "Wire.h"         // I2C通訊函式庫
#include "ArduinoBLE.h"   // Bluetooth Low Energy函式庫

// ============================================================================
// 硬體物件初始化
// ============================================================================
// 建立LSM6DS3感測器實例，使用I2C通訊模式，設備地址0x6A
LSM6DS3 myIMU(I2C_MODE, 0x6A);

// ============================================================================
// BLE服務與特徵定義
// ============================================================================
// 自訂IMU資料服務，使用UUID: 0769bb8e-b496-4fdd-b53b-87462ff423d0
BLEService imuService("0769bb8e-b496-4fdd-b53b-87462ff423d0");

// IMU資料特徵，支援讀取和通知功能，資料長度30 bytes
// UUID: 8ee82f5b-76c7-4170-8f49-fff786257090
BLECharacteristic imuDataChar("8ee82f5b-76c7-4170-8f49-fff786257090", 
                              BLERead | BLENotify, 30);

// 時間同步特徵值，支援寫入功能，用於接收手機時間
// UUID: a1b2c3d4-e5f6-4789-a012-3456789abcde
BLECharacteristic timeSyncChar("a1b2c3d4-e5f6-4789-a012-3456789abcde", BLEWrite, 4);

// ============================================================================
// IMU校正相關變數
// ============================================================================
bool imuReady = false;           // IMU感測器是否準備就緒
bool calibrationDone = false;    // 是否已完成校正

// 加速度計偏移量 (用於校正靜止狀態下的零點漂移)
float offsetAX = 0.0f, offsetAY = 0.0f, offsetAZ = 0.0f;

// 陀螺儀偏移量 (用於校正靜止狀態下的零點漂移)
float offsetGX = 0.0f, offsetGY = 0.0f, offsetGZ = 0.0f;

// ============================================================================
// 時間同步相關變數
// ============================================================================
uint32_t timeBaseMs = 0;              // 基準時間（毫秒，從手機接收，表示從當天 00:00:00 開始的毫秒數）
unsigned long mcuTimeBaseMs = 0;       // MCU 連線時的 millis()
bool timeSynced = false;               // 是否已同步時間

// ============================================================================
// 電源管理相關變數
// ============================================================================
// 電池規格：501230, 3.7V, 150mAh
// 正常工作電壓範圍：3.2V (低電量警告) ~ 4.2V (滿電)
// 充電模式切換點：3.5V (低於3.5V使用高電流充電，高於3.5V使用低電流充電)
unsigned long lastVoltageReadTime = -10000;  // 上次電壓讀取時間 (初始值設為10秒前)
unsigned long lastVoltageUpdateTime = 0;     // 上次電壓更新時間
int16_t voltageRaw = 0;                       // 原始電壓讀取值 (12-bit等效值，用於BLE傳輸)
int16_t voltageRawCached = 0;                // 緩存的電壓原始值（每10秒更新一次）
const unsigned long VOLTAGE_READ_INTERVAL = 10000;  // 電壓讀取間隔：10秒
const int VOLTAGE_SAMPLE_COUNT = 30;         // 每次讀取30筆取平均
bool isHighCurrentCharging = false;          // 是否為高電流充電模式

#define LEDR        (11u)
#define LEDB        (12u)
#define LEDG        (13u)

// ============================================================================
// 系統初始化函數
// ============================================================================
void setup() {
    // ------------------------------------------------------------------------
    // 串列通訊初始化
    // ------------------------------------------------------------------------
    Serial.begin(9600);        // 設定串列通訊速率為9600 bps
    //while (!Serial);           // 等待串列埠準備就緒 (USB連接)
    
    // ------------------------------------------------------------------------
    // I2C通訊初始化
    // ------------------------------------------------------------------------
    Wire.begin();              // 初始化I2C通訊
    Wire.setClock(400000);     // 設定I2C時鐘頻率為400kHz (高速模式)
    
    // ------------------------------------------------------------------------
    // IMU感測器初始化
    // ------------------------------------------------------------------------
    Serial.println("Initializing LSM6DS3 IMU...");
    
    // 設定IMU參數（在begin()之前設定）
    // 根據README.md規格：加速度計 ±16G，陀螺儀 ±2000 dps
    myIMU.settings.accelRange = 16;      // 加速度計量程：±16G
    myIMU.settings.gyroRange = 2000;     // 陀螺儀量程：±2000 dps
    myIMU.settings.accelSampleRate = 416; // 加速度計輸出頻率：416Hz
    myIMU.settings.gyroSampleRate = 416;  // 陀螺儀輸出頻率：416Hz
    myIMU.settings.accelBandWidth = 100;  // 加速度計帶寬：100Hz
    myIMU.settings.gyroBandWidth = 400;   // 陀螺儀帶寬：400Hz
    
    if (myIMU.begin() != 0) {
        // IMU初始化失敗
        imuReady = false;
        Serial.println("Device error");
        while(1);              // 停止執行，等待重啟
    } else {
        // IMU初始化成功
        imuReady = true;
        Serial.println("IMU initialized successfully");
        Serial.print("Accelerometer range: ±"); Serial.print(myIMU.settings.accelRange); Serial.println("G");
        Serial.print("Gyroscope range: ±"); Serial.print(myIMU.settings.gyroRange); Serial.println(" dps");
        Serial.print("Accelerometer ODR: "); Serial.print(myIMU.settings.accelSampleRate); Serial.println(" Hz");
        Serial.print("Gyroscope ODR: "); Serial.print(myIMU.settings.gyroSampleRate); Serial.println(" Hz");
        
        // 驗證暫存器設定是否正確寫入
        debugIMURegisters();
        
        Serial.println("timestamp,aX,aY,aZ,gX,gY,gZ,voltage");  // 輸出CSV標題
    }

    // ------------------------------------------------------------------------
    // LED 初始化
    // ------------------------------------------------------------------------
    pinMode(LEDR, OUTPUT);
    pinMode(LEDB, OUTPUT);
    pinMode(LEDG, OUTPUT);
    
    // 設定電池電壓監控腳位
    // P0.14 (VBAT_ENABLE): 設為 LOW 啟用內建分壓電路，HIGH 關閉省電
    pinMode(P0_14, OUTPUT);
    digitalWrite(P0_14, HIGH);  // 初始狀態：關閉分壓電路（省電）
    
    // ------------------------------------------------------------------------
    // BLE藍牙初始化
    // ------------------------------------------------------------------------
    if (!BLE.begin()) {
        Serial.println("BLE initialization failed!");
        while(1);              // 停止執行，等待重啟
    }
    
    // 設定BLE服務和特徵
    imuService.addCharacteristic(imuDataChar);  // 將特徵加入服務
    imuService.addCharacteristic(timeSyncChar); // 將時間同步特徵加入服務
    BLE.addService(imuService);                 // 將服務加入BLE
    imuDataChar.setValue((uint8_t*)"", 0);      // 設定特徵初始值為空
    timeSyncChar.setValue((uint8_t*)"", 0);      // 設定時間同步特徵初始值為空
    
    // 設定時間同步特徵值的寫入回調
    timeSyncChar.setEventHandler(BLEWritten, handleTimeSync);
    
    // 設定BLE設備名稱和廣播服務
    BLE.setLocalName("SmartRacket");            // 設定設備名稱為SmartRacket
    BLE.setAdvertisedService(imuService);       // 設定廣播的服務
    
    // 設定BLE參數以提高連接穩定性
    BLE.setConnectable(true);                   // 允許設備被連接
    BLE.setAdvertisingInterval(100);            // 設定廣播間隔為100ms
    
    // 開始BLE廣播
    BLE.advertise();
    
    // 輸出初始化完成訊息
    Serial.println("BLE advertising started...");
    Serial.println("Device name: SmartRacket");
    Serial.println("Waiting for connection...");
}

// ============================================================================
// 時間同步處理函數
// ============================================================================
void handleTimeSync(BLEDevice central, BLECharacteristic characteristic) {
    // 讀取手機發送的時間（4 bytes, uint32_t, Little-Endian）
    // 時間格式：從當天 00:00:00 開始的毫秒數
    const uint8_t* data = characteristic.value();
    int length = characteristic.valueLength();
    
    if (length == 4) {
        // 解析時間（Little-Endian）
        uint32_t phoneTimeMs = 0;
        memcpy(&phoneTimeMs, data, 4);
        
        // 記錄基準時間和 MCU 當前時間
        timeBaseMs = phoneTimeMs;
        mcuTimeBaseMs = millis();
        timeSynced = true;
        
        Serial.print("時間同步成功: 基準時間 = ");
        Serial.print(timeBaseMs);
        Serial.print(" ms (從當天 00:00:00 開始), MCU millis() = ");
        Serial.println(mcuTimeBaseMs);
    } else {
        Serial.print("時間同步失敗: 資料長度錯誤 (");
        Serial.print(length);
        Serial.println(" bytes, 需要 4 bytes)");
    }
}

// ============================================================================
// 計算從當天 00:00:00 開始的毫秒數（時分秒毫秒格式）
// ============================================================================
uint32_t getTimeOfDayMs() {
    if (!timeSynced) {
        // 尚未同步，使用 millis()（向下兼容）
        return (uint32_t)millis();
    }
    
    // 計算從基準點開始經過的毫秒數
    unsigned long elapsed = millis() - mcuTimeBaseMs;
    
    // 計算當前時間（從當天 00:00:00 開始的毫秒數）
    uint32_t currentTimeMs = timeBaseMs + elapsed;
    
    // 確保不超過一天的毫秒數（86,400,000 ms）
    const uint32_t MS_PER_DAY = 24UL * 60UL * 60UL * 1000UL;  // 86,400,000
    if (currentTimeMs >= MS_PER_DAY) {
        // 如果超過一天，取模（理論上不會發生，但安全起見）
        currentTimeMs = currentTimeMs % MS_PER_DAY;
        Serial.println("警告: 時間超過一天，已取模");
    }
    
    return currentTimeMs;
}

// ============================================================================
// 主程式迴圈
// ============================================================================
void loop() {
    // ------------------------------------------------------------------------
    // 點亮藍色代表程序啟動
    // ------------------------------------------------------------------------
    digitalWrite(LEDB, HIGH);
    // ------------------------------------------------------------------------
    // 電源管理檢查
    // ------------------------------------------------------------------------
    //checkVoltageAndSleep();    // 檢查電池電壓，必要時進入省電模式
    
    // ------------------------------------------------------------------------
    // BLE事件處理
    // ------------------------------------------------------------------------
    BLE.poll();                // 必須持續呼叫來處理BLE事件 (連接、斷線、資料傳輸等)
    
    // ------------------------------------------------------------------------
    // 檢查BLE連接狀態
    // ------------------------------------------------------------------------
    BLEDevice central = BLE.central();  // 取得連接的中央設備 (手機/電腦)
    
    // 靜態變數：用於控制資料輸出頻率（無論是否連接）
    static unsigned long lastDataOutputTime = 0;
    const unsigned long dataOutputInterval = 20;  // 20ms = 50Hz
    
    // 檢查是否到達資料輸出時間（無論是否連接BLE）
    unsigned long now = millis();
    if ((long)(now - lastDataOutputTime) >= 0) {
        // --------------------------------------------------------------------
        // 讀取IMU感測器資料（無論是否連接BLE）
        // --------------------------------------------------------------------
        uint32_t timestamp = millis();  // 時間戳記
        
        // 初始化感測器資料變數
        float aX = 0, aY = 0, aZ = 0;  // 加速度 (X, Y, Z軸)
        float gX = 0, gY = 0, gZ = 0;  // 角速度 (X, Y, Z軸)
        
        if (imuReady) {
            // 讀取原始感測器資料並減去校正偏移量
            aX = myIMU.readFloatAccelX() - offsetAX;  // 加速度X軸
            aY = myIMU.readFloatAccelY() - offsetAY;  // 加速度Y軸
            aZ = myIMU.readFloatAccelZ() - offsetAZ;  // 加速度Z軸
            gX = myIMU.readFloatGyroX() - offsetGX;   // 角速度X軸
            gY = myIMU.readFloatGyroY() - offsetGY;   // 角速度Y軸
            gZ = myIMU.readFloatGyroZ() - offsetGZ;   // 角速度Z軸
        }
        
        // --------------------------------------------------------------------
        // 讀取電池電壓（使用 XIAO nRF52840 Sense 內建分壓電路）
        // --------------------------------------------------------------------
        // 1. 啟用分壓電路（P0.14 = LOW）
        digitalWrite(P0_14, LOW);
        delayMicroseconds(500);  // 等待電壓穩定（約 500µs）
        
        // 2. 讀取 ADC 值（P0.31 / AIN7 / PIN_VBAT）
        // 注意：需要確認 A0 是否對應 P0.31
        // 如果 A0 不對應，可能需要使用其他腳位編號或直接配置 SAADC
        voltageRaw = analogRead(A0);
        
        // 3. 關閉分壓電路以省電（P0.14 = HIGH）
        digitalWrite(P0_14, HIGH);
        
        // 確保 voltageRaw 在有效範圍內
        // 注意：Arduino analogRead() 通常返回 10-bit (0-1023)
        // 但 nRF52840 SAADC 實際是 12-bit (0-4095)
        // 需要將 10-bit 值轉換為 12-bit 等效值
        if (voltageRaw < 0) voltageRaw = 0;
        
        // 轉換 10-bit 到 12-bit：12bit_value = 10bit_value * 4
        // 例如：400 (10-bit) → 1600 (12-bit)
        if (voltageRaw <= 1023) {
            voltageRaw = voltageRaw * 4;  // 10-bit 轉 12-bit
        }
        
        // 記錄轉換後的原始值（用於除錯）
        // Serial.print(" [ADC原始="); Serial.print(voltageRaw/4); Serial.print(", 轉換後="); Serial.print(voltageRaw); Serial.print("]");
        
        // --------------------------------------------------------------------
        // 串列埠輸出（簡化：只輸出六軸資料和電壓）
        // --------------------------------------------------------------------
        // 計算實際電池電壓
        // 校準調整：根據當前讀值重新校準
        // 如果讀到的原始值是 523 (10-bit) → 2092 (12-bit)，實際電壓應該是 4.14V
        // 計算：4.14 = 2092 * K / 4096，得到 K ≈ 8.11
        float calibrationConstant = 8.11f;  // 根據當前讀值重新校準（2025-01-24）
        float voltage = (float)voltageRaw * calibrationConstant / 4096.0f;
        
        // 輸出格式：timestamp,aX,aY,aZ,gX,gY,gZ,voltage
        // 使用 getTimeOfDayMs() 取得時間（連線後使用同步時間，未連線使用 millis()）
        uint32_t outputTimestamp = getTimeOfDayMs();
        Serial.print(outputTimestamp);  // 時間戳記（從當天 00:00:00 開始的毫秒數，或 millis()）
        Serial.print(',');
        Serial.print(aX, 8);  // 加速度 X
        Serial.print(',');
        Serial.print(aY, 8);  // 加速度 Y
        Serial.print(',');
        Serial.print(aZ, 8);  // 加速度 Z
        Serial.print(',');
        Serial.print(gX, 8);  // 角速度 X
        Serial.print(',');
        Serial.print(gY, 8);  // 角速度 Y
        Serial.print(',');
        Serial.print(gZ, 8);  // 角速度 Z
        Serial.print(',');
        Serial.println(voltage, 2);  // 電壓（2位小數）
        
        // 更新輸出時間
        lastDataOutputTime += dataOutputInterval;
    }
    
    if (central && central.connected()) {
        // ====================================================================
        // BLE已連接 - 開始IMU資料傳輸
        // ====================================================================
        
        // 首次連接時進行IMU校正
        if (!calibrationDone) {
            calibrateIMUOffsets();  // 校正IMU偏移量
            calibrationDone = true;
        }
        
        static bool firstConnection = true;
        if (firstConnection) {
            Serial.println("Connected to central");
            // 初始化電壓緩存值（立即讀取一次，如果失敗則重試）
            int retryCount = 0;
            while (retryCount < 3 && voltageRawCached == 0) {
                voltageRawCached = readVoltageAverage();
                if (voltageRawCached == 0) {
                    retryCount++;
                    delay(100);  // 等待100ms後重試
                }
            }
            if (voltageRawCached == 0) {
                Serial.println("Warning: Failed to read voltage, using default value");
                // 如果仍然失敗，使用一個合理的預設值（約3.7V對應的ADC值）
                // 3.7V ≈ 1400 (12-bit ADC值，使用校準常數11.68計算)
                voltageRawCached = 1400;
            }
            lastVoltageUpdateTime = now;
            firstConnection = false;
        }
        
        // 設定資料傳輸參數
        const unsigned long interval = 20;  // 傳輸間隔20ms = 50Hz
        static unsigned long lastSendTime = 0;
        
        // 檢查是否到達BLE傳輸時間
        if ((long)(now - lastSendTime) >= 0) {
            // --------------------------------------------------------------------
            // 資料封包化 (30 bytes二進位格式)
            // --------------------------------------------------------------------
            uint8_t buffer[30];  // 資料緩衝區
            
            // 重新讀取最新資料（確保資料是最新的）
            // 計算從當天 00:00:00 開始的毫秒數（時分秒毫秒格式）
            uint32_t timestamp = getTimeOfDayMs();
            float aX = 0, aY = 0, aZ = 0;
            float gX = 0, gY = 0, gZ = 0;
            
            if (imuReady) {
                aX = myIMU.readFloatAccelX() - offsetAX;
                aY = myIMU.readFloatAccelY() - offsetAY;
                aZ = myIMU.readFloatAccelZ() - offsetAZ;
                gX = myIMU.readFloatGyroX() - offsetGX;
                gY = myIMU.readFloatGyroY() - offsetGY;
                gZ = myIMU.readFloatGyroZ() - offsetGZ;
            }
            
            // 檢查是否需要更新電壓讀數（每10秒更新一次）
            // 或者如果緩存值為0（首次讀取失敗），立即重試
            if ((now - lastVoltageUpdateTime >= VOLTAGE_READ_INTERVAL) || (voltageRawCached == 0)) {
                // 讀取30筆電壓並取平均
                int16_t newVoltage = readVoltageAverage();
                // 只有當讀取成功（非0）時才更新緩存值
                if (newVoltage > 0) {
                    voltageRawCached = newVoltage;
                    Serial.print("Voltage updated: ");
                    Serial.print((float)newVoltage * 11.68f / 4096.0f, 3);
                    Serial.println("V");
                } else {
                    // 如果讀取失敗，記錄警告但保留舊值
                    Serial.println("Warning: Voltage read failed, keeping cached value");
                }
                lastVoltageUpdateTime = now;
            }
            
            // 使用緩存的電壓值
            voltageRaw = voltageRawCached;
            
            // 封包結構: [時間戳4] + [加速度12] + [陀螺儀12] + [電壓2] = 30 bytes
            memcpy(buffer, &timestamp, 4);        // 0-3: 時間戳 (4 bytes)
            memcpy(buffer + 4, &aX, 4);           // 4-7: 加速度X (4 bytes)
            memcpy(buffer + 8, &aY, 4);           // 8-11: 加速度Y (4 bytes)
            memcpy(buffer + 12, &aZ, 4);          // 12-15: 加速度Z (4 bytes)
            memcpy(buffer + 16, &gX, 4);          // 16-19: 角速度X (4 bytes)
            memcpy(buffer + 20, &gY, 4);          // 20-23: 角速度Y (4 bytes)
            memcpy(buffer + 24, &gZ, 4);          // 24-27: 角速度Z (4 bytes)
            
            // 將 voltageRaw 轉換為 uint16_t 並以 Little-Endian 格式發送
            uint16_t voltageRawUint = (uint16_t)voltageRaw;
            memcpy(buffer + 28, &voltageRawUint, 2);  // 28-29: 電壓 (2 bytes, Little-Endian)
            
            // --------------------------------------------------------------------
            // 透過BLE傳送資料
            // --------------------------------------------------------------------
            bool success = imuDataChar.writeValue(buffer, 30);  // 發送30 bytes資料
            if (!success) {
                Serial.println("BLE發送失敗!");
            }
            
            // 更新傳輸時間
            lastSendTime += interval;
        }
        
    } else {
        // ====================================================================
        // 沒有BLE連接 - 省電模式（但仍會輸出串列資料）
        // ====================================================================
        static bool firstDisconnection = true;
        if (firstDisconnection) {
            Serial.println("Disconnected from central");
            // 重置時間同步狀態（下次連線時需要重新同步）
            timeSynced = false;
            timeBaseMs = 0;
            mcuTimeBaseMs = 0;
            firstDisconnection = false;
        }
        delay(10);  // 減少延遲，讓串列輸出更順暢
    }
}

// ============================================================================
// IMU暫存器調試函數（驗證設定是否正確寫入）
// ============================================================================
void debugIMURegisters() {
    Serial.println("\n=== IMU Register Debug ===");
    
    uint8_t data;
    uint8_t deviceAddress = 0x6A;  // LSM6DS3 I2C 地址
    
    // 檢查加速度計暫存器 (CTRL1_XL - 0x10)
    Wire.beginTransmission(deviceAddress);
    Wire.write(0x10);
    if (Wire.endTransmission() == 0) {
        Wire.requestFrom(deviceAddress, (uint8_t)1);
        if (Wire.available()) {
            data = Wire.read();
            Serial.print("Register CTRL1_XL (0x10): 0x");
            if (data < 0x10) Serial.print("0");
            Serial.println(data, HEX);
            
            // 解析 FS_XL[1:0] (位元 3:2)
            uint8_t fs_xl = (data >> 2) & 0x03;
            Serial.print("  FS_XL[1:0] = ");
            Serial.print(fs_xl, BIN);
            Serial.print(" -> ");
            switch(fs_xl) {
                case 0: Serial.println("±2g (預設)"); break;
                case 1: Serial.println("±16g (目標)"); break;
                case 2: Serial.println("±4g"); break;
                case 3: Serial.println("±8g"); break;
            }
            
            // 檢查是否為目標設定 (±16g = 01)
            if (fs_xl != 1) {
                Serial.println("  ⚠️ WARNING: 加速度計量程設定失敗！實際為預設值 ±2g");
                Serial.println("  這會導致讀數被錯誤放大 8 倍！");
            } else {
                Serial.println("  ✓ 加速度計量程設定正確：±16g");
            }
        } else {
            Serial.println("  ❌ 無法讀取 CTRL1_XL 暫存器（無回應）");
        }
    } else {
        Serial.println("  ❌ 無法讀取 CTRL1_XL 暫存器（I2C 錯誤）");
    }
    
    // 檢查陀螺儀暫存器 (CTRL2_G - 0x11)
    Wire.beginTransmission(deviceAddress);
    Wire.write(0x11);
    if (Wire.endTransmission() == 0) {
        Wire.requestFrom(deviceAddress, (uint8_t)1);
        if (Wire.available()) {
            data = Wire.read();
            Serial.print("Register CTRL2_G (0x11): 0x");
            if (data < 0x10) Serial.print("0");
            Serial.println(data, HEX);
            
            // 檢查 FS_125 位元 (位元 1)
            bool fs_125 = (data >> 1) & 0x01;
            if (fs_125) {
                Serial.println("  FS_125 = 1 -> ±125dps (專用模式)");
            } else {
                // 解析 FS_G[3:2] (位元 3:2)
                uint8_t fs_g = (data >> 2) & 0x03;
                Serial.print("  FS_G[3:2] = ");
                Serial.print(fs_g, BIN);
                Serial.print(" -> ");
                switch(fs_g) {
                    case 0: Serial.println("±250dps (預設)"); break;
                    case 1: Serial.println("±500dps"); break;
                    case 2: Serial.println("±1000dps"); break;
                    case 3: Serial.println("±2000dps (目標)"); break;
                }
                
                // 檢查是否為目標設定 (±2000dps = 11)
                if (fs_g != 3) {
                    Serial.println("  ⚠️ WARNING: 陀螺儀量程設定失敗！實際為預設值 ±250dps");
                    Serial.println("  這會導致讀數被錯誤放大 8 倍！");
                } else {
                    Serial.println("  ✓ 陀螺儀量程設定正確：±2000dps");
                }
            }
        } else {
            Serial.println("  ❌ 無法讀取 CTRL2_G 暫存器（無回應）");
        }
    } else {
        Serial.println("  ❌ 無法讀取 CTRL2_G 暫存器（I2C 錯誤）");
    }
    
    Serial.println("==========================\n");
}

// ============================================================================
// IMU感測器校正函數（修正版：只校正陀螺儀，不校正加速度計）
// ============================================================================
void calibrateIMUOffsets() {
    Serial.println("Starting IMU calibration...");
    Serial.println("注意：此版本只校正陀螺儀，不校正加速度計");
    Serial.println("原因：無法保證開機時球拍是水平放置的");
    
    // 初始化累加變數
    float sumAX = 0, sumAY = 0, sumAZ = 0;  // 加速度累加（僅用於顯示，不作為offset）
    float sumGX = 0, sumGY = 0, sumGZ = 0;  // 陀螺儀累加
    
    // 進行100次採樣來計算偏移量
    for (int i = 0; i < 100; i++) {
        // 累加原始感測器讀值
        sumAX += myIMU.readFloatAccelX();  // 加速度X軸（僅用於顯示）
        sumAY += myIMU.readFloatAccelY();  // 加速度Y軸（僅用於顯示）
        sumAZ += myIMU.readFloatAccelZ();  // 加速度Z軸（僅用於顯示）
        sumGX += myIMU.readFloatGyroX();   // 陀螺儀X軸
        sumGY += myIMU.readFloatGyroY();   // 陀螺儀Y軸
        sumGZ += myIMU.readFloatGyroZ();   // 陀螺儀Z軸
        
        delay(10);  // 10ms間隔採樣
    }
    
    // 計算平均偏移量
    // 加速度計：不進行offset校正（因為無法保證開機時是水平放置的）
    // 重力向量是姿態解算的重要依據，不應該被當作Offset扣掉
    offsetAX = 0.0f;  // 加速度X軸：不校正
    offsetAY = 0.0f;  // 加速度Y軸：不校正
    offsetAZ = 0.0f;  // 加速度Z軸：不校正（不扣除重力）
    
    // 陀螺儀：一定要校正，因為它會漂移
    offsetGX = sumGX / 100.0;  // 陀螺儀X軸偏移
    offsetGY = sumGY / 100.0;  // 陀螺儀Y軸偏移
    offsetGZ = sumGZ / 100.0;  // 陀螺儀Z軸偏移
    
    // 顯示校正結果
    Serial.println("Calibration results:");
    Serial.print("  Accelerometer (僅顯示，不作為offset): ");
    Serial.print("X="); Serial.print(sumAX / 100.0, 3);
    Serial.print(" Y="); Serial.print(sumAY / 100.0, 3);
    Serial.print(" Z="); Serial.println(sumAZ / 100.0, 3);
    Serial.print("  Gyroscope offsets: ");
    Serial.print("X="); Serial.print(offsetGX, 3);
    Serial.print(" Y="); Serial.print(offsetGY, 3);
    Serial.print(" Z="); Serial.println(offsetGZ, 3);
    
    Serial.println("IMU calibration completed");
}

// ============================================================================
// 電壓讀取函數（讀取30筆取平均）
// ============================================================================
/**
 * 讀取30筆電壓值並計算平均值
 * 每次讀取前後都會啟用/關閉分壓電路以省電
 * @return 平均後的12-bit等效電壓原始值
 */
int16_t readVoltageAverage() {
    unsigned long sum = 0;
    int validSamples = 0;
    
    // 啟用分壓電路（P0.14 = LOW）
    digitalWrite(P0_14, LOW);
    delayMicroseconds(500);  // 等待電壓穩定
    
    // 讀取30筆電壓值
    for (int i = 0; i < VOLTAGE_SAMPLE_COUNT; i++) {
        int16_t raw = analogRead(A0);
        
        // 驗證讀數是否在合理範圍內（10-bit: 0-1023）
        if (raw >= 0 && raw <= 1023) {
            // 轉換為12-bit等效值
            int16_t raw12bit = raw * 4;
            sum += raw12bit;
            validSamples++;
        }
        
        // 每筆讀數之間稍作延遲，確保ADC穩定
        delayMicroseconds(100);
    }
    
    // 關閉分壓電路以省電（P0.14 = HIGH）
    digitalWrite(P0_14, HIGH);
    
    // 計算平均值
    if (validSamples > 0) {
        return (int16_t)(sum / validSamples);
    } else {
        // 如果所有讀數都無效，返回0
        return 0;
    }
}

// ============================================================================
// 電壓監控與省電管理函數
// ============================================================================
void checkVoltageAndSleep() {
    unsigned long now = millis();

    // 每60秒檢查一次電壓 (避免頻繁讀取)
    if (now - lastVoltageReadTime >= 60000) {
        // 啟用分壓電路（P0.14 = LOW）
        digitalWrite(P0_14, LOW);
        delayMicroseconds(500);  // 等待電壓穩定
        
        // 讀取 ADC 值（P0.31 / AIN7 / PIN_VBAT）
        voltageRaw = analogRead(A0);
        
        // 關閉分壓電路以省電（P0.14 = HIGH）
        digitalWrite(P0_14, HIGH);
        
        lastVoltageReadTime = now;

        // 轉換 10-bit 到 12-bit（如果需要的話）
        if (voltageRaw <= 1023) {
            voltageRaw = voltageRaw * 4;  // 10-bit 轉 12-bit
        }

        // 將數位值轉換為實際電池電壓
        // 使用 nRF52840 SAADC 公式：
        // V_BAT = RESULT × K / 4096
        // 其中：
        // - RESULT: 12-bit ADC 值（0-4095）
        // - K: 校準常數（理論值 10.8，但可能需要根據實際硬體調整）
        // 建議：用萬用表測量實際電池電壓，然後調整 K 值以匹配
        // 校準調整：根據當前讀值重新校準
        // 如果讀到的原始值是 523 (10-bit) → 2092 (12-bit)，實際電壓應該是 4.14V
        // 計算：4.14 = 2092 * K / 4096，得到 K ≈ 8.11
        float calibrationConstant = 8.11f;  // 根據當前讀值重新校準（2025-01-24）
        float voltage = (float)voltageRaw * calibrationConstant / 4096.0f;

        // 根據電壓調整充電模式
        updateChargingMode(voltage);

        // 檢查是否電壓過低 (低於3.2V，電池低電量警告)
        if (voltage < 3.2) {
            Serial.println("Voltage too low! Entering sleep mode.");
            
            // 嘗試通知手機低電量警告
            if (BLE.connected()) {
                const char* warning = "LowPowerSleep";  // 低電量警告訊息
                uint8_t buffer[30] = {0};               // 初始化緩衝區
                memcpy(buffer, warning, strlen(warning)); // 複製警告訊息
                
                // 使用最後2 bytes作為訊息類型代碼
                uint16_t type = 0xABCD;  // 低電量警告類型
                memcpy(buffer + 28, &type, 2);
                
                // 發送警告訊息
                imuDataChar.writeValue(buffer, 30);

                delay(50);
                BLE.disconnect();       // 強制斷線，確保手機收到警告
                delay(300);
                BLE.advertise();        // 重新開始廣播
            }

            // 進入省電模式 - 等待重新連接
            while (!BLE.central().connected()) {
                delay(1000);   // 每秒檢查一次連接狀態
            }

            Serial.println("BLE reconnected. Wake up.");
            BLE.advertise();  // 重新開始廣播
        }
    }
}

// ============================================================================
// 充電模式控制函數
// ============================================================================
void updateChargingMode(float batteryVoltage) {
    // 電池規格：501230, 3.7V, 150mAh
    // 當電池電壓低於3.5V時，切換到高電流充電模式（快速充電）
    // 當電池電壓高於3.5V時，切換回低電流充電模式（保護電池）
    if (batteryVoltage < 3.5) {
        if (!isHighCurrentCharging) {
            pinMode(P0_13, OUTPUT);           // 設定P0_13為輸出模式
            digitalWrite(P0_13, LOW);         // 輸出LOW信號，啟用高電流充電
            isHighCurrentCharging = true;     // 更新充電模式狀態
            Serial.println("Switched to HIGH current charging.");
        }
    } else {
        // 當電池電壓高於3.5V時，切換回低電流充電模式（保護電池）
        if (isHighCurrentCharging) {
            pinMode(P0_13, OUTPUT);           // 設定P0_13為輸出模式
            digitalWrite(P0_13, HIGH);        // 輸出HIGH信號，啟用低電流充電
            isHighCurrentCharging = false;    // 更新充電模式狀態
            Serial.println("Switched to LOW current charging.");
        }
    }
}
