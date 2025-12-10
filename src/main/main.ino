#include <ArduinoBLE.h> // 引入 BLE (低功耗藍牙) 函式庫，讓我們可以使用藍牙功能
#include <LSM6DS3.h>    // 引入 IMU (慣性測量單元) 函式庫，用來讀取加速度和陀螺儀
#include <Wire.h>       // 引入 Wire 函式庫，這是用來與 IMU 進行 I2C 通訊的

// --- 設定區 ---
// 定義 IMU 的傳輸速率為 50Hz (每秒 50 次)
#define IMU_RATE 50 

// --- LED 腳位設定 (Seeed XIAO nRF52840) ---
// 這塊板子有內建 RGB LED，分別對應以下腳位 (Active LOW: LOW=亮, HIGH=滅)
#ifndef LED_RED
#define LED_RED 11  // P0.26
#endif
#ifndef LED_GREEN
#define LED_GREEN 12 // P0.30
#endif
#ifndef LED_BLUE
#define LED_BLUE 13  // P0.06
#endif

// --- 藍牙 UUID 設定 ---
// 這些是用來識別裝置和服務的唯一識別碼 (UUID)
// 在 APP 端也要使用一模一樣的 UUID 才能對得上
const char* DEVICE_NAME = "SmartRacket"; // 藍牙廣播名稱
const char* SERVICE_UUID = "0769bb8e-b496-4fdd-b53b-87462ff423d0"; // 主要服務 UUID
const char* CHAR_IMU_UUID = "8ee82f5b-76c7-4170-8f49-fff786257090"; // IMU 資料特徵值
const char* CHAR_TIME_UUID = "8ee82f5b-76c7-4170-8f49-fff786257091"; // 時間同步特徵值

// --- 硬體物件 ---
// 建立 IMU 物件，使用 I2C 模式，位址通常是 0x6A
LSM6DS3 myIMU(I2C_MODE, 0x6A);

// --- 藍牙物件 ---
// 建立一個藍牙服務
BLEService racketService(SERVICE_UUID);

// 建立特徵值 (Characteristic)
// IMU 特徵值：APP 可以讀取 (Read) 跟訂閱通知 (Notify)，長度 34 bytes
BLECharacteristic imuChar(CHAR_IMU_UUID, BLERead | BLENotify, 34); 
// 時間特徵值：APP 可以寫入 (Write) 時間給我們，長度 4 bytes (一個數字)
BLECharacteristic timeChar(CHAR_TIME_UUID, BLEWrite, 4);      

// --- 資料結構 ---
// 這是我們傳給 APP 的資料封包格式
// __attribute__((packed)) 的意思是告訴編譯器不要塞任何填充位元，確保大小剛剛好
struct DataPacket {
  uint32_t timestamp;  // 0-3 bytes: 時間戳記 (秒)
  uint16_t ms;         // 4-5 bytes: 毫秒的部分
  float ax, ay, az;    // 6-17 bytes: 加速度計 X, Y, Z (各 4 bytes)
  float gx, gy, gz;    // 18-29 bytes: 陀螺儀 X, Y, Z (各 4 bytes)
  uint16_t voltage;    // 30-31 bytes: 電池電壓 (毫伏特 mV)
  uint16_t checksum;   // 32-33 bytes:檢查碼 (用來確認資料有沒有傳壞)
} __attribute__((packed));

// 建立一個封包變數，等等把資料塞進這裡
DataPacket packet;

// --- 時間同步變數 ---
// 因為 MCU 沒有時區概念，我們需要 APP 告訴我們現在幾點 (Unix Time)
unsigned long offsetUnixTime = 0; // 手機傳來的基準時間 (秒)
unsigned long millisAtSync = 0;   // 收到基準時間當下的 Arduino 系統時間 (毫秒)

// --- 初始化函式 (只會執行一次) ---
void setup() {
  Serial.begin(115200); // 開啟序列埠監控，速度 115200 (用來在電腦看 debug 訊息)
  
  // --- LED 初始化 ---
  pinMode(LED_RED, OUTPUT);
  pinMode(LED_GREEN, OUTPUT);
  pinMode(LED_BLUE, OUTPUT);
  
  // 預設全滅 (Active LOW)
  digitalWrite(LED_RED, HIGH);
  digitalWrite(LED_GREEN, HIGH);
  digitalWrite(LED_BLUE, HIGH);

  // --- 充電功能設定 (針對 Seeed XIAO nRF52840) ---
  // P0.13:High Charge Setting (HICHG)
  // 設為 LOW 代表啟用 100mA 快充 (預設懸空是 50mA)
  pinMode(P0_13, OUTPUT);
  digitalWrite(P0_13, LOW); 

  // P0.17: Charge Status (CHG)
  // LOW 代表正在充電中，HIGH 代表充飽或沒充
  pinMode(P0_17, INPUT_PULLUP);

  // --- 電壓讀取腳位設定 ---
  // P0.14 是啟用腳位。
  // 注意：平常不讀取時，建議設為 INPUT (High Impedance)，避免對 P0.31 造成漏電流或電壓影響
  pinMode(P0_14, INPUT);
  
  // 1. 初始化 IMU
  // 如果回傳值不為 0 代表失敗
  if (myIMU.begin() != 0) {
    Serial.println("IMU Error"); // 印出錯誤訊息
    // IMU 錯誤：閃爍紅燈
    while(1) { 
      digitalWrite(LED_RED, LOW); delay(100); 
      digitalWrite(LED_RED, HIGH); delay(100); 
    }
  }
  
  // 2. 初始化藍牙模組
  if (!BLE.begin()) {
    Serial.println("BLE Error");
    // BLE 錯誤：慢閃紅燈
    while(1) { 
        digitalWrite(LED_RED, LOW); delay(500); 
        digitalWrite(LED_RED, HIGH); delay(500); 
    } 
  }

  // 設定藍牙參數
  BLE.setLocalName(DEVICE_NAME); // 設定廣播名稱
  BLE.setAdvertisedService(racketService); // 設定廣播這項服務
  
  // 把特徵值加到服務裡
  racketService.addCharacteristic(imuChar);
  racketService.addCharacteristic(timeChar);
  // 把服務加到藍牙系統裡
  BLE.addService(racketService);

  // 設定事件處理器：當有人寫入 timeChar 時，呼叫 onTimeWritten 函式
  timeChar.setEventHandler(BLEWritten, onTimeWritten);

  // 開始廣播！這時候 APP 才能掃描到我們
  BLE.advertise();
  Serial.println("Bluetooth Device Active, waiting for connections...");
  
  // 等待連線時：亮綠燈 (或不亮)
  // 這裡我們先不亮，或者可以考慮慢閃綠燈代表 "Waiting"
}

// --- 主迴圈 (一直重複執行) ---
void loop() {
  // 檢查有沒有主機 (Central，例如手機) 連上來
  BLEDevice central = BLE.central();

  if (central) {
    // 真的連上了！
    Serial.print("Connected to central: ");
    Serial.println(central.address());
    
    // 連線成功：亮藍燈 (Turn ON Blue LED)
    digitalWrite(LED_RED, HIGH);   // 關紅
    digitalWrite(LED_GREEN, HIGH); // 關綠
    digitalWrite(LED_BLUE, LOW);   // 亮藍

    unsigned long lastSend = 0; // 上次傳送的時間
    // 計算傳送間隔 (毫秒)，例如 50Hz 就是每 20ms 傳一次
    const unsigned long interval = 1000 / IMU_RATE;

    // 當手機還連著的時候，就不斷做這個迴圈
    while (central.connected()) {
      unsigned long now = millis(); // 取得現在運行的毫秒數
      
      // 如果時間到了 (距離上次傳送超過 interval)
      if (now - lastSend >= interval) {
        lastSend = now; // 更新上次傳送時間
        readAndSendSensor(); // 呼叫讀取並傳送的函式
      }
      
      // 雖然大多數 nRF52 核心不需要，但有些核心需要 polling 藍牙事件
      // BLE.poll(); 
    }

    // 斷線了
    Serial.print("Disconnected from central: ");
    Serial.println(central.address());
    
    // 斷線後：關閉所有燈 (或是回到待機閃爍)
    digitalWrite(LED_BLUE, HIGH); // 關藍燈
  }
}

// --- 讀取並傳送感測器資料 ---
void readAndSendSensor() {
  // 1. 計算當下時間
  unsigned long currentMillis = millis();
  // 算出距離同步時間過了多久
  unsigned long elapsedSinceSync = currentMillis - millisAtSync;
  
  // 填入封包：目前時間 = 基準時間 + 過了幾秒
  packet.timestamp = offsetUnixTime + (elapsedSinceSync / 1000);
  // 毫秒部分 = 過了多久除以 1000 的餘數
  packet.ms = elapsedSinceSync % 1000;
  
  // 2. 讀取 IMU 資料 (加速度與角速度)
  packet.ax = myIMU.readFloatAccelX();
  packet.ay = myIMU.readFloatAccelY();
  packet.az = myIMU.readFloatAccelZ();
  
  packet.gx = myIMU.readFloatGyroX();
  packet.gy = myIMU.readFloatGyroY();
  packet.gz = myIMU.readFloatGyroZ();
  
  // 3. 讀取電池電壓
  // 由於電路阻抗很高 (1M + 510k 歐姆)，直接讀會因為取樣時間不足而不準
  // 我們需要做一些技巧：先讀一次假的，再讀幾次算平均
  
  // - 切換為 OUTPUT 並拉低，開啟測量電路
  pinMode(P0_14, OUTPUT);
  digitalWrite(P0_14, LOW); 
  delayMicroseconds(50);    // 等待 50 微秒讓電路穩定
  
  analogRead(P0_31); // 讀一次假的 (Dummy read) 讓電容充電
  delayMicroseconds(10);
  
  uint32_t rawSum = 0;
  int samples = 5; // 取 5 次平均
  for(int i=0; i<samples; i++) {
    rawSum += analogRead(P0_31); // 讀取 P0.31 腳位
    delayMicroseconds(10);
  }
  
  // - 讀完後馬上拉高並切回 INPUT，避免漏電保護電路
  digitalWrite(P0_14, HIGH); 
  pinMode(P0_14, INPUT); 
  
  float raw = rawSum / (float)samples; // 算出平均讀值 (0~1023)
  
  // 電壓公式推導：
  // 1. ADC 讀值轉電壓 (參考電壓 3.6V): Vpin = raw * (3.6 / 1023)
  // 2. 分壓電路還原 (1510k / 510k): Vbat = Vpin * (1510 / 510)
  // 3. 結合起來的理論值
  float v = raw * (3600.0f / 1023.0f) * (1510.0f / 510.0f);

  // 校正 (Calibration):
  // 使用者實測 3.53V 時，APP 顯示 3.79V。
  // 誤差比例 = 3.53 / 3.79 = 0.9314
  // 我們乘上這個係數來修正誤差
  v *= 0.9314f;

  packet.voltage = (uint16_t)v; // 轉成整數存入封包 (例如 3700 代表 3.7V)

  // 4. 計算檢查碼 (Checksum)
  // 使用 XOR 運算把前面所有資料混在一起，讓接收端檢查資料有沒有傳錯
  uint8_t* ptr = (uint8_t*)&packet;
  uint16_t chk = 0;
  for(int i=0; i<32; i++) { // 前 32 bytes 參與運算
    chk ^= ptr[i];
  }
  packet.checksum = chk;

  // 5. 透過藍牙傳送出去
  imuChar.writeValue((uint8_t*)&packet, sizeof(packet));
}

// --- 事件：收到時間同步 ---
void onTimeWritten(BLEDevice central, BLECharacteristic characteristic) {
  // 檢查是不是收到 4 個 byte
  if (characteristic.valueLength() == 4) {
     const uint8_t* data = characteristic.value();
     uint32_t ts = 0;
     // 將 4 個 byte 組合成一個 32 位元整數 (Little Endian 排列)
     // 例如：[0x01, 0x02, 0x03, 0x04] -> 0x04030201
     ts |= data[0];
     ts |= data[1] << 8;
     ts |= data[2] << 16;
     ts |= data[3] << 24;
     
     // 更新全域變數
     offsetUnixTime = ts; 
     millisAtSync = millis(); // 記下收到同步那一刻的 Arduino 時間
     
     Serial.print("Time Synced: ");
     Serial.println(ts);
  }
}

// --- 小工具：閃爍 LED (紅色) ---
// 用來顯示錯誤狀態
void blink(int delayMs) {
  digitalWrite(LED_RED, LOW); // 亮紅燈
  delay(delayMs);
  digitalWrite(LED_RED, HIGH); // 關紅燈
  delay(delayMs);
}
