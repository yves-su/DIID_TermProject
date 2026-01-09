# Smart Racket AI App 🏸

**English** | [Traditional Chinese](#smart-racket-ai-app--繁體中文)

An advanced Flutter application designed to interface with the Smart Racket hardware ecosystem. This app serves as the central hub, bridging high-frequency sensor data from the racket (ESP32) to the AI inference engine (Python Server), while providing real-time visualization and feedback to the player.

---

## ✨ Key Features

### 1. Robust BLE Connectivity (`BleService`)
*   **Auto-Connect**: Automatically scans for and connects to the nearest device named **"SmartRacket"**.
*   **High-Performance Stream**: Handles high-throughput BLE notifications using a **Ring Buffer** architecture to prevent data packet loss or corruption.
*   **Custom Protocol**: Parses 34-byte custom binary packets containing timestamp, 6-axis IMU data (Acc/Gyro), and battery voltage.
*   **Visual Feedback**: Beautiful ripple animations and haptic feedback during scanning and connection.

### 2. Real-Time AI Interaction (`WebSocketService`)
*   **Low-Latency Streaming**: Streams buffered IMU sensor windows to a local or remote Python server via WebSocket (`ws://` or `wss://`).
*   **Intelligent Triggering**: Only sends relevant data windows based on motion intensity thresholds, optimizing bandwidth.
*   **Instant Feedback**: Receives and displays AI classification results (Swing Type & Speed) within milliseconds.
*   **Supported Actions**:
    *   **Smash** (殺球)
    *   **Drive** (平抽)
    *   **Drop** (切球)
    *   **Toss** (長球)
    *   **Other** (其他)

### 3. Professional Data Visualization
*   **6-Axis Graph**: Real-time rendering of Accelerometer and Gyroscope data using `fl_chart`.
*   **Triggered Waveform View**: Visualizes the exact data waveform sent to the server, allowing users to verify the input to the AI model.
*   **Swing Statistics**: Tracks and counts the number of shots for each swing type in the current session.
*   **Server Status Probe**: "Ping-less" server detection mechanism (`probeOnce`) to quickly verify AI server availability.

### 4. MCU Status & Debugging
*   **MCU Debug Window**: A dedicated debug interface for monitoring MCU status.
*   **Raw Data Inspection**: View real-time raw packet logs, connection stability, and battery voltage.
*   **Sensitivity Control**: Adjust the motion trigger threshold directly from the debug panel.

### 5. Sensor Calibration
*   **Zero-Offset**: Built-in zero-offset calibration to ensure data accuracy regardless of initial racket orientation.

---

## 🛠 Technical Architecture

The app is built with **Flutter** and follows a **Provider-based MVVM** architecture for separation of concerns and testability.

### Core Components
*   **`HomeProvider`**: The central "Brain" of the UI. It orchestrates data flow between services and the UI, managing application state (Connection status, Stats, Calibration).
*   **`BleService`**: Managing Bluetooth Low Energy (BLE) scanning, connection, and raw byte parsing. It exposes a broadcast stream of `IMUData`.
*   **`WebSocketService`**: Manages the persistent connection to the AI Server. Handles JSON serialization/deserialization and heartbeat mechanisms.
*   **`DataBufferManager`**: Implements a sliding window buffer to capture the exact moment of a swing for AI analysis.

### Dependencies
*   `flutter_blue_plus`: For reliable BLE communication.
*   `web_socket_channel`: For communicating with the Python AI Server.
*   `provider`: For efficient state management and dependency injection.
*   `fl_chart`: For high-performance real-time charts.

---

## 🚀 Getting Started

### Prerequisites
*   **Hardware**: A Smart Racket device (ESP32 + MPU6050/ICM20948) broadcasting as "SmartRacket".
*   **Server**: The Python AI Server running locally or in the cloud.

### Installation
1.  **Clone the repository**:
    ```bash
    git clone https://github.com/YourRepo/smart_racket_app.git
    ```
2.  **Install dependencies**:
    ```bash
    flutter pub get
    ```
3.  **Run the app**:
    ```bash
    flutter run
    ```

### Usage Guide
1.  **Connect Racket**: Tap the large **WiFi icon** on the main screen. The app will scan and auto-connect to your racket.
2.  **Connect Server**:
    *   Enter your AI Server address (e.g., `192.168.1.100:8000` or `wss://your-server.com/ws/predict`).
    *   The app will automatically probe the connection. A green checkmark indicates success.
3.  **Play**: Start swinging! The app will visualize your motion and display the AI's classification result in real-time.

---

# Smart Racket AI App 🏸 (繁體中文)

這是一個基於 Flutter 開發的高階羽球智慧分析應用程式。作為 Smart Racket 系統的核心介面，它負責將球拍硬體 (ESP32) 的高頻感測數據橋接到後端 AI 推論引擎 (Python Server)，並為球員提供即時的視覺化回饋。

---

## ✨ 核心功能

### 1. 強大的 BLE 連線能力 (`BleService`)
*   **自動連線**：自動掃描並連線到名稱為 **"SmartRacket"** 的最近裝置。
*   **高效能串流**：使用 **Ring Buffer (環形緩衝區)** 架構處理高頻 BLE 通知，確保封包不丟失、不錯位。
*   **自訂協定**：解析包含時間戳記、六軸 IMU 數據 (加速度/角速度) 和電池電壓的 34-byte 自訂二進位封包。
*   **互動回饋**：掃描與連線過程中配有精美的波紋動畫與觸覺震動回饋。

### 2. 即時 AI 互動 (`WebSocketService`)
*   **低延遲傳輸**：透過 WebSocket (`ws://` 或 `wss://`) 將緩衝的感測器視窗資料串流至本地或雲端 Python 伺服器。
*   **智慧觸發**：僅在動作強度超過門檻時傳送資料，優化頻寬與伺服器負載。
*   **即時判讀**：數毫秒內接收並顯示 AI 分類結果（揮拍類型與球速）。
*   **支援動作類型**：
    *   **Smash** (殺球)
    *   **Drive** (平抽)
    *   **Drop** (切球)
    *   **Toss** (長球)
    *   **Other** (其他)

### 3. 專業數據視覺化
*   **六軸圖表**：使用 `fl_chart` 即時繪製加速度計與陀螺儀的波形圖。
*   **觸發波形檢視**：即時觀測送往伺服器辨識的感測器波形，讓使用者清楚知道被傳送進行推論的數據樣貌。
*   **揮拍統計**：自動計算並統計當次練習中各種球路的數量。
*   **伺服器探測**：內建 "Ping-less" 伺服器探測機制 (`probeOnce`)，快速驗證 AI 服務可用性。

### 4. MCU 狀態與除錯
*   **MCU Debug 視窗**：專用的除錯介面，可即時監控 MCU 的運作狀態。
*   **原始數據監控**：顯示原始封包日誌 (Raw Log)、連線穩定度與電池電壓。
*   **靈敏度調整**：可在除錯面板中直接調整動作觸發門檻。

### 5. 感測器校正
*   **歸零校正**：內建歸零校正功能，消除硬體安裝誤差，確保數據精準。

---

## 🛠 技術架構

本應用程式採用 **Flutter** 開發，並遵循 **Provider-based MVVM** 架構，確保責任分離與程式碼可維護性。

### 核心元件
*   **`HomeProvider`**：UI 的核心大腦。負責協調各個 Service 與 UI 之間的資料流，管理應用程式狀態（連線、統計、校正）。
*   **`BleService`**：管理藍牙低功耗 (BLE) 的掃描、連線與原始 Byte 解析。提供 `IMUData` 的廣播串流。
*   **`WebSocketService`**：管理與 AI Server 的長連線。處理 JSON 序列化/反序列化與心跳機制。
*   **`DataBufferManager`**：實作滑動視窗 (Sliding Window)，負責捕捉揮拍瞬間的完整數據供 AI 分析。

### 關鍵套件
*   `flutter_blue_plus`：提供穩定的 BLE 通訊能力。
*   `web_socket_channel`：與 Python AI Server 通訊。
*   `provider`：高效的狀態管理與依賴注入。
*   `fl_chart`：繪製高效能即時圖表。
