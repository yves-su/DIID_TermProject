# 🏸 智能羽毛球拍 IMU 感測器系統 - 完整技術文件

## 📋 目錄

1. [系統概述](#系統概述)
2. [硬體規格](#硬體規格)
3. [BLE 通訊協議詳解](#ble-通訊協議詳解)
4. [資料格式規格](#資料格式規格)
5. [手機端藍芽接收程式開發指南](#手機端藍芽接收程式開發指南)
6. [手機App結果展示與UI設計](#手機app結果展示與ui設計)
7. [姿態校正功能](#姿態校正功能)
8. [WiFi 資料傳輸至伺服器](#wifi-資料傳輸至伺服器)
9. [資料庫設計](#資料庫設計)
10. [AI 訓練資料準備](#ai-訓練資料準備)
11. [系統架構流程圖](#系統架構流程圖)
12. [開發注意事項](#開發注意事項)
13. [故障排除](#故障排除)

---

## 系統概述

本系統是一個智能羽毛球拍感測器，透過內嵌於球拍手柄的 IMU（慣性測量單元）感測器，即時採集球拍揮動時的加速度和角速度資料，透過 BLE（藍牙低功耗）傳輸至手機 App，再經由 WiFi 上傳至伺服器資料庫，最後用於 AI 模型訓練，以識別不同的球路（如殺球、抽球、其他等）。

### 核心功能流程

```
羽球拍感測器 → BLE傳輸 → 手機App（收集資料+展示結果） → WiFi上傳 → 伺服器資料庫 → AI訓練 → 球路識別
```

### 展示功能說明

本系統在展示時將使用相同的硬體設備進行揮拍測試，所有測試結果將直接在手機App上即時顯示：

- **即時資料收集**：手機App持續接收BLE傳輸的IMU資料
- **即時結果展示**：AI模型推理結果直接在手機螢幕上顯示
- **視覺化呈現**：提供圖表、動畫等多種展示方式
- **測試記錄**：保存每次揮拍的測試結果供後續查看

---

## 硬體規格

### 核心組件

| 組件 | 型號 | 規格 | 功能 |
|------|------|------|------|
| **主控板** | Seeed XIAO nRF52840 Sense | 20×17.5×5 mm | ARM Cortex-M4F, 256KB Flash, 32KB RAM |
| **感測器** | LSM6DS3TR | - | 六軸IMU（加速度計 + 陀螺儀） |
| **電池** | LIR2032 | 32×16×6 mm | 3.6V 鋰電池 |
| **充電接口** | Type-C | 5×8.5×3.5 mm | USB充電接口 |

### IMU 感測器參數

| 參數 | 加速度計 | 陀螺儀 |
|------|----------|--------|
| **資料輸出頻率 (ODR)** | 416 Hz | 416 Hz |
| **量測範圍** | ±16G | ±2000 dps |
| **帶寬設定** | 100 Hz | 400 Hz |
| **I²C 傳輸速率** | 400 kHz | 400 kHz |
| **解析度** | 16-bit | 16-bit |

### 硬體連接配置

```
球拍手柄內部配置：
├── Type-C接口（充電）
├── 主控板 (XIAO nRF52840 Sense)
│   ├── I2C 連接 LSM6DS3 (SDA, SCL)
│   ├── A0 類比輸入（電壓監控）
│   └── P0_13 數位輸出（充電模式控制）
└── 電池 (LIR2032)
```

---

## BLE 通訊協議詳解

### 設備識別資訊

- **設備名稱**: `SmartRacket`
- **藍牙版本**: Bluetooth 5.0 (BLE)
- **連接模式**: 主從模式（手機為主端，感測器為從端）

### BLE 服務架構

#### 1. 服務 UUID
```
0769bb8e-b496-4fdd-b53b-87462ff423d0
```

#### 2. 特徵 UUID (Characteristic)
```
8ee82f5b-76c7-4170-8f49-fff786257090
```

#### 3. 特徵屬性
- **讀取 (Read)**: 支援
- **通知 (Notify)**: 支援（主要使用此方式接收資料）
- **寫入 (Write)**: 不支援

### BLE 連接流程

```
1. 感測器啟動 → 初始化BLE服務 → 開始廣播 (Advertising)
2. 手機App → 掃描BLE設備 → 找到 "SmartRacket"
3. 手機App → 發起連接請求 (Connect Request)
4. 感測器 → 接受連接 → 建立BLE連接
5. 手機App → 訂閱通知 (Subscribe to Notify)
6. 感測器 → 開始發送IMU資料（每20ms一次）
```

### BLE 資料傳輸參數

- **傳輸頻率**: 50 Hz（每 20ms 傳送一次）
- **單次資料大小**: 30 bytes
- **傳輸方式**: BLE Notification（推播模式，無需手機主動讀取）
- **廣播間隔**: 100ms（未連接時）

### 連接狀態管理

```python
連接狀態檢查流程：
1. 持續監聽連接狀態
2. 連接中斷時自動重新廣播
3. 低電量時自動斷線並通知手機
4. 手機斷線後感測器進入省電模式
```

---

## 資料格式規格

### 資料封包結構（30 bytes）

#### 二進位格式（Little-Endian）

| 偏移量 | 長度 | 資料類型 | 欄位名稱 | 說明 |
|--------|------|----------|----------|------|
| 0-3 | 4 bytes | `uint32_t` | `timestamp` | 時間戳記（millis()，單位：毫秒） |
| 4-7 | 4 bytes | `float` | `accelX` | X軸加速度（單位：g，已校正） |
| 8-11 | 4 bytes | `float` | `accelY` | Y軸加速度（單位：g，已校正） |
| 12-15 | 4 bytes | `float` | `accelZ` | Z軸加速度（單位：g，已校正，已減去重力） |
| 16-19 | 4 bytes | `float` | `gyroX` | X軸角速度（單位：dps，已校正） |
| 20-23 | 4 bytes | `float` | `gyroY` | Y軸角速度（單位：dps，已校正） |
| 24-27 | 4 bytes | `float` | `gyroZ` | Z軸角速度（單位：dps，已校正） |
| 28-29 | 2 bytes | `uint16_t` | `voltageRaw` | 原始電壓讀值（0-1023，需除以100.0得到電壓） |

### 資料解析範例（Python）

```python
import struct

def parse_imu_data(data: bytes) -> dict:
    """
    解析30 bytes的IMU資料封包
    
    Args:
        data: 30 bytes的二進位資料
    
    Returns:
        dict: 包含所有感測器資料的字典
    """
    if len(data) != 30:
        raise ValueError(f"資料長度錯誤，應為30 bytes，實際為{len(data)} bytes")
    
    # 使用Little-Endian格式解析
    timestamp = struct.unpack('<I', data[0:4])[0]      # uint32_t
    accelX = struct.unpack('<f', data[4:8])[0]         # float
    accelY = struct.unpack('<f', data[8:12])[0]        # float
    accelZ = struct.unpack('<f', data[12:16])[0]       # float
    gyroX = struct.unpack('<f', data[16:20])[0]        # float
    gyroY = struct.unpack('<f', data[20:24])[0]        # float
    gyroZ = struct.unpack('<f', data[24:28])[0]        # float
    voltageRaw = struct.unpack('<H', data[28:30])[0]   # uint16_t
    
    # 計算實際電壓值
    voltage = voltageRaw / 100.0
    
    return {
        'timestamp': timestamp,        # 毫秒
        'accelX': accelX,             # g (重力加速度單位)
        'accelY': accelY,             # g
        'accelZ': accelZ,             # g
        'gyroX': gyroX,               # dps (度/秒)
        'gyroY': gyroY,               # dps
        'gyroZ': gyroZ,               # dps
        'voltage': voltage             # V (伏特)
    }
```

### 資料解析範例（JavaScript/TypeScript）

```typescript
interface IMUData {
    timestamp: number;
    accelX: number;
    accelY: number;
    accelZ: number;
    gyroX: number;
    gyroY: number;
    gyroZ: number;
    voltage: number;
}

function parseIMUData(buffer: ArrayBuffer): IMUData {
    const view = new DataView(buffer);
    
    let offset = 0;
    const timestamp = view.getUint32(offset, true); offset += 4;
    const accelX = view.getFloat32(offset, true); offset += 4;
    const accelY = view.getFloat32(offset, true); offset += 4;
    const accelZ = view.getFloat32(offset, true); offset += 4;
    const gyroX = view.getFloat32(offset, true); offset += 4;
    const gyroY = view.getFloat32(offset, true); offset += 4;
    const gyroZ = view.getFloat32(offset, true); offset += 4;
    const voltageRaw = view.getUint16(offset, true); offset += 2;
    
    return {
        timestamp,
        accelX,
        accelY,
        accelZ,
        gyroX,
        gyroY,
        gyroZ,
        voltage: voltageRaw / 100.0
    };
}
```

### 資料單位說明

- **加速度 (Acceleration)**: 
  - 單位：`g`（重力加速度，1g ≈ 9.8 m/s²）
  - 範圍：通常為 ±16g
  - 靜止狀態下，Z軸約為 1g（重力）

- **角速度 (Angular Velocity)**:
  - 單位：`dps`（度/秒，degrees per second）
  - 範圍：±2000 dps
  - 靜止狀態下，各軸應接近 0 dps

- **時間戳記 (Timestamp)**:
  - 單位：毫秒（milliseconds）
  - 來源：Arduino `millis()` 函數
  - 從系統啟動開始累計

### IMU 校正機制

感測器在首次連接時會自動進行校正：

1. **加速度計校正**：
   - 收集 100 筆資料計算平均值
   - Z軸減去 1g（重力加速度）
   - 用於補償靜止狀態下的偏移

2. **陀螺儀校正**：
   - 收集 100 筆資料計算平均值
   - 作為零點偏移補償

---

## 手機端藍芽接收程式開發指南

### 開發環境建議

#### Android (Kotlin/Java)

**必要權限 (AndroidManifest.xml)**
```xml
<!-- 藍牙權限 -->
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" android:usesPermissionFlags="neverForLocation" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />

<!-- 位置權限（Android 12以下需要） -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />

<!-- WiFi 和網路權限 -->
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<uses-permission android:name="android.permission.ACCESS_WIFI_STATE" />
```

**Gradle 依賴 (build.gradle)**
```gradle
dependencies {
    // BLE 支援（使用 Android BLE API）
    implementation 'com.polidea.rxandroidble2:rxandroidble:1.17.2'
    
    // 或使用 Google 的 BLE 庫
    implementation 'no.nordicsemi.android:ble:2.6.1'
    
    // HTTP 請求（用於上傳資料）
    implementation 'com.squareup.okhttp3:okhttp:4.12.0'
    implementation 'com.google.code.gson:gson:2.10.1'
}
```

#### Flutter (Dart)

**pubspec.yaml 依賴**
```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # BLE 藍牙庫
  flutter_blue_plus: ^1.32.0
  
  # HTTP 請求
  http: ^1.1.0
  
  # JSON 處理
  json_annotation: ^4.8.1
  
  # 資料庫（本地緩存）
  sqflite: ^2.3.0
  path: ^1.8.3
```

### BLE 連接實現範例（Flutter）

```dart
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:typed_data';

class BLEIMUReceiver {
  // BLE 服務和特徵 UUID
  static const String deviceName = "SmartRacket";
  static const String serviceUUID = "0769bb8e-b496-4fdd-b53b-87462ff423d0";
  static const String characteristicUUID = "8ee82f5b-76c7-4170-8f49-fff786257090";
  
  BluetoothDevice? connectedDevice;
  BluetoothCharacteristic? imuCharacteristic;
  bool isConnected = false;
  
  // 資料接收回調
  Function(Map<String, dynamic>)? onDataReceived;
  
  // 掃描並連接設備
  Future<bool> scanAndConnect() async {
    try {
      print("開始掃描BLE設備...");
      
      // 啟動藍牙掃描
      await FlutterBluePlus.startScan(timeout: Duration(seconds: 10));
      
      // 監聽掃描結果
      FlutterBluePlus.scanResults.listen((results) {
        for (ScanResult result in results) {
          if (result.device.platformName == deviceName || 
              result.device.advName == deviceName) {
            print("找到目標設備: ${result.device.platformName}");
            FlutterBluePlus.stopScan();
            connectToDevice(result.device);
            break;
          }
        }
      });
      
      return true;
    } catch (e) {
      print("掃描失敗: $e");
      return false;
    }
  }
  
  // 連接到設備
  Future<void> connectToDevice(BluetoothDevice device) async {
    try {
      print("正在連接設備...");
      await device.connect(timeout: Duration(seconds: 15));
      
      connectedDevice = device;
      
      // 監聽連接狀態
      device.connectionState.listen((state) {
        isConnected = (state == BluetoothConnectionState.connected);
        if (!isConnected) {
          print("設備已斷線");
        }
      });
      
      // 發現服務
      List<BluetoothService> services = await device.discoverServices();
      
      for (BluetoothService service in services) {
        if (service.uuid.toString().toLowerCase() == 
            serviceUUID.toLowerCase().replaceAll('-', '')) {
          
          // 找到目標特徵
          for (BluetoothCharacteristic characteristic in service.characteristics) {
            if (characteristic.uuid.toString().toLowerCase() == 
                characteristicUUID.toLowerCase().replaceAll('-', '')) {
              
              imuCharacteristic = characteristic;
              
              // 訂閱通知
              await characteristic.setNotifyValue(true);
              
              // 監聽資料
              characteristic.lastValueStream.listen((data) {
                parseAndHandleData(data);
              });
              
              print("BLE連接成功，開始接收資料");
              break;
            }
          }
        }
      }
    } catch (e) {
      print("連接失敗: $e");
    }
  }
  
  // 解析資料並觸發回調
  void parseAndHandleData(Uint8List data) {
    if (data.length != 30) {
      print("資料長度錯誤: ${data.length} bytes");
      return;
    }
    
    // 解析資料（Little-Endian）
    ByteData byteData = data.buffer.asByteData();
    
    int timestamp = byteData.getUint32(0, Endian.little);
    double accelX = byteData.getFloat32(4, Endian.little);
    double accelY = byteData.getFloat32(8, Endian.little);
    double accelZ = byteData.getFloat32(12, Endian.little);
    double gyroX = byteData.getFloat32(16, Endian.little);
    double gyroY = byteData.getFloat32(20, Endian.little);
    double gyroZ = byteData.getFloat32(24, Endian.little);
    int voltageRaw = byteData.getUint16(28, Endian.little);
    double voltage = voltageRaw / 100.0;
    
    Map<String, dynamic> imuData = {
      'timestamp': timestamp,
      'accelX': accelX,
      'accelY': accelY,
      'accelZ': accelZ,
      'gyroX': gyroX,
      'gyroY': gyroY,
      'gyroZ': gyroZ,
      'voltage': voltage,
      'receivedAt': DateTime.now().millisecondsSinceEpoch,
    };
    
    // 觸發回調
    if (onDataReceived != null) {
      onDataReceived!(imuData);
    }
  }
  
  // 斷開連接
  Future<void> disconnect() async {
    if (connectedDevice != null) {
      await connectedDevice!.disconnect();
      connectedDevice = null;
      imuCharacteristic = null;
      isConnected = false;
    }
  }
}
```

### 資料緩衝與處理

由於資料傳輸頻率為 50Hz，建議使用緩衝區管理資料：

```dart
class IMUDataBuffer {
  List<Map<String, dynamic>> buffer = [];
  static const int bufferSize = 200; // 緩存200筆資料（約4秒）
  
  void addData(Map<String, dynamic> data) {
    buffer.add(data);
    
    // 保持緩衝區大小
    if (buffer.length > bufferSize) {
      buffer.removeAt(0);
    }
  }
  
  // 取得最近N筆資料（用於AI分析）
  List<Map<String, dynamic>> getRecentData(int count) {
    if (buffer.length < count) {
      return List.from(buffer);
    }
    return buffer.sublist(buffer.length - count);
  }
  
  // 清空緩衝區
  void clear() {
    buffer.clear();
  }
}
```

---

## 手機App結果展示與UI設計

### 展示功能需求

手機App在展示時需要同時完成以下功能：

1. **即時資料收集**：持續接收BLE傳輸的IMU感測器資料
2. **即時AI推理**：使用本地TensorFlow Lite模型進行即時球路識別
3. **結果展示**：將識別結果以視覺化的方式呈現給使用者
4. **測試記錄**：保存每次揮拍的詳細資料和識別結果

### UI設計建議

#### 1. 主介面架構

建議採用Tab導航或底部導航欄設計，主要包含以下頁面：

```
┌─────────────────────────────────┐
│      智能羽球拍分析系統             │
├─────────────────────────────────┤
│                                 │
│  ┌─────┐  ┌─────┐  ┌─────┐    │
│  │首頁 │  │分析 │  │歷史 │    │
│  └─────┘  └─────┘  └─────┘    │
│                                 │
└─────────────────────────────────┘
```

#### 2. 即時測試頁面（首頁）

這是展示時的主要頁面，建議設計如下：

**上半部：連線狀態與即時資料顯示**
```
┌─────────────────────────────────┐
│  📶 SmartRacket  ✓ 已連接       │
│  電量: ████████░░ 80%          │
├─────────────────────────────────┤
│  即時感測器資料                  │
│  ┌─────────────────────────┐  │
│  │ 加速度: X Y Z            │  │
│  │ 角速度: X Y Z            │  │
│  └─────────────────────────┘  │
└─────────────────────────────────┘
```

**中間：AI識別結果展示區（重點）**
```
┌─────────────────────────────────┐
│      🎾 揮拍識別結果              │
│                                 │
│    ┌─────────────────────┐    │
│    │                     │    │
│    │    [殺球]           │    │
│    │                     │    │
│    │  信心度: 85%        │    │
│    │                     │    │
│    └─────────────────────┘    │
│                                 │
│  [準備揮拍] [開始測試] [結束]   │
└─────────────────────────────────┘
```

**下半部：即時波形圖**
```
┌─────────────────────────────────┐
│  即時資料波形                    │
│  ┌─────────────────────────┐  │
│  │  ▁▂▃▅▇█▇▅▃▂▁          │  │
│  │  (動態更新波形圖)         │  │
│  └─────────────────────────┘  │
└─────────────────────────────────┘
```

**UI元素建議：**
- 結果卡片使用大尺寸顯示，顏色區分不同球路類型：
  - 殺球：紅色系（#FF4444）
  - 抽球：藍色系（#4488FF）
  - 其他：灰色系（#888888）
- 信心度以進度條或圓形進度指示器顯示
- 結果顯示時加入動畫效果（如彈出、淡入等）
- 結果凍結顯示3-5秒，讓使用者清楚看到識別結果

#### 3. 測試結果詳細頁面

展示每次揮拍的詳細資訊：

```dart
class StrokeResultPage extends StatelessWidget {
  final StrokeResult result;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('揮拍結果詳情')),
      body: Column(
        children: [
          // 結果摘要卡片
          _buildResultCard(result),
          
          // 時間軸資訊
          _buildTimeline(result),
          
          // 詳細數據圖表
          _buildDataCharts(result),
          
          // 動作回放（可選）
          _buildReplaySection(result),
        ],
      ),
    );
  }
  
  Widget _buildResultCard(StrokeResult result) {
    return Card(
      color: _getStrokeColor(result.label),
      child: Padding(
        padding: EdgeInsets.all(24.0),
        child: Column(
          children: [
            Text(
              _getStrokeLabel(result.label),
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 16),
            Text(
              '信心度: ${(result.confidence * 100).toInt()}%',
              style: TextStyle(fontSize: 24, color: Colors.white70),
            ),
            SizedBox(height: 8),
            Text(
              '時間: ${_formatTime(result.timestamp)}',
              style: TextStyle(fontSize: 14, color: Colors.white60),
            ),
          ],
        ),
      ),
    );
  }
}
```

#### 4. 歷史記錄頁面

顯示所有測試記錄的列表：

```
┌─────────────────────────────────┐
│  測試記錄                        │
├─────────────────────────────────┤
│  🎾 殺球  85%  [今天 14:23]    │
│  🎾 抽球  72%  [今天 14:20]    │
│  🎾 其他  45%  [今天 14:15]    │
│  🎾 殺球  90%  [今天 14:10]    │
│  🎾 抽球  68%  [今天 14:05]    │
└─────────────────────────────────┘
```

#### 5. 圖表視覺化建議

**即時波形圖（fl_chart）**
```dart
import 'package:fl_chart/fl_chart.dart';

Widget buildRealTimeChart(List<IMUData> data) {
  return LineChart(
    LineChartData(
      lineBarsData: [
        LineChartBarData(
          spots: data.map((d) => FlSpot(
            d.timestamp.toDouble(),
            d.gyroY,
          )).toList(),
          isCurved: true,
          color: Colors.blue,
          barWidth: 2,
        ),
      ],
      titlesData: FlTitlesData(
        show: true,
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: true),
        ),
      ),
    ),
  );
}
```

**三軸加速度/角速度顯示**
- 使用3D指標球或2D平面投影顯示球拍姿態
- 實時更新，提供視覺回饋

#### 6. 動畫效果建議

**識別結果彈出動畫：**
```dart
class ResultAnimation extends StatefulWidget {
  final String label;
  final double confidence;
  
  @override
  _ResultAnimationState createState() => _ResultAnimationState();
}

class _ResultAnimationState extends State<ResultAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 500),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    
    _controller.forward();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: _buildResultCard(),
          ),
        );
      },
    );
  }
}
```

### 展示模式設計

為了在展示時有更好的效果，建議設計以下模式：

#### 1. 測試模式
- 清晰的開始/停止按鈕
- 測試過程中顯示即時資料
- 每次揮拍後立即顯示結果
- 結果持續顯示3-5秒後自動清除，準備下一次測試

#### 2. 演示模式
- 自動記錄模式，無需手動操作
- 連續測試多個揮拍動作
- 自動保存所有結果
- 可以回放測試過程

### 狀態管理建議

使用Flutter的狀態管理方案（如Provider、Riverpod）管理以下狀態：

```dart
class TestSessionState {
  bool isConnected = false;
  bool isRecording = false;
  List<StrokeResult> results = [];
  IMUData? currentData;
  String? currentPrediction;
  double? currentConfidence;
}
```

### 效能優化建議

1. **圖表更新頻率**：波形圖建議每秒更新10-20次即可，不需要50Hz
2. **結果快取**：識別結果快取顯示，避免頻繁重新計算
3. **背景處理**：AI推理在背景執行緒進行，避免阻塞UI

---

## 姿態校正功能

### 功能必要性說明

姿態校正是確保AI模型準確識別的重要功能，因為：

1. **感測器安裝差異**：不同球拍或不同安裝角度會導致感測器座標系與實際揮拍動作座標系不一致
2. **個人揮拍習慣**：不同使用者的揮拍姿勢和握拍方式可能有差異
3. **提高識別準確度**：經過校正後的資料能顯著提升AI模型的識別準確率

### 校正流程設計

#### 1. 校正模式觸發

建議在主介面設置中提供「校正姿態」選項：

```dart
class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('設定')),
      body: ListView(
        children: [
          ListTile(
            leading: Icon(Icons.tune),
            title: Text('校正姿態'),
            subtitle: Text('校準感測器姿態以提高識別準確度'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => CalibrationPage()),
            ),
          ),
          // 其他設定選項...
        ],
      ),
    );
  }
}
```

#### 2. 校正步驟設計

**步驟1：準備階段**
```
┌─────────────────────────────────┐
│  姿態校正                        │
├─────────────────────────────────┤
│                                 │
│  請將球拍放置在平坦表面         │
│  保持球拍靜止不動               │
│                                 │
│  準備好後請點擊「開始校正」      │
│                                 │
│      [取消]    [開始校正]        │
└─────────────────────────────────┘
```

**步驟2：靜止狀態採樣**
```dart
class CalibrationPage extends StatefulWidget {
  @override
  _CalibrationPageState createState() => _CalibrationPageState();
}

class _CalibrationPageState extends State<CalibrationPage> {
  List<IMUData> calibrationSamples = [];
  bool isCalibrating = false;
  int sampleCount = 0;
  static const int requiredSamples = 200; // 收集200筆資料（約4秒）
  
  void startCalibration() {
    setState(() {
      isCalibrating = true;
      sampleCount = 0;
      calibrationSamples.clear();
    });
    
    // 開始收集資料
    BLEIMUReceiver().onDataReceived = (data) {
      if (isCalibrating && sampleCount < requiredSamples) {
        setState(() {
          calibrationSamples.add(data);
          sampleCount++;
        });
        
        // 更新進度
        if (sampleCount % 10 == 0) {
          _updateProgress();
        }
      }
      
      if (sampleCount >= requiredSamples) {
        _completeCalibration();
      }
    };
  }
  
  void _completeCalibration() {
    // 計算校正參數
    CalibrationData calData = _calculateCalibration(calibrationSamples);
    
    // 保存校正參數
    _saveCalibrationData(calData);
    
    setState(() {
      isCalibrating = false;
    });
    
    // 顯示完成訊息
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('校正完成'),
        content: Text('姿態校正已完成，將應用於後續的揮拍識別'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('確定'),
          ),
        ],
      ),
    );
  }
  
  CalibrationData _calculateCalibration(List<IMUData> samples) {
    // 計算平均值作為偏移量
    double accelXOffset = samples.map((s) => s.accelX).reduce((a, b) => a + b) / samples.length;
    double accelYOffset = samples.map((s) => s.accelY).reduce((a, b) => a + b) / samples.length;
    double accelZOffset = samples.map((s) => s.accelZ).reduce((a, b) => a + b) / samples.length;
    
    double gyroXOffset = samples.map((s) => s.gyroX).reduce((a, b) => a + b) / samples.length;
    double gyroYOffset = samples.map((s) => s.gyroY).reduce((a, b) => a + b) / samples.length;
    double gyroZOffset = samples.map((s) => s.gyroZ).reduce((a, b) => a + b) / samples.length;
    
    // 計算重力方向（用於座標系轉換）
    double gravityMagnitude = sqrt(
      pow(accelXOffset, 2) + 
      pow(accelYOffset, 2) + 
      pow(accelZOffset, 2)
    );
    
    return CalibrationData(
      accelOffset: Offset3D(accelXOffset, accelYOffset, accelZOffset),
      gyroOffset: Offset3D(gyroXOffset, gyroYOffset, gyroZOffset),
      gravityDirection: Vector3D(
        accelXOffset / gravityMagnitude,
        accelYOffset / gravityMagnitude,
        accelZOffset / gravityMagnitude,
      ),
    );
  }
}
```

**校正進度顯示：**
```
┌─────────────────────────────────┐
│  校正中...                      │
│                                 │
│  ████████░░░░░░░░░░ 40%         │
│                                 │
│  請保持球拍靜止不動             │
│  剩餘時間: 2.4 秒               │
│                                 │
└─────────────────────────────────┘
```

#### 3. 校正資料應用

校正後的資料需要在資料處理時應用：

```dart
class CalibratedIMUProcessor {
  CalibrationData? calibrationData;
  
  IMUData applyCalibration(IMUData rawData) {
    if (calibrationData == null) {
      return rawData; // 未校正則返回原始資料
    }
    
    return IMUData(
      timestamp: rawData.timestamp,
      // 減去偏移量
      accelX: rawData.accelX - calibrationData!.accelOffset.x,
      accelY: rawData.accelY - calibrationData!.accelOffset.y,
      accelZ: rawData.accelZ - calibrationData!.accelOffset.z,
      
      gyroX: rawData.gyroX - calibrationData!.gyroOffset.x,
      gyroY: rawData.gyroY - calibrationData!.gyroOffset.y,
      gyroZ: rawData.gyroZ - calibrationData!.gyroOffset.z,
      
      voltage: rawData.voltage,
    );
  }
  
  // 座標系轉換（可選，根據需求實現）
  IMUData transformCoordinate(IMUData calibratedData) {
    // 根據重力方向進行座標系旋轉
    // 實現細節依需求而定
    return calibratedData;
  }
}
```

#### 4. 校正資料儲存

使用本地儲存保存校正參數：

```dart
class CalibrationStorage {
  static const String calibrationKey = 'imu_calibration_data';
  
  Future<void> saveCalibration(CalibrationData data) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(data.toJson());
    await prefs.setString(calibrationKey, jsonString);
  }
  
  Future<CalibrationData?> loadCalibration() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(calibrationKey);
    
    if (jsonString == null) return null;
    
    final json = jsonDecode(jsonString);
    return CalibrationData.fromJson(json);
  }
  
  Future<void> clearCalibration() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(calibrationKey);
  }
}
```

### 校正時機建議

1. **首次使用**：App首次啟動時提示使用者進行校正
2. **更換設備**：更換球拍或重新安裝感測器後
3. **定期校正**：建議每次使用前校正（可在設定中選擇是否自動提示）
4. **手動觸發**：使用者可在設定中隨時重新校正

### 校正驗證

校正完成後，可以進行簡單的驗證：

```dart
bool validateCalibration(CalibrationData calData) {
  // 驗證重力方向是否合理
  double gravityMag = sqrt(
    pow(calData.gravityDirection.x, 2) +
    pow(calData.gravityDirection.y, 2) +
    pow(calData.gravityDirection.z, 2)
  );
  
  // 重力大小應接近1g
  if (gravityMag < 0.8 || gravityMag > 1.2) {
    return false; // 校正資料異常
  }
  
  // 驗證陀螺儀偏移是否在合理範圍內
  if (calData.gyroOffset.magnitude > 50) { // 50 dps
    return false; // 陀螺儀偏移過大
  }
  
  return true;
}
```

### 進階校正功能（可選）

如果需要更高精度，可以實現多方位校正：

1. **多角度校正**：讓使用者將球拍置於不同角度進行校正
2. **動態校正**：進行特定動作（如標準揮拍）來校正
3. **個人化校正**：根據使用者的揮拍習慣進行個人化調整

---

## WiFi 資料傳輸至伺服器

### 資料上傳策略

#### 1. 即時上傳（推薦用於訓練資料收集）

每收到一筆資料立即上傳至伺服器：

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';

class DataUploader {
  static const String serverUrl = "https://your-server.com/api/imu-data";
  
  // 單筆資料上傳
  Future<bool> uploadSingleData(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse(serverUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'device_id': 'SmartRacket_001', // 設備識別碼
          'timestamp': data['timestamp'],
          'accelX': data['accelX'],
          'accelY': data['accelY'],
          'accelZ': data['accelZ'],
          'gyroX': data['gyroX'],
          'gyroY': data['gyroY'],
          'gyroZ': data['gyroZ'],
          'voltage': data['voltage'],
          'received_at': data['receivedAt'],
        }),
      );
      
      return response.statusCode == 200;
    } catch (e) {
      print("上傳失敗: $e");
      return false;
    }
  }
  
  // 批次上傳（用於離線緩存資料）
  Future<bool> uploadBatchData(List<Map<String, dynamic>> dataList) async {
    try {
      final response = await http.post(
        Uri.parse("$serverUrl/batch"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'device_id': 'SmartRacket_001',
          'data': dataList,
        }),
      );
      
      return response.statusCode == 200;
    } catch (e) {
      print("批次上傳失敗: $e");
      return false;
    }
  }
}
```

#### 2. 批次上傳（節省網路資源）

將資料暫存本地，定期批量上傳：

```dart
class BatchUploadManager {
  List<Map<String, dynamic>> pendingData = [];
  Timer? uploadTimer;
  
  void startBatchUpload() {
    // 每10秒上傳一次
    uploadTimer = Timer.periodic(Duration(seconds: 10), (timer) {
      if (pendingData.isNotEmpty) {
        _uploadBatch();
      }
    });
  }
  
  void addData(Map<String, dynamic> data) {
    pendingData.add(data);
    
    // 如果緩存超過500筆，立即上傳
    if (pendingData.length >= 500) {
      _uploadBatch();
    }
  }
  
  Future<void> _uploadBatch() async {
    if (pendingData.isEmpty) return;
    
    List<Map<String, dynamic>> dataToUpload = List.from(pendingData);
    pendingData.clear();
    
    bool success = await DataUploader().uploadBatchData(dataToUpload);
    
    if (!success) {
      // 上傳失敗，重新加入待上傳列表
      pendingData.insertAll(0, dataToUpload);
    }
  }
}
```

### 離線資料緩存

使用本地資料庫儲存未上傳的資料：

```dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalDataCache {
  static Database? _database;
  
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }
  
  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'imu_data.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) {
        return db.execute('''
          CREATE TABLE imu_data(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            device_id TEXT,
            timestamp INTEGER,
            accelX REAL,
            accelY REAL,
            accelZ REAL,
            gyroX REAL,
            gyroY REAL,
            gyroZ REAL,
            voltage REAL,
            received_at INTEGER,
            uploaded INTEGER DEFAULT 0
          )
        ''');
      },
    );
  }
  
  Future<void> insertData(Map<String, dynamic> data) async {
    final db = await database;
    await db.insert('imu_data', {
      'device_id': 'SmartRacket_001',
      'timestamp': data['timestamp'],
      'accelX': data['accelX'],
      'accelY': data['accelY'],
      'accelZ': data['accelZ'],
      'gyroX': data['gyroX'],
      'gyroY': data['gyroY'],
      'gyroZ': data['gyroZ'],
      'voltage': data['voltage'],
      'received_at': data['receivedAt'],
      'uploaded': 0,
    });
  }
  
  Future<List<Map<String, dynamic>>> getUnuploadedData() async {
    final db = await database;
    return await db.query(
      'imu_data',
      where: 'uploaded = ?',
      whereArgs: [0],
      orderBy: 'timestamp ASC',
    );
  }
  
  Future<void> markAsUploaded(List<int> ids) async {
    final db = await database;
    for (int id in ids) {
      await db.update(
        'imu_data',
        {'uploaded': 1},
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }
}
```

---

## 資料庫設計

### 建議的資料庫結構（MySQL/PostgreSQL）

#### 主要資料表：`imu_raw_data`

```sql
CREATE TABLE imu_raw_data (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    device_id VARCHAR(50) NOT NULL,
    timestamp BIGINT NOT NULL,
    accel_x FLOAT NOT NULL,
    accel_y FLOAT NOT NULL,
    accel_z FLOAT NOT NULL,
    gyro_x FLOAT NOT NULL,
    gyro_y FLOAT NOT NULL,
    gyro_z FLOAT NOT NULL,
    voltage FLOAT,
    received_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    uploaded_at TIMESTAMP,
    INDEX idx_device_timestamp (device_id, timestamp),
    INDEX idx_received_at (received_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

#### 訓練資料表：`training_data`

```sql
CREATE TABLE training_data (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    session_id VARCHAR(100) NOT NULL,
    device_id VARCHAR(50) NOT NULL,
    label VARCHAR(20) NOT NULL,  -- 'smash', 'drive', 'other'
    start_timestamp BIGINT NOT NULL,
    end_timestamp BIGINT NOT NULL,
    data_frame JSON,  -- 儲存40筆資料的陣列
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_session (session_id),
    INDEX idx_label (label)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

#### 球路識別結果表：`stroke_recognition`

```sql
CREATE TABLE stroke_recognition (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    device_id VARCHAR(50) NOT NULL,
    session_id VARCHAR(100) NOT NULL,
    predicted_label VARCHAR(20) NOT NULL,
    confidence FLOAT NOT NULL,
    timestamp BIGINT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_device_session (device_id, session_id),
    INDEX idx_timestamp (timestamp)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

### RESTful API 設計建議

#### 1. 上傳單筆IMU資料
```
POST /api/v1/imu-data
Content-Type: application/json

Request Body:
{
  "device_id": "SmartRacket_001",
  "timestamp": 1234567890,
  "accelX": 0.123,
  "accelY": -0.456,
  "accelZ": 0.789,
  "gyroX": 12.34,
  "gyroY": -56.78,
  "gyroZ": 90.12,
  "voltage": 3.65,
  "received_at": 1234567890123
}

Response:
{
  "status": "success",
  "data_id": 12345,
  "message": "Data uploaded successfully"
}
```

#### 2. 批次上傳IMU資料
```
POST /api/v1/imu-data/batch
Content-Type: application/json

Request Body:
{
  "device_id": "SmartRacket_001",
  "data": [
    { "timestamp": 1234567890, "accelX": 0.123, ... },
    { "timestamp": 1234567910, "accelX": 0.124, ... },
    ...
  ]
}

Response:
{
  "status": "success",
  "uploaded_count": 50,
  "message": "Batch data uploaded successfully"
}
```

#### 3. 上傳標記的訓練資料
```
POST /api/v1/training-data
Content-Type: application/json

Request Body:
{
  "session_id": "session_20241201_001",
  "device_id": "SmartRacket_001",
  "label": "smash",
  "start_timestamp": 1234567890,
  "end_timestamp": 1234568690,
  "data_frame": [
    { "timestamp": 1234567890, "accelX": 0.123, ... },
    { "timestamp": 1234567910, "accelX": 0.124, ... },
    ... (40筆資料)
  ]
}

Response:
{
  "status": "success",
  "training_data_id": 67890,
  "message": "Training data saved successfully"
}
```

---

## AI 訓練資料準備

### 資料格式要求

#### 1. 時間窗口切割

AI 模型需要固定長度的輸入，建議使用**40筆資料**作為一個分析窗口（對應約 0.8 秒的資料）：

```python
def create_data_frames(raw_data, window_size=40):
    """
    將原始資料切割成固定長度的frame
    
    Args:
        raw_data: List[dict] - 原始IMU資料列表
        window_size: int - 每個frame的資料筆數（預設40）
    
    Returns:
        List[List[dict]] - 切割後的資料frame列表
    """
    frames = []
    for i in range(len(raw_data) - window_size + 1):
        frame = raw_data[i:i + window_size]
        frames.append(frame)
    return frames
```

#### 2. 特徵提取

每個frame需要轉換為模型輸入格式 `[1, 40, 6, 1]`：

- **批次大小**: 1
- **時間點**: 40（40筆資料）
- **特徵數**: 6（accelX, accelY, accelZ, gyroX, gyroY, gyroZ）
- **通道數**: 1

```python
import numpy as np

def frame_to_model_input(frame):
    """
    將資料frame轉換為模型輸入格式
    
    Args:
        frame: List[dict] - 40筆IMU資料
    
    Returns:
        numpy.ndarray - 形狀為 (1, 40, 6, 1) 的陣列
    """
    features = []
    for data in frame:
        features.append([
            data['accelX'],
            data['accelY'],
            data['accelZ'],
            data['gyroX'],
            data['gyroY'],
            data['gyroZ']
        ])
    
    # 轉換為 numpy 陣列
    array = np.array(features, dtype=np.float32)
    
    # 重塑為 (1, 40, 6, 1)
    array = array.reshape(1, 40, 6, 1)
    
    return array
```

### 資料標記流程

#### 1. 自動峰值偵測

根據感測器資料的峰值來識別擊球動作：

```python
def detect_peak_frames(data, threshold_std=2.0):
    """
    透過標準差偵測峰值（擊球動作）
    
    Args:
        data: List[dict] - IMU資料列表
        threshold_std: float - 標準差閾值
    
    Returns:
        List[int] - 峰值索引列表
    """
    # 提取gY軸資料作為主要判斷依據
    gyY_values = [d['gyroY'] for d in data]
    
    mean = np.mean(gyY_values)
    std = np.std(gyY_values)
    
    peaks = []
    for i in range(len(gyY_values)):
        if abs(gyY_values[i] - mean) > threshold_std * std:
            peaks.append(i)
    
    return peaks

def create_labeled_frames(raw_data, peak_indices, label):
    """
    根據峰值建立標記的資料frame
    
    Args:
        raw_data: List[dict] - 原始資料
        peak_indices: List[int] - 峰值索引
        label: str - 標籤（'smash', 'drive', 'other'）
    
    Returns:
        List[dict] - 標記的frame列表
    """
    frames = []
    for peak_idx in peak_indices:
        # 峰值前19筆 + 峰值 + 後20筆 = 40筆
        start_idx = max(0, peak_idx - 19)
        end_idx = min(len(raw_data), peak_idx + 21)
        
        frame = raw_data[start_idx:end_idx]
        
        if len(frame) == 40:
            frames.append({
                'label': label,
                'data': frame,
                'peak_index': peak_idx
            })
    
    return frames
```

#### 2. 手動標記工具

建議開發一個標記工具，讓使用者可以：
- 視覺化顯示IMU資料波形
- 手動標記擊球動作的開始和結束時間
- 選擇球路類別（smash、drive、other）

### 資料預處理

#### 1. 資料標準化

```python
def normalize_frame(frame, mean=None, std=None):
    """
    標準化資料frame（Z-score標準化）
    
    Args:
        frame: numpy.ndarray - 原始資料frame
        mean: numpy.ndarray - 預計算的平均值（用於測試資料）
        std: numpy.ndarray - 預計算的標準差（用於測試資料）
    
    Returns:
        tuple: (標準化後的frame, mean, std)
    """
    if mean is None or std is None:
        mean = np.mean(frame, axis=0, keepdims=True)
        std = np.std(frame, axis=0, keepdims=True)
    
    # 避免除以零
    std = np.where(std == 0, 1, std)
    
    normalized = (frame - mean) / std
    
    return normalized, mean, std
```

#### 2. 資料增強

```python
def augment_data(frames, noise_factor=0.01):
    """
    添加雜訊進行資料增強
    
    Args:
        frames: List[numpy.ndarray] - 原始frame列表
        noise_factor: float - 雜訊強度
    
    Returns:
        List[numpy.ndarray] - 增強後的frame列表
    """
    augmented = []
    for frame in frames:
        noise = np.random.normal(0, noise_factor, frame.shape)
        augmented_frame = frame + noise
        augmented.append(augmented_frame)
    
    return augmented
```

### 資料集組織

```
training_data/
├── smash/
│   ├── frame_001.npy
│   ├── frame_002.npy
│   └── ...
├── drive/
│   ├── frame_001.npy
│   ├── frame_002.npy
│   └── ...
└── other/
    ├── frame_001.npy
    ├── frame_002.npy
    └── ...
```

---

## 系統架構流程圖

### 完整資料流程

```
┌─────────────────┐
│   羽球拍感測器    │
│  (Arduino IMU)  │
└────────┬────────┘
         │ BLE (50Hz)
         │ 30 bytes/packet
         ▼
┌─────────────────┐
│   手機App接收    │
│  (BLE Client)   │
│  - 解析資料      │
│  - 緩衝管理      │
└────────┬────────┘
         │
         ├─────────────────┐
         │                 │
         ▼                 ▼
┌─────────────────┐  ┌─────────────────┐
│   本地資料庫     │  │   WiFi上傳      │
│  (SQLite緩存)   │  │   (HTTP/HTTPS)  │
└─────────────────┘  └────────┬────────┘
                              │
                              ▼
                      ┌─────────────────┐
                      │   伺服器資料庫   │
                      │  (MySQL/PostgreSQL)
                      └────────┬────────┘
                               │
                               ▼
                      ┌─────────────────┐
                      │   AI訓練模組     │
                      │  - 資料預處理    │
                      │  - 模型訓練      │
                      │  - 模型部署      │
                      └─────────────────┘
```

### 手機App模組架構

```
┌─────────────────────────────────────┐
│          手機App架構                │
├─────────────────────────────────────┤
│                                     │
│  ┌──────────────┐                  │
│  │  BLE Manager │                  │
│  │  - 掃描設備  │                  │
│  │  - 連接管理  │                  │
│  │  - 資料接收  │                  │
│  └──────┬───────┘                  │
│         │                           │
│  ┌──────▼───────┐                  │
│  │ Data Parser  │                  │
│  │  - 解析30bytes│                 │
│  │  - 資料驗證   │                  │
│  └──────┬───────┘                  │
│         │                           │
│  ┌──────▼───────┐                  │
│  │ Data Buffer  │                  │
│  │  - 滑動窗口  │                  │
│  │  - 40筆frame │                  │
│  └──────┬───────┘                  │
│         │                           │
│  ├──────┴───────┬──────────────────┤
│  │              │                  │
│  ▼              ▼                  │
│  ┌──────────┐  ┌──────────────┐   │
│  │  AI推理   │  │  Data Upload │   │
│  │  (TFLite)│  │  - WiFi上傳  │   │
│  │          │  │  - 本地緩存  │   │
│  └──────────┘  └──────────────┘   │
│                                     │
└─────────────────────────────────────┘
```

---

## 開發注意事項

### BLE 連接注意事項

1. **連接超時處理**：
   - 設定合理的連接超時時間（建議15秒）
   - 連接失敗時提供重試機制

2. **斷線重連機制**：
   - 監聽連接狀態變化
   - 自動重新掃描和連接
   - 顯示連接狀態給使用者

3. **資料接收穩定性**：
   - 檢查接收到的資料長度（必須為30 bytes）
   - 處理資料解析錯誤
   - 記錄錯誤日誌用於除錯

### 網路傳輸注意事項

1. **WiFi 狀態檢查**：
   - 上傳前檢查WiFi連接狀態
   - WiFi未連接時將資料暫存本地

2. **資料上傳失敗處理**：
   - 實現重試機制（最多3次）
   - 失敗的資料存入本地資料庫
   - 定期檢查並重新上傳未成功的資料

3. **電池消耗優化**：
   - 批次上傳減少網路請求次數
   - 使用背景任務處理上傳
   - 避免過於頻繁的網路請求

### 資料處理注意事項

1. **時間戳記同步**：
   - 手機接收時間與感測器時間的差異
   - 建議記錄手機本地時間戳記
   - 伺服器端統一使用UTC時間

2. **資料品質控制**：
   - 檢查感測器資料的有效範圍
   - 過濾異常值（如全0或極大值）
   - 驗證時間戳記的連續性

3. **記憶體管理**：
   - 避免在記憶體中累積過多資料
   - 定期清理已處理的資料
   - 使用適當的資料結構大小

---

## 故障排除

### BLE 連接問題

#### 問題1：無法掃描到設備

**可能原因**：
- 感測器未啟動或BLE未廣播
- 手機藍牙未開啟
- 設備距離過遠

**解決方法**：
1. 檢查Arduino程式是否正確上傳
2. 確認感測器LED指示燈狀態
3. 檢查手機藍牙權限
4. 靠近感測器（建議1米內）

#### 問題2：連接後立即斷線

**可能原因**：
- BLE服務UUID不匹配
- 特徵UUID不匹配
- 手機BLE驅動問題

**解決方法**：
1. 檢查UUID是否完全一致（包含大小寫）
2. 確認BLE服務和特徵是否正確發現
3. 嘗試重新啟動手機藍牙
4. 檢查Arduino程式中的BLE設定

#### 問題3：資料接收不穩定

**可能原因**：
- 傳輸頻率過高
- BLE訊號干擾
- 手機處理效能不足

**解決方法**：
1. 降低資料傳輸頻率（修改Arduino程式）
2. 遠離WiFi路由器等干擾源
3. 檢查手機是否有其他BLE連接占用頻寬
4. 優化資料接收處理邏輯

### 資料解析問題

#### 問題1：資料長度錯誤

**症狀**：收到非30 bytes的資料

**解決方法**：
```dart
if (data.length != 30) {
  print("警告：收到異常長度的資料 ${data.length} bytes");
  return; // 跳過此筆資料
}
```

#### 問題2：資料值異常

**症狀**：加速度或角速度值超出合理範圍

**解決方法**：
```dart
bool validateData(Map<String, dynamic> data) {
  // 加速度範圍：-16g ~ +16g
  if (data['accelX'].abs() > 16 || 
      data['accelY'].abs() > 16 || 
      data['accelZ'].abs() > 16) {
    return false;
  }
  
  // 角速度範圍：-2000 ~ +2000 dps
  if (data['gyroX'].abs() > 2000 || 
      data['gyroY'].abs() > 2000 || 
      data['gyroZ'].abs() > 2000) {
    return false;
  }
  
  return true;
}
```

### 網路傳輸問題

#### 問題1：上傳失敗

**可能原因**：
- 網路連接不穩定
- 伺服器API錯誤
- 資料格式錯誤

**解決方法**：
1. 實現重試機制
2. 檢查HTTP狀態碼和錯誤訊息
3. 驗證JSON格式是否正確
4. 檢查伺服器日誌

#### 問題2：資料遺失

**可能原因**：
- 上傳失敗但未保存
- 本地資料庫寫入失敗
- 應用程式意外關閉

**解決方法**：
1. 所有資料先存入本地資料庫
2. 上傳成功後才標記為已上傳
3. 定期檢查並重新上傳未成功的資料
4. 使用事務確保資料一致性

---

## 參考資源

### 官方文件

- [Seeed XIAO nRF52840 Sense 文件](https://wiki.seeedstudio.com/XIAO_BLE/)
- [ArduinoBLE 函式庫文件](https://www.arduino.cc/reference/en/libraries/arduinoble/)
- [Flutter Blue Plus 文件](https://pub.dev/packages/flutter_blue_plus)
- [BLE 規格文件](https://www.bluetooth.com/specifications/specs/core-specification/)

### 範例程式碼位置

- **Arduino主程式**: `src/main/main.ino`
- **Windows接收程式**: `APP/windows/visualizer/ble_imu_receiver.py`
- **過往專案範例**: `examples/Past_Student_Projects/codes/`

### 開發工具建議

- **BLE掃描工具**: 
  - Android: nRF Connect
  - iOS: LightBlue
- **資料視覺化**: 
  - Python: Matplotlib, Plotly
  - Flutter: fl_chart
- **API測試**: Postman, curl

---

## 聯絡資訊

如有技術問題，請聯絡專案團隊或查閱專案README文件。

---

**文件版本**: v1.1  
**最後更新**: 2025年11月  
**維護者**: DIID Term Project Team  
**更新內容**: 
- 新增手機App結果展示與UI設計章節
- 新增姿態校正功能章節
- 更新系統概述，說明展示功能需求

