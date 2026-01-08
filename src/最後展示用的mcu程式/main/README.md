# 🏸 Smart Racket Firmware (MCU)

![Badge](https://img.shields.io/badge/Platform-Arduino-blue?style=for-the-badge&logo=arduino)
![Badge](https://img.shields.io/badge/Board-Seeed_XIAO_nRF52840-green?style=for-the-badge&logo=nordicsemiconductors)
![Badge](https://img.shields.io/badge/Sensor-LSM6DS3-orange?style=for-the-badge)

## 📌 專案簡介 (Overview)
這是 **Smart Racket 智慧羽球拍** 的核心韌體程式，運作於 **Seeed XIAO nRF52840** 微控制器上。
主要負責 **高頻率慣性數據採集 (IMU)** 與 **低功耗藍牙傳輸 (BLE)**。透過內建的 Gyroscope 與 Accelerometer，即時捕捉使用者的揮拍動作，並將數據封包傳送至手機/伺服器進行 AI 分析。

---

## 🛠️ 硬體規格 (Hardware)

| Component      | Model               | Function                   | Pinout        |
| -------------- | ------------------- | -------------------------- | ------------- |
| **MCU**        | Seeed XIAO nRF52840 | 主控制器、BLE運算          | -             |
| **IMU**        | LSM6DS3             | 六軸感測器 (加速度+角速度) | I2C (SDA/SCL) |
| **Battery**    | Li-Po 3.7V          | 電源供應                   | BAT+ / GND    |
| **Status LED** | Built-in RGB        | 狀態指示燈                 | D12/D13/D14   |

### 🔌 腳位定義 (Pin Definitions)
```cpp
const int PIN_LED_RED = 12;   // 紅燈
const int PIN_LED_GREEN = 13; // 綠燈
const int PIN_LED_BLUE = 14;  // 藍燈
P0_13: Charge High Current    // 充電電流控制
P0_17: Charge Status          // 充電狀態讀取
P0_14: Battery Read Enable    // 電壓讀取啟用
P0_31: Battery Analog Read    // 電壓讀取類比腳位
```

---

## 📡 藍牙通訊協定 (BLE Protocol)

本專案使用標準 BLE GATT Profile 進行通訊。

### Service UUID
`0769bb8e-b496-4fdd-b53b-87462ff423d0`

### Characteristics

| Name          | UUID        | Type     | Length   | Description                      |
| ------------- | ----------- | -------- | -------- | -------------------------------- |
| **IMU Data**  | `...257090` | `Notify` | 34 Bytes | 即時傳送感測器封包               |
| **Time Sync** | `...257091` | `Write`  | 4 Bytes  | 接收手機 Unix Timestamp 進行校時 |

### 📦 資料封包結構 (Data Packet Structure)
```cpp
struct DataPacket {
  uint32_t timestamp; // Unix 時間戳 (秒)
  uint16_t ms;        // 毫秒
  float ax, ay, az;   // 加速度 (X, Y, Z)
  float gx, gy, gz;   // 角速度 (X, Y, Z)
  uint16_t voltage;   // 電池電壓
  uint16_t checksum;  // 檢查碼
};
```

---

## 💡 LED 狀態指示燈 (Status Indicators)

為了讓使用者直觀了解裝置狀態，我們設計了完整的燈號邏輯：

| 狀態 (Status)            | 燈號 (LED Pattern)         | 說明 (Description)     |
| ------------------------ | -------------------------- | ---------------------- |
| **充電中** (Charging)    | 🟢 **綠燈呼吸** (Breathing) | 裝置充電中，充飽後熄滅 |
| **待機中** (Idle)        | 🔵 **藍燈慢閃** (Blinking)  | 等待藍牙連線           |
| **已連線** (Connected)   | 🟢/🔵/🔴 **恆亮**             | 根據電量顯示顏色       |
| &nbsp;&nbsp; -> 電量充裕 | 🟢 綠燈恆亮                 | > 3.8V                 |
| &nbsp;&nbsp; -> 電量普通 | 🔵 藍燈恆亮                 | 3.6V ~ 3.8V            |
| &nbsp;&nbsp; -> 電量低   | 🔴 紅燈恆亮                 | < 3.6V                 |

---

## ⚙️ 核心邏輯 (Core Logic)

```mermaid
graph TD
    A[Start] --> B[Setup Hardware \n(LED, IMU, BLE)];
    B --> C{Init Success?};
    C -- No --> D[Error Loop \n(Red Blink)];
    C -- Yes --> E[BLE Advertise];
    E --> F{Connected?};
    F -- No --> G[Update Idle LED];
    F -- Yes --> H[Main Loop];
    
    subgraph "Connected Loop (50Hz)"
    H --> I[Check Time Interval];
    I --> J[Read IMU Data];
    J --> K[Read Battery Voltage];
    K --> L[Send BLE Packet];
    L --> M[Update Connected LED];
    end
```

---

## 🚀 如何編譯與上傳 (How to Build)
1. 安裝 **Arduino IDE**。
2. 安裝 **Seeed nRF52 Boards** BSP。
3. 安裝必要函式庫：
   - `ArduinoBLE`
   - `LSM6DS3`
4. 選擇開發板 `Seeed XIAO nRF52840 Sense`。
5. 點擊 **Upload**。
