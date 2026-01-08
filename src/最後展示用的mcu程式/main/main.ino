/**
 * Project: Smart Racket (智慧羽球拍)
 * Author: DIID Term Project Team
 * Description:
 *   此程式運作於 Seeed XIAO nRF52840 開發板上。
 *   主要功能為讀取 LSM6DS3 六軸慣性測量單元 (IMU) 的加速度與角速度數據，
 *   並透過 BLE (Bluetooth Low Energy) 廣播與傳輸資料至手機端/伺服器端進行 AI
 * 動作分析。
 *
 *   特色功能：
 *   1. 使用 BLE 進行低功耗藍牙傳輸 (Service UUID/Char UUID)。
 *   2. 實作 LED 狀態燈號 (充電、待機、連線、電量與呼吸燈效果)。
 *   3. 嚴格的時間同步機制 (Time Sync) 確保數據時間戳記精確。
 *   4. 電池電壓監測與校正。
 */

#include <ArduinoBLE.h> // 引入 BLE 函式庫，用於藍牙通訊
#include <LSM6DS3.h>    // 引入 IMU 函式庫，用於讀取六軸感測器
#include <Wire.h>       // 引入 Wire 函式庫，用於 I2C 通訊

// --- 設定區 (Settings) ---
// 設定 IMU 的採樣率 (Hz)，此數值需與 AI 模型訓練時的採樣率一致
#define IMU_RATE 50

// --- LED 腳位定義 (Pin Definitions) ---
// 根據實際硬體測試結果定義 RGB LED 腳位
// 測試結果：12=紅(Red), 13=綠(Green), 14=藍(Blue)
// 注意：XIAO nRF52840 的 onboard LED 為 Active LOW (低電位點亮)
const int PIN_LED_RED = 12;
const int PIN_LED_GREEN = 13;
const int PIN_LED_BLUE = 14;

// --- 藍牙 UUID 設定 (BLE UUIDs) ---
// UUID 是藍牙服務與特徵的唯一識別碼，手機端需使用相同 UUID 才能找到此裝置
const char *DEVICE_NAME = "SmartRacket";
const char *SERVICE_UUID =
    "0769bb8e-b496-4fdd-b53b-87462ff423d0"; // 主服務 UUID
const char *CHAR_IMU_UUID =
    "8ee82f5b-76c7-4170-8f49-fff786257090"; // IMU 資料特徵 (Read/Notify)
const char *CHAR_TIME_UUID =
    "8ee82f5b-76c7-4170-8f49-fff786257091"; // 時間同步特徵 (Write)

// --- 硬體與藍牙物件實例化 (Objects) ---
// 建立 IMU 物件，使用 I2C 模式，位址為 0x6A
LSM6DS3 myIMU(I2C_MODE, 0x6A);

// 建立 BLE 服務物件
BLEService racketService(SERVICE_UUID);

// 建立 BLE 特徵 (Characteristics)
// imuChar: 用於傳送感測器數據，支援 Read 與 Notify (主動推播) 模式，資料長度 34
// bytes
BLECharacteristic imuChar(CHAR_IMU_UUID, BLERead | BLENotify, 34);

// timeChar: 用於接收手機端的時間同步訊號，支援 Write 模式，資料長度 4 bytes
// (uint32 timestamp)
BLECharacteristic timeChar(CHAR_TIME_UUID, BLEWrite, 4);

// --- 資料結構 (Data Structure) ---
// 定義傳輸封包的結構，使用 __attribute__((packed))
// 禁止編譯器進行記憶體對齊填補(Padding)， 確保傳輸的 byte
// 順序與大小與定義完全一致。
struct DataPacket {
  uint32_t timestamp; // Unix Timestamp (秒)
  uint16_t ms;        // 毫秒 (Milliseconds)
  float ax, ay, az;   // 加速度 (Accelerometer): X, Y, Z
  float gx, gy, gz;   // 角速度 (Gyroscope): X, Y, Z
  uint16_t voltage;   // 電池電壓 (Battery Voltage)
  uint16_t checksum;  // 檢查碼 (XOR Checksum)，用於驗證資料完整性
} __attribute__((packed));

DataPacket packet; // 宣告一個封包變數

// --- 全域變數 (Global Variables) ---
uint16_t g_lastVoltage = 0; // 儲存最後一次讀取到的電池電壓，用於 LED 顏色判斷
unsigned long offsetUnixTime = 0; // 基準時間 (秒)，由手機端同步寫入
unsigned long millisAtSync =
    0; // 收到基準時間當下的 Arduino 系統時間 (millis)，用於計算經過時間

/**
 * -------------------------------------------------------------------------
 * Setup 函式：系統初始化
 * -------------------------------------------------------------------------
 */
void setup() {
  Serial.begin(115200); // 開啟 Serial 通訊，便於除錯 (Debug)

  // --- 1. LED 初始化 ---
  pinMode(PIN_LED_RED, OUTPUT);
  pinMode(PIN_LED_GREEN, OUTPUT);
  pinMode(PIN_LED_BLUE, OUTPUT);

  // 預設全滅 (Active LOW: HIGH=滅, LOW=亮)
  digitalWrite(PIN_LED_RED, HIGH);
  digitalWrite(PIN_LED_GREEN, HIGH);
  digitalWrite(PIN_LED_BLUE, HIGH);

  // --- 2. 充電功能設定 (針對 Seeed XIAO nRF52840) ---
  // 設定充電電流與讀取充電狀態
  pinMode(P0_13, OUTPUT);
  digitalWrite(P0_13, LOW);     // 設定為 High Charge Current (快充模式)
  pinMode(P0_17, INPUT_PULLUP); // P0.17 為充電狀態腳位 (Low = Charging)

  // --- 3. 電壓讀取腳位設定 ---
  pinMode(P0_14, INPUT); // 設定電壓讀取致能腳位

  // --- 4. 初始化 IMU (慣性測量單元) ---
  // [重要] 強制設定與訓練資料一致的量程 (Range)，避免數據被截斷 (Clipping)
  // 殺球動作瞬間加速度極大，若使用預設 ±2G/4G 會導致數據失真
  myIMU.settings.accelRange = 16;  // 加速度量程：±16 G
  myIMU.settings.gyroRange = 2000; // 角速度量程：±2000 dps (degrees per second)

  if (myIMU.begin() != 0) {
    Serial.println("IMU Error");
    // 若 IMU 初始化失敗，紅燈快速閃爍並鎖死程式
    while (1) {
      digitalWrite(PIN_LED_RED, LOW);
      delay(100);
      digitalWrite(PIN_LED_RED, HIGH);
      delay(100);
    }
  }

  // --- 5. 初始化藍牙模組 (BLE) ---
  if (!BLE.begin()) {
    Serial.println("BLE Error");
    // 若 BLE 初始化失敗，紅燈慢速閃爍並鎖死程式
    while (1) {
      digitalWrite(PIN_LED_RED, LOW);
      delay(500);
      digitalWrite(PIN_LED_RED, HIGH);
      delay(500);
    }
  }

  // --- 6. 設定藍牙參數 ---
  BLE.setLocalName(DEVICE_NAME);           // 設定裝置名稱
  BLE.setAdvertisedService(racketService); // 設定廣播的服務

  // 將特徵加入服務
  racketService.addCharacteristic(imuChar);
  racketService.addCharacteristic(timeChar);

  // 將服務加入 BLE
  BLE.addService(racketService);

  // 設定事件 Callback：當 timeChar 被寫入時，執行 onTimeWritten 函式
  timeChar.setEventHandler(BLEWritten, onTimeWritten);

  // 開始廣播 (Advertising)，讓手機可以搜尋到
  BLE.advertise();
  Serial.println("Bluetooth Device Active, waiting for connections...");
}

/**
 * -------------------------------------------------------------------------
 * LED 狀態更新函式
 * 目的：根據目前的系統狀態 (充電中、連線中、電量高低) 改變 LED 顏色與顯示模式
 * -------------------------------------------------------------------------
 * @param connected 目前是否已連上藍牙
 */
void updateLedState(bool connected) {
  // 1. 檢查是否在充電 (P0.17 LOW 代表正在充電)
  bool isCharging = (digitalRead(P0_17) == LOW);

  if (isCharging) {
    // === 充電模式：綠燈呼吸燈 (Breathing Green) ===
    // 關閉紅、藍燈
    digitalWrite(PIN_LED_RED, HIGH);
    digitalWrite(PIN_LED_BLUE, HIGH);

    // 計算呼吸燈亮度 (0~255 三角波)
    // 使用 millis() 產生隨時間變化的數值
    int val = (millis() / 5) % 512;
    if (val > 255)
      val = 511 - val; // 讓數值從 0->255->0 循環

    // 因為 LED 是 Active LOW, 亮度控制需反向 (analogWrite 0=Off, 255=On ? or
    // inverted?) 經實測與習慣，analogWrite 在此開發板對應 PWM Duty Cycle 故用
    // 255 - val 來控制亮度變化
    analogWrite(PIN_LED_GREEN, 255 - val);
    return; // 充電模式優先權最高，直接返回
  }

  // 若沒在充電，檢查藍牙連線狀態
  if (!connected) {
    // === 待機模式 (未連線)：藍燈慢閃 (Blinking Blue) ===
    // 先關閉綠、紅燈，並清除 PWM 狀態
    digitalWrite(PIN_LED_GREEN, HIGH);
    digitalWrite(PIN_LED_RED, HIGH);

    static unsigned long lastBlink = 0;
    static bool ledState = HIGH;

    // 每 500ms 切換一次狀態
    if (millis() - lastBlink >= 500) {
      lastBlink = millis();
      ledState = !ledState;
      digitalWrite(PIN_LED_BLUE, ledState);
    }
  } else {
    // === 連線模式：顯示電量 (Battery Level Indicator) ===
    // 根據最後一次讀到的電壓值 (g_lastVoltage) 顯示對應顏色 (恆亮)

    // 電量燈號邏輯：
    // > 3.8V : 綠燈 (Green) - 電量充足
    // 3.6V ~ 3.8V : 藍燈 (Blue) - 電量普通
    // < 3.6V : 紅燈 (Red) - 電量低

    if (g_lastVoltage > 3800) {
      digitalWrite(PIN_LED_RED, HIGH);
      digitalWrite(PIN_LED_BLUE, HIGH);
      digitalWrite(PIN_LED_GREEN, LOW); // 亮綠燈
    } else if (g_lastVoltage >= 3600) {
      digitalWrite(PIN_LED_RED, HIGH);
      digitalWrite(PIN_LED_GREEN, HIGH);
      digitalWrite(PIN_LED_BLUE, LOW); // 亮藍燈
    } else {
      digitalWrite(PIN_LED_GREEN, HIGH);
      digitalWrite(PIN_LED_BLUE, HIGH);
      digitalWrite(PIN_LED_RED, LOW); // 亮紅燈 (沒讀到電壓預設也為紅)
    }
  }
}

/**
 * -------------------------------------------------------------------------
 * Loop 函式：主程式迴圈
 * -------------------------------------------------------------------------
 */
void loop() {
  // 檢查是否有中央裝置 (手機) 連線
  BLEDevice central = BLE.central();

  // 更新 LED 狀態 (傳入目前連線狀態)
  updateLedState((bool)central);

  if (central) {
    // --- 進入連線狀態 ---
    static bool connectedLog = false;
    if (!connectedLog) {
      Serial.print("Connected to central: ");
      Serial.println(central.address());
      connectedLog = true;
    }

    unsigned long lastSend = 0;
    // 計算發送間隔：1000ms / 50Hz = 20ms
    const unsigned long interval = 1000 / IMU_RATE;

    // 當連線持續時，執行此迴圈
    while (central.connected()) {
      // 雖然在 while 迴圈內，仍需持續更新 LED (為了充電呼吸燈效果順暢)
      unsigned long now = millis();

      // 檢查是否已達到傳送資料的時間點
      if (now - lastSend >= interval) {
        lastSend = now;

        // 讀取感測器並發送數據
        readAndSendSensor();

        // 讀取傳感器後電壓會更新，隨即更新 LED 顯示
        updateLedState(true);
      }
    }

    // --- 連線中斷 ---
    Serial.print("Disconnected from central: ");
    Serial.println(central.address());
    connectedLog = false;
  }
}

/**
 * -------------------------------------------------------------------------
 * readAndSendSensor 函式
 * 功能：讀取 IMU 數值、電池電壓，打包成 Packet 並透過 BLE 發送
 * -------------------------------------------------------------------------
 */
void readAndSendSensor() {
  // 1. 計算時間戳記
  unsigned long currentMillis = millis();
  unsigned long elapsedSinceSync = currentMillis - millisAtSync;

  // 結合基準時間 (Offset) 與經過時間，計算出當下的 Unix Timestamp
  packet.timestamp = offsetUnixTime + (elapsedSinceSync / 1000);
  packet.ms = elapsedSinceSync % 1000;

  // 2. 讀取 IMU 加速度 (Accel) X, Y, Z
  packet.ax = myIMU.readFloatAccelX();
  packet.ay = myIMU.readFloatAccelY();
  packet.az = myIMU.readFloatAccelZ();

  // 3. 讀取 IMU 角速度 (Gyro) X, Y, Z
  packet.gx = myIMU.readFloatGyroX();
  packet.gy = myIMU.readFloatGyroY();
  packet.gz = myIMU.readFloatGyroZ();

  // 4. 讀取電池電壓 (Battery Voltage)
  // 設定 P0.14 為 LOW 以啟動分壓電路讀取 (省電設計)
  pinMode(P0_14, OUTPUT);
  digitalWrite(P0_14, LOW);
  delayMicroseconds(50); // 等待電路穩定

  // 類比讀取 P0.31 (BAT_READ)
  analogRead(P0_31); // 捨棄第一次讀取 (Dummy read)
  delayMicroseconds(10);

  // 進行多次採樣取平均，以獲得更穩定的數值
  uint32_t rawSum = 0;
  int samples = 5;
  for (int i = 0; i < samples; i++) {
    rawSum += analogRead(P0_31);
    delayMicroseconds(10);
  }

  // 讀取完畢，關閉分壓電路 (省電)
  digitalWrite(P0_14, HIGH);
  pinMode(P0_14, INPUT);

  // 計算實際電壓 (毫伏特 mV)
  // 公式參考：raw / samples * (參考電壓/解析度) * (分壓比)
  float raw = rawSum / (float)samples;
  float v = raw * (3600.0f / 1023.0f) * (1510.0f / 510.0f);
  v *= 0.9314f; // 硬體校正係數 (根據實際量測值調整)

  packet.voltage = (uint16_t)v;
  g_lastVoltage = packet.voltage; // 更新全域電壓變數

  // 5. 計算檢查碼 (XOR Checksum)
  // 用於讓接收端驗證封包在傳輸過程中是否損壞
  uint8_t *ptr = (uint8_t *)&packet;
  uint16_t chk = 0;
  // 對封包的前 32 bytes 進行 XOR 運算 (不包含 checksum 欄位本身)
  for (int i = 0; i < 32; i++) {
    chk ^= ptr[i];
  }
  packet.checksum = chk;

  // 6. 寫入 BLE 特徵值 (發送資料)
  imuChar.writeValue((uint8_t *)&packet, sizeof(packet));
}

/**
 * -------------------------------------------------------------------------
 * onTimeWritten 函式 (BLE Event Callback)
 * 功能：當手機寫入時間特徵時觸發，用於校正時間
 * -------------------------------------------------------------------------
 */
void onTimeWritten(BLEDevice central, BLECharacteristic characteristic) {
  // 確認寫入的資料長度是否正確 (4 bytes = uint32)
  if (characteristic.valueLength() == 4) {
    const uint8_t *data = characteristic.value();
    uint32_t ts = 0;

    // 將 4 bytes 還原為 uint32 整數 (Little Endian)
    ts |= data[0];
    ts |= data[1] << 8;
    ts |= data[2] << 16;
    ts |= data[3] << 24;

    // 更新系統基準時間
    offsetUnixTime = ts;
    millisAtSync = millis(); // 記錄同步當下的機器時間

    Serial.print("Time Synced: ");
    Serial.println(ts);
  }
}
