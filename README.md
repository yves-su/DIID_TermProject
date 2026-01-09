# 🏸 Smart Racket AI System (智慧羽毛球拍專案)

本專案是一個整合 **嵌入式硬體 (IoT)**、**行動應用 (Mobile)** 與 **人工智慧 (AI)** 的完整 AIoT 系統。透過球拍內的感測器即時偵測揮拍動作，經由手機轉發至雲端 AI 伺服器進行分析，並即時回饋擊球類型（殺球、平抽、切球等）與球速。

---

## 🏗️ 系統架構 (System Architecture)

```mermaid
graph LR
    subgraph Hardware [MCU & Sensors]
        IMU(LSM6DS3) -->|I2C| MCU(XIAO nRF52840)
        MCU -->|BLE 5.0 (Notify)| App
    end

    subgraph Mobile [Flutter App]
        App -->|Ring Buffer| Buffer(Data Manager)
        Buffer -->|Detection| Logic(Trigger Logic)
        Logic -->|WebSocket (JSON)| Server
        Server -->|Result| UI(Real-time Feedback)
    end

    subgraph Cloud [AI Server]
        Server(FastAPI) -->|Preprocessing| Model1(Classifier)
        Server -->|Raw Data| Model2(Speed Regressor)
        Model1 --> Result
        Model2 --> Result
    end
```

---

## 🔧 1. 硬體端 (MCU Firmware)
位於 `src/最後展示用的mcu程式/main`

基於 **Seeed XIAO nRF52840 Sense** 開發板，負責以 **50Hz** 頻率採樣六軸數據並透過 BLE 廣播。

### 核心規格
*   **開發板**: Seeed XIAO nRF52840 Sense
*   **感測器**: LSM6DS3 (Acc ±16G, Gyro ±2000dps)
*   **傳輸協定**: Bluetooth Low Energy (BLE 5.0)
*   **採樣率**: 50Hz (每 20ms 一筆)

### BLE 通訊協定
*   **Device Name**: `SmartRacket`
*   **Service UUID**: `0769bb8e-b496-4fdd-b53b-87462ff423d0`
*   **IMU Characteristic**: `8ee82f5b-76c7-4170-8f49-fff786257090` (Notify)

### 封包結構 (34 Bytes)
MCU 傳送自定義的二進位結構封包，不進行任何字串轉換以最大化傳輸效率：

| Offset | 欄位 (Field)  | 類型 (Type) | 說明                     |
| :----- | :------------ | :---------- | :----------------------- |
| 0      | **Timestamp** | `uint32_t`  | Unix 時間戳記 (秒)       |
| 4      | **Millis**    | `uint16_t`  | 毫秒數 (0~999)           |
| 6      | **Accel X**   | `float`     | 加速度 X (Little Endian) |
| 10     | **Accel Y**   | `float`     | 加速度 Y                 |
| 14     | **Accel Z**   | `float`     | 加速度 Z                 |
| 18     | **Gyro X**    | `float`     | 角速度 X                 |
| 22     | **Gyro Y**    | `float`     | 角速度 Y                 |
| 26     | **Gyro Z**    | `float`     | 角速度 Z                 |
| 30     | **Voltage**   | `uint16_t`  | 電池電壓 (mV)            |
| 32     | **Checksum**  | `uint16_t`  | XOR 校驗碼               |

---

## 📱 2. 行動端 (Flutter App)
位於 `APP/smart_racket_app`

使用 **Flutter** 構建的跨平台應用程式，作為資料的中繼站與視覺化終端。

### 技術棧
*   **Framework**: Flutter 3.x (Dart)
*   **State Management**: Provider
*   **BLE**: `flutter_blue_plus`
*   **Network**: `web_socket_channel`
*   **Charts**: `fl_chart`

### 關鍵功能
1.  **Ring Buffer 機制**: 實作環形緩衝區處理高頻 BLE 資料，防止封包錯位或遺失。
2.  **即時波形圖**: 透過 Canvas 高效繪製六軸資料波形。
3.  **MCU Debug Window**: 專用的硬體除錯介面，可監看原始數據與調整觸發靈敏度。
4.  **WebSocket 串流**: 智慧判斷揮拍動作，僅擷取關鍵視窗 (Window) 傳送至伺服器。

---

## 🧠 3. AI 伺服器 (Python Server)
位於 `server/`

基於 **FastAPI** 的高效能推論伺服器，負責接收數據並執行深度學習模型。

### 技術棧
*   **Runtime**: Python 3.9+
*   **Framework**: FastAPI (WebSocket support)
*   **AI Engine**: TensorFlow / Keras

### 模型架構
伺服器運行兩組模型：
1.  **動作分類器 (Classifier)**:
    *   輸入: 40 frames (正規化後的 IMU 數據)
    *   輸出: 動作類型 (Smash, Drive, Drop, Toss, Other)
2.  **球速預測器 (Speed Regressor)**:
    *   輸入: 原始數據
    *   觸發: 僅在分類為 `Smash` 時執行，預測殺球速度。

---

## 🚀 快速開始 (Getting Started)

### 1. 硬體準備
燒錄 `src/最後展示用的mcu程式/main/main.ino` 至 XIAO nRF52840 開發板。

### 2. 啟動伺服器
```bash
cd server
pip install -r requirements.txt
python main.py
```
*(伺服器預設運行於 `0.0.0.0:8000`)*

### 3. 執行 App
```bash
cd APP/smart_racket_app
flutter pub get
flutter run
```

### 4. 連線步驟
1.  打開 App，點擊 **Wifi 圖示** 自動掃描並連接球拍 (需開藍牙)。
2.  在 App 上方輸入伺服器 IP (例如 `ws://192.168.1.100:8000/ws/predict`)。
3.  開始揮拍！App 會即時顯示動作與球速。

---

## 👥 專案團隊

*   **硬體/韌體**: 蘇昱彰、張羿軒
*   **App 開發**: 許峻瑋 (Flutter重構)、李昊恆 (UI)
*   **AI 模型**: 江詠翔、費哈蘇
*   **資料工程**: 巫誌騰

---

## 📄 授權
本專案為學期專案成果，僅供學術交流與學習使用。
