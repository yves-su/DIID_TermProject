# 🏸 Smart Badminton Racket IMU Sensor System - Complete Technical Documentation

## 📋 Table of Contents

1. [System Overview](#system-overview)
2. [Hardware Specifications](#hardware-specifications)
3. [BLE Communication Protocol](#ble-communication-protocol)
4. [Data Format Specifications](#data-format-specifications)
5. [Mobile BLE Receiver Development Guide](#mobile-ble-receiver-development-guide)
6. [Mobile App Results Display & UI Design](#mobile-app-results-display--ui-design)
7. [Pose Calibration Function](#pose-calibration-function)
8. [WiFi Data Transmission to Server](#wifi-data-transmission-to-server)
9. [Database Design](#database-design)
10. [AI Training Data Preparation](#ai-training-data-preparation)
11. [System Architecture Flowchart](#system-architecture-flowchart)
12. [Development Notes](#development-notes)
13. [Troubleshooting](#troubleshooting)

---

## System Overview

This system is an intelligent badminton racket sensor that uses an IMU (Inertial Measurement Unit) sensor embedded in the racket handle to collect acceleration and angular velocity data in real-time during racket swings. The data is transmitted to a mobile App via BLE (Bluetooth Low Energy), then uploaded to a server database via WiFi, and finally used for AI model training to identify different stroke types (such as smash, drive, and others).

### Core Function Flow

```
Badminton Racket Sensor → BLE Transmission → Mobile App (Data Collection + Results Display) → WiFi Upload → Server Database → AI Training → Stroke Recognition
```

### Demo Function Description

During demonstrations, the system will use the same hardware equipment for stroke testing, and all test results will be displayed in real-time directly on the mobile App:

- **Real-time Data Collection**: The mobile App continuously receives IMU data transmitted via BLE
- **Real-time Results Display**: AI model inference results are displayed directly on the mobile screen
- **Visualization**: Provides various display methods such as charts and animations
- **Test Records**: Saves test results for each stroke for later viewing

---

## Hardware Specifications

### Core Components

| Component | Model | Specifications | Function |
|-----------|-------|----------------|----------|
| **Main Board** | Seeed XIAO nRF52840 Sense | 20×17.5×5 mm | ARM Cortex-M4F, 256KB Flash, 32KB RAM |
| **Sensor** | LSM6DS3TR | - | Six-axis IMU (Accelerometer + Gyroscope) |
| **Battery** | LIR2032 | 32×16×6 mm | 3.6V Lithium Battery |
| **Charging Interface** | Type-C | 5×8.5×3.5 mm | USB Charging Interface |

### IMU Sensor Parameters

| Parameter | Accelerometer | Gyroscope |
|-----------|---------------|-----------|
| **Data Output Rate (ODR)** | 416 Hz | 416 Hz |
| **Measurement Range** | ±16G | ±2000 dps |
| **Bandwidth Setting** | 100 Hz | 400 Hz |
| **I²C Transmission Rate** | 400 kHz | 400 kHz |
| **Resolution** | 16-bit | 16-bit |

### Hardware Connection Configuration

```
Racket Handle Internal Configuration:
├── Type-C Interface (Charging)
├── Main Board (XIAO nRF52840 Sense)
│   ├── I2C Connection to LSM6DS3 (SDA, SCL)
│   ├── A0 Analog Input (Voltage Monitoring)
│   └── P0_13 Digital Output (Charging Mode Control)
└── Battery (LIR2032)
```

---

## BLE Communication Protocol

### Device Identification Information

- **Device Name**: `SmartRacket`
- **Bluetooth Version**: Bluetooth 5.0 (BLE)
- **Connection Mode**: Master-Slave Mode (Mobile phone as master, sensor as slave)

### BLE Service Architecture

#### 1. Service UUID
```
0769bb8e-b496-4fdd-b53b-87462ff423d0
```

#### 2. Characteristic UUID
```
8ee82f5b-76c7-4170-8f49-fff786257090
```

#### 3. Characteristic Properties
- **Read**: Supported
- **Notify**: Supported (Main method for receiving data)
- **Write**: Not Supported

### BLE Connection Flow

```
1. Sensor Startup → Initialize BLE Service → Start Advertising
2. Mobile App → Scan BLE Devices → Find "SmartRacket"
3. Mobile App → Initiate Connection Request
4. Sensor → Accept Connection → Establish BLE Connection
5. Mobile App → Subscribe to Notify
6. Sensor → Start Sending IMU Data (every 20ms)
```

### BLE Data Transmission Parameters

- **Transmission Frequency**: 50 Hz (transmit every 20ms)
- **Single Data Size**: 30 bytes
- **Transmission Method**: BLE Notification (Push mode, no need for mobile to actively read)
- **Advertising Interval**: 100ms (when not connected)

### Connection Status Management

```python
Connection Status Check Flow:
1. Continuously monitor connection status
2. Automatically re-advertise when connection is interrupted
3. Automatically disconnect and notify mobile when battery is low
4. Sensor enters power-saving mode after mobile disconnects
```

---

## Data Format Specifications

### Data Packet Structure (30 bytes)

#### Binary Format (Little-Endian)

| Offset | Length | Data Type | Field Name | Description |
|--------|--------|-----------|------------|-------------|
| 0-3 | 4 bytes | `uint32_t` | `timestamp` | Timestamp (millis(), unit: milliseconds) |
| 4-7 | 4 bytes | `float` | `accelX` | X-axis acceleration (unit: g, calibrated) |
| 8-11 | 4 bytes | `float` | `accelY` | Y-axis acceleration (unit: g, calibrated) |
| 12-15 | 4 bytes | `float` | `accelZ` | Z-axis acceleration (unit: g, calibrated, gravity subtracted) |
| 16-19 | 4 bytes | `float` | `gyroX` | X-axis angular velocity (unit: dps, calibrated) |
| 20-23 | 4 bytes | `float` | `gyroY` | Y-axis angular velocity (unit: dps, calibrated) |
| 24-27 | 4 bytes | `float` | `gyroZ` | Z-axis angular velocity (unit: dps, calibrated) |
| 28-29 | 2 bytes | `uint16_t` | `voltageRaw` | Raw voltage reading (0-1023, divide by 100.0 to get voltage) |

### Data Parsing Example (Python)

```python
import struct

def parse_imu_data(data: bytes) -> dict:
    """
    Parse 30 bytes IMU data packet
    
    Args:
        data: 30 bytes of binary data
    
    Returns:
        dict: Dictionary containing all sensor data
    """
    if len(data) != 30:
        raise ValueError(f"Data length error, should be 30 bytes, actually {len(data)} bytes")
    
    # Parse using Little-Endian format
    timestamp = struct.unpack('<I', data[0:4])[0]      # uint32_t
    accelX = struct.unpack('<f', data[4:8])[0]         # float
    accelY = struct.unpack('<f', data[8:12])[0]        # float
    accelZ = struct.unpack('<f', data[12:16])[0]       # float
    gyroX = struct.unpack('<f', data[16:20])[0]        # float
    gyroY = struct.unpack('<f', data[20:24])[0]        # float
    gyroZ = struct.unpack('<f', data[24:28])[0]        # float
    voltageRaw = struct.unpack('<H', data[28:30])[0]   # uint16_t
    
    # Calculate actual voltage value
    voltage = voltageRaw / 100.0
    
    return {
        'timestamp': timestamp,        # milliseconds
        'accelX': accelX,             # g (gravity acceleration unit)
        'accelY': accelY,             # g
        'accelZ': accelZ,             # g
        'gyroX': gyroX,               # dps (degrees per second)
        'gyroY': gyroY,               # dps
        'gyroZ': gyroZ,               # dps
        'voltage': voltage             # V (volts)
    }
```

### Data Parsing Example (JavaScript/TypeScript)

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

### Data Unit Description

- **Acceleration**: 
  - Unit: `g` (gravity acceleration, 1g ≈ 9.8 m/s²)
  - Range: Usually ±16g
  - At rest, Z-axis is approximately 1g (gravity)

- **Angular Velocity**:
  - Unit: `dps` (degrees per second)
  - Range: ±2000 dps
  - At rest, all axes should be close to 0 dps

- **Timestamp**:
  - Unit: milliseconds
  - Source: Arduino `millis()` function
  - Accumulated from system startup

### IMU Calibration Mechanism

The sensor automatically performs calibration when first connected:

1. **Accelerometer Calibration**:
   - Collect 100 data points to calculate average
   - Subtract 1g from Z-axis (gravity acceleration)
   - Used to compensate for offset in resting state

2. **Gyroscope Calibration**:
   - Collect 100 data points to calculate average
   - Used as zero-point offset compensation

---

## Mobile BLE Receiver Development Guide

### Development Environment Recommendations

#### Android (Kotlin/Java)

**Required Permissions (AndroidManifest.xml)**
```xml
<!-- Bluetooth Permissions -->
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" android:usesPermissionFlags="neverForLocation" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />

<!-- Location Permissions (Required for Android 12 and below) -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />

<!-- WiFi and Network Permissions -->
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<uses-permission android:name="android.permission.ACCESS_WIFI_STATE" />
```

**Gradle Dependencies (build.gradle)**
```gradle
dependencies {
    // BLE Support (using Android BLE API)
    implementation 'com.polidea.rxandroidble2:rxandroidble:1.17.2'
    
    // Or use Google's BLE library
    implementation 'no.nordicsemi.android:ble:2.6.1'
    
    // HTTP Requests (for data upload)
    implementation 'com.squareup.okhttp3:okhttp:4.12.0'
    implementation 'com.google.code.gson:gson:2.10.1'
}
```

#### Flutter (Dart)

**pubspec.yaml Dependencies**
```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # BLE Bluetooth Library
  flutter_blue_plus: ^1.32.0
  
  # HTTP Requests
  http: ^1.1.0
  
  # JSON Processing
  json_annotation: ^4.8.1
  
  # Database (Local Cache)
  sqflite: ^2.3.0
  path: ^1.8.3
```

### BLE Connection Implementation Example (Flutter)

```dart
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:typed_data';

class BLEIMUReceiver {
  // BLE Service and Characteristic UUIDs
  static const String deviceName = "SmartRacket";
  static const String serviceUUID = "0769bb8e-b496-4fdd-b53b-87462ff423d0";
  static const String characteristicUUID = "8ee82f5b-76c7-4170-8f49-fff786257090";
  
  BluetoothDevice? connectedDevice;
  BluetoothCharacteristic? imuCharacteristic;
  bool isConnected = false;
  
  // Data reception callback
  Function(Map<String, dynamic>)? onDataReceived;
  
  // Scan and connect to device
  Future<bool> scanAndConnect() async {
    try {
      print("Starting BLE device scan...");
      
      // Start Bluetooth scan
      await FlutterBluePlus.startScan(timeout: Duration(seconds: 10));
      
      // Listen to scan results
      FlutterBluePlus.scanResults.listen((results) {
        for (ScanResult result in results) {
          if (result.device.platformName == deviceName || 
              result.device.advName == deviceName) {
            print("Found target device: ${result.device.platformName}");
            FlutterBluePlus.stopScan();
            connectToDevice(result.device);
            break;
          }
        }
      });
      
      return true;
    } catch (e) {
      print("Scan failed: $e");
      return false;
    }
  }
  
  // Connect to device
  Future<void> connectToDevice(BluetoothDevice device) async {
    try {
      print("Connecting to device...");
      await device.connect(timeout: Duration(seconds: 15));
      
      connectedDevice = device;
      
      // Monitor connection state
      device.connectionState.listen((state) {
        isConnected = (state == BluetoothConnectionState.connected);
        if (!isConnected) {
          print("Device disconnected");
        }
      });
      
      // Discover services
      List<BluetoothService> services = await device.discoverServices();
      
      for (BluetoothService service in services) {
        if (service.uuid.toString().toLowerCase() == 
            serviceUUID.toLowerCase().replaceAll('-', '')) {
          
          // Find target characteristic
          for (BluetoothCharacteristic characteristic in service.characteristics) {
            if (characteristic.uuid.toString().toLowerCase() == 
                characteristicUUID.toLowerCase().replaceAll('-', '')) {
              
              imuCharacteristic = characteristic;
              
              // Subscribe to notifications
              await characteristic.setNotifyValue(true);
              
              // Listen to data
              characteristic.lastValueStream.listen((data) {
                parseAndHandleData(data);
              });
              
              print("BLE connection successful, starting to receive data");
              break;
            }
          }
        }
      }
    } catch (e) {
      print("Connection failed: $e");
    }
  }
  
  // Parse data and trigger callback
  void parseAndHandleData(Uint8List data) {
    if (data.length != 30) {
      print("Data length error: ${data.length} bytes");
      return;
    }
    
    // Parse data (Little-Endian)
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
    
    // Trigger callback
    if (onDataReceived != null) {
      onDataReceived!(imuData);
    }
  }
  
  // Disconnect
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

### Data Buffering and Processing

Since the data transmission frequency is 50Hz, it is recommended to use a buffer to manage data:

```dart
class IMUDataBuffer {
  List<Map<String, dynamic>> buffer = [];
  static const int bufferSize = 200; // Cache 200 data points (approximately 4 seconds)
  
  void addData(Map<String, dynamic> data) {
    buffer.add(data);
    
    // Maintain buffer size
    if (buffer.length > bufferSize) {
      buffer.removeAt(0);
    }
  }
  
  // Get recent N data points (for AI analysis)
  List<Map<String, dynamic>> getRecentData(int count) {
    if (buffer.length < count) {
      return List.from(buffer);
    }
    return buffer.sublist(buffer.length - count);
  }
  
  // Clear buffer
  void clear() {
    buffer.clear();
  }
}
```

---

## Mobile App Results Display & UI Design

### Display Function Requirements

The mobile App needs to simultaneously complete the following functions during demonstrations:

1. **Real-time Data Collection**: Continuously receive IMU sensor data transmitted via BLE
2. **Real-time AI Inference**: Use local TensorFlow Lite model for real-time stroke recognition
3. **Results Display**: Present recognition results to users in a visual way
4. **Test Records**: Save detailed data and recognition results for each stroke

### UI Design Recommendations

#### 1. Main Interface Architecture

It is recommended to use Tab navigation or bottom navigation bar design, mainly including the following pages:

```
┌─────────────────────────────────┐
│  Smart Badminton Analysis       │
│         System                  │
├─────────────────────────────────┤
│                                 │
│  ┌─────┐  ┌─────┐  ┌─────┐    │
│  │Home │  │Analy│  │Hist │    │
│  └─────┘  └─────┘  └─────┘    │
│                                 │
└─────────────────────────────────┘
```

#### 2. Real-time Test Page (Home Page)

This is the main page for demonstrations, recommended design as follows:

**Upper Section: Connection Status & Real-time Data Display**
```
┌─────────────────────────────────┐
│  📶 SmartRacket  ✓ Connected   │
│  Battery: ████████░░ 80%       │
├─────────────────────────────────┤
│  Real-time Sensor Data          │
│  ┌─────────────────────────┐  │
│  │ Acceleration: X Y Z     │  │
│  │ Angular Vel: X Y Z       │  │
│  └─────────────────────────┘  │
└─────────────────────────────────┘
```

**Middle Section: AI Recognition Results Display Area (Key Focus)**
```
┌─────────────────────────────────┐
│      🎾 Stroke Recognition      │
│                                 │
│    ┌─────────────────────┐    │
│    │                     │    │
│    │    [SMASH]          │    │
│    │                     │    │
│    │  Confidence: 85%    │    │
│    │                     │    │
│    └─────────────────────┘    │
│                                 │
│  [Ready] [Start Test] [Stop]   │
└─────────────────────────────────┘
```

**Lower Section: Real-time Waveform Chart**
```
┌─────────────────────────────────┐
│  Real-time Data Waveform        │
│  ┌─────────────────────────┐  │
│  │  ▁▂▃▅▇█▇▅▃▂▁          │  │
│  │  (Dynamic waveform)      │  │
│  └─────────────────────────┘  │
└─────────────────────────────────┘
```

**UI Element Recommendations:**
- Result cards use large size display, with colors distinguishing different stroke types:
  - Smash: Red tones (#FF4444)
  - Drive: Blue tones (#4488FF)
  - Other: Gray tones (#888888)
- Confidence displayed as progress bar or circular progress indicator
- Add animation effects when displaying results (such as pop-up, fade-in, etc.)
- Results freeze display for 3-5 seconds to allow users to clearly see recognition results

#### 3. Test Results Detail Page

Display detailed information for each stroke:

```dart
class StrokeResultPage extends StatelessWidget {
  final StrokeResult result;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Stroke Result Details')),
      body: Column(
        children: [
          // Result summary card
          _buildResultCard(result),
          
          // Timeline information
          _buildTimeline(result),
          
          // Detailed data charts
          _buildDataCharts(result),
          
          // Action replay (optional)
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
              'Confidence: ${(result.confidence * 100).toInt()}%',
              style: TextStyle(fontSize: 24, color: Colors.white70),
            ),
            SizedBox(height: 8),
            Text(
              'Time: ${_formatTime(result.timestamp)}',
              style: TextStyle(fontSize: 14, color: Colors.white60),
            ),
          ],
        ),
      ),
    );
  }
}
```

#### 4. History Records Page

Display list of all test records:

```
┌─────────────────────────────────┐
│  Test Records                   │
├─────────────────────────────────┤
│  🎾 Smash  85%  [Today 14:23]  │
│  🎾 Drive  72%  [Today 14:20]  │
│  🎾 Other  45%  [Today 14:15]  │
│  🎾 Smash  90%  [Today 14:10]  │
│  🎾 Drive  68%  [Today 14:05]  │
└─────────────────────────────────┘
```

#### 5. Chart Visualization Recommendations

**Real-time Waveform Chart (fl_chart)**
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

**Three-axis Acceleration/Angular Velocity Display**
- Use 3D indicator sphere or 2D plane projection to display racket pose
- Real-time update, providing visual feedback

#### 6. Animation Effect Recommendations

**Recognition Result Pop-up Animation:**
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

### Display Mode Design

For better demonstration effects, it is recommended to design the following modes:

#### 1. Test Mode
- Clear start/stop buttons
- Display real-time data during testing
- Immediately display results after each stroke
- Results persist for 3-5 seconds then automatically clear, ready for next test

#### 2. Demo Mode
- Auto-record mode, no manual operation required
- Continuously test multiple stroke actions
- Automatically save all results
- Can replay the test process

### State Management Recommendations

Use Flutter's state management solution (such as Provider, Riverpod) to manage the following states:

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

### Performance Optimization Recommendations

1. **Chart Update Frequency**: Waveform chart recommended to update 10-20 times per second, no need for 50Hz
2. **Result Caching**: Cache recognition results for display, avoid frequent recalculation
3. **Background Processing**: AI inference runs on background thread to avoid blocking UI

---

## Pose Calibration Function

### Function Necessity Description

Pose calibration is an important function to ensure accurate AI model recognition because:

1. **Sensor Installation Differences**: Different rackets or different installation angles will cause sensor coordinate system to be inconsistent with actual stroke action coordinate system
2. **Individual Stroke Habits**: Different users' stroke postures and grip styles may differ
3. **Improve Recognition Accuracy**: Calibrated data can significantly improve AI model recognition accuracy

### Calibration Flow Design

#### 1. Calibration Mode Trigger

It is recommended to provide "Calibrate Pose" option in the main interface settings:

```dart
class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            leading: Icon(Icons.tune),
            title: Text('Calibrate Pose'),
            subtitle: Text('Calibrate sensor pose to improve recognition accuracy'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => CalibrationPage()),
            ),
          ),
          // Other settings options...
        ],
      ),
    );
  }
}
```

#### 2. Calibration Step Design

**Step 1: Preparation Phase**
```
┌─────────────────────────────────┐
│  Pose Calibration               │
├─────────────────────────────────┤
│                                 │
│  Please place racket on flat   │
│  surface                        │
│  Keep racket still              │
│                                 │
│  Click "Start Calibration"      │
│  when ready                     │
│                                 │
│      [Cancel]  [Start]           │
└─────────────────────────────────┘
```

**Step 2: Static State Sampling**
```dart
class CalibrationPage extends StatefulWidget {
  @override
  _CalibrationPageState createState() => _CalibrationPageState();
}

class _CalibrationPageState extends State<CalibrationPage> {
  List<IMUData> calibrationSamples = [];
  bool isCalibrating = false;
  int sampleCount = 0;
  static const int requiredSamples = 200; // Collect 200 data points (approximately 4 seconds)
  
  void startCalibration() {
    setState(() {
      isCalibrating = true;
      sampleCount = 0;
      calibrationSamples.clear();
    });
    
    // Start collecting data
    BLEIMUReceiver().onDataReceived = (data) {
      if (isCalibrating && sampleCount < requiredSamples) {
        setState(() {
          calibrationSamples.add(data);
          sampleCount++;
        });
        
        // Update progress
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
    // Calculate calibration parameters
    CalibrationData calData = _calculateCalibration(calibrationSamples);
    
    // Save calibration parameters
    _saveCalibrationData(calData);
    
    setState(() {
      isCalibrating = false;
    });
    
    // Show completion message
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Calibration Complete'),
        content: Text('Pose calibration completed, will be applied to subsequent stroke recognition'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
  
  CalibrationData _calculateCalibration(List<IMUData> samples) {
    // Calculate average as offset
    double accelXOffset = samples.map((s) => s.accelX).reduce((a, b) => a + b) / samples.length;
    double accelYOffset = samples.map((s) => s.accelY).reduce((a, b) => a + b) / samples.length;
    double accelZOffset = samples.map((s) => s.accelZ).reduce((a, b) => a + b) / samples.length;
    
    double gyroXOffset = samples.map((s) => s.gyroX).reduce((a, b) => a + b) / samples.length;
    double gyroYOffset = samples.map((s) => s.gyroY).reduce((a, b) => a + b) / samples.length;
    double gyroZOffset = samples.map((s) => s.gyroZ).reduce((a, b) => a + b) / samples.length;
    
    // Calculate gravity direction (for coordinate system transformation)
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

**Calibration Progress Display:**
```
┌─────────────────────────────────┐
│  Calibrating...                 │
│                                 │
│  ████████░░░░░░░░░░ 40%         │
│                                 │
│  Please keep racket still       │
│  Remaining time: 2.4 seconds    │
│                                 │
└─────────────────────────────────┘
```

#### 3. Calibration Data Application

Calibrated data needs to be applied during data processing:

```dart
class CalibratedIMUProcessor {
  CalibrationData? calibrationData;
  
  IMUData applyCalibration(IMUData rawData) {
    if (calibrationData == null) {
      return rawData; // Return original data if not calibrated
    }
    
    return IMUData(
      timestamp: rawData.timestamp,
      // Subtract offset
      accelX: rawData.accelX - calibrationData!.accelOffset.x,
      accelY: rawData.accelY - calibrationData!.accelOffset.y,
      accelZ: rawData.accelZ - calibrationData!.accelOffset.z,
      
      gyroX: rawData.gyroX - calibrationData!.gyroOffset.x,
      gyroY: rawData.gyroY - calibrationData!.gyroOffset.y,
      gyroZ: rawData.gyroZ - calibrationData!.gyroOffset.z,
      
      voltage: rawData.voltage,
    );
  }
  
  // Coordinate system transformation (optional, implement according to requirements)
  IMUData transformCoordinate(IMUData calibratedData) {
    // Rotate coordinate system based on gravity direction
    // Implementation details depend on requirements
    return calibratedData;
  }
}
```

#### 4. Calibration Data Storage

Use local storage to save calibration parameters:

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

### Calibration Timing Recommendations

1. **First Use**: Prompt user to calibrate when App first launches
2. **Device Replacement**: After changing racket or reinstalling sensor
3. **Regular Calibration**: Recommend calibration before each use (can choose whether to auto-prompt in settings)
4. **Manual Trigger**: Users can recalibrate anytime in settings

### Calibration Validation

After calibration is complete, simple validation can be performed:

```dart
bool validateCalibration(CalibrationData calData) {
  // Validate if gravity direction is reasonable
  double gravityMag = sqrt(
    pow(calData.gravityDirection.x, 2) +
    pow(calData.gravityDirection.y, 2) +
    pow(calData.gravityDirection.z, 2)
  );
  
  // Gravity magnitude should be close to 1g
  if (gravityMag < 0.8 || gravityMag > 1.2) {
    return false; // Calibration data abnormal
  }
  
  // Validate if gyroscope offset is within reasonable range
  if (calData.gyroOffset.magnitude > 50) { // 50 dps
    return false; // Gyroscope offset too large
  }
  
  return true;
}
```

### Advanced Calibration Functions (Optional)

For higher precision, multi-directional calibration can be implemented:

1. **Multi-angle Calibration**: Allow users to place racket at different angles for calibration
2. **Dynamic Calibration**: Perform specific actions (such as standard stroke) for calibration
3. **Personalized Calibration**: Personalized adjustment based on user's stroke habits

---

## WiFi Data Transmission to Server

### Data Upload Strategy

#### 1. Real-time Upload (Recommended for Training Data Collection)

Upload each data point to server immediately upon receipt:

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';

class DataUploader {
  static const String serverUrl = "https://your-server.com/api/imu-data";
  
  // Single data upload
  Future<bool> uploadSingleData(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse(serverUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'device_id': 'SmartRacket_001', // Device identifier
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
      print("Upload failed: $e");
      return false;
    }
  }
  
  // Batch upload (for offline cached data)
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
      print("Batch upload failed: $e");
      return false;
    }
  }
}
```

#### 2. Batch Upload (Save Network Resources)

Cache data locally, upload in batches periodically:

```dart
class BatchUploadManager {
  List<Map<String, dynamic>> pendingData = [];
  Timer? uploadTimer;
  
  void startBatchUpload() {
    // Upload every 10 seconds
    uploadTimer = Timer.periodic(Duration(seconds: 10), (timer) {
      if (pendingData.isNotEmpty) {
        _uploadBatch();
      }
    });
  }
  
  void addData(Map<String, dynamic> data) {
    pendingData.add(data);
    
    // Upload immediately if cache exceeds 500 entries
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
      // Upload failed, re-add to pending list
      pendingData.insertAll(0, dataToUpload);
    }
  }
}
```

### Offline Data Cache

Use local database to store unuploaded data:

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

## Database Design

### Recommended Database Structure (MySQL/PostgreSQL)

#### Main Data Table: `imu_raw_data`

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

#### Training Data Table: `training_data`

```sql
CREATE TABLE training_data (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    session_id VARCHAR(100) NOT NULL,
    device_id VARCHAR(50) NOT NULL,
    label VARCHAR(20) NOT NULL,  -- 'smash', 'drive', 'other'
    start_timestamp BIGINT NOT NULL,
    end_timestamp BIGINT NOT NULL,
    data_frame JSON,  -- Store array of 40 data points
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_session (session_id),
    INDEX idx_label (label)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

#### Stroke Recognition Results Table: `stroke_recognition`

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

### RESTful API Design Recommendations

#### 1. Upload Single IMU Data
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

#### 2. Batch Upload IMU Data
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

#### 3. Upload Labeled Training Data
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
    ... (40 data points)
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

## AI Training Data Preparation

### Data Format Requirements

#### 1. Time Window Segmentation

AI models require fixed-length input, it is recommended to use **40 data points** as one analysis window (corresponding to approximately 0.8 seconds of data):

```python
def create_data_frames(raw_data, window_size=40):
    """
    Segment raw data into fixed-length frames
    
    Args:
        raw_data: List[dict] - Raw IMU data list
        window_size: int - Number of data points per frame (default 40)
    
    Returns:
        List[List[dict]] - List of segmented data frames
    """
    frames = []
    for i in range(len(raw_data) - window_size + 1):
        frame = raw_data[i:i + window_size]
        frames.append(frame)
    return frames
```

#### 2. Feature Extraction

Each frame needs to be converted to model input format `[1, 40, 6, 1]`:

- **Batch Size**: 1
- **Time Points**: 40 (40 data points)
- **Feature Count**: 6 (accelX, accelY, accelZ, gyroX, gyroY, gyroZ)
- **Channels**: 1

```python
import numpy as np

def frame_to_model_input(frame):
    """
    Convert data frame to model input format
    
    Args:
        frame: List[dict] - 40 IMU data points
    
    Returns:
        numpy.ndarray - Array with shape (1, 40, 6, 1)
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
    
    # Convert to numpy array
    array = np.array(features, dtype=np.float32)
    
    # Reshape to (1, 40, 6, 1)
    array = array.reshape(1, 40, 6, 1)
    
    return array
```

### Data Labeling Process

#### 1. Automatic Peak Detection

Identify stroke actions based on sensor data peaks:

```python
def detect_peak_frames(data, threshold_std=2.0):
    """
    Detect peaks through standard deviation (stroke actions)
    
    Args:
        data: List[dict] - IMU data list
        threshold_std: float - Standard deviation threshold
    
    Returns:
        List[int] - List of peak indices
    """
    # Extract gY axis data as main judgment basis
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
    Create labeled data frames based on peaks
    
    Args:
        raw_data: List[dict] - Raw data
        peak_indices: List[int] - Peak indices
        label: str - Label ('smash', 'drive', 'other')
    
    Returns:
        List[dict] - List of labeled frames
    """
    frames = []
    for peak_idx in peak_indices:
        # 19 points before peak + peak + 20 points after = 40 points
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

#### 2. Manual Labeling Tool

It is recommended to develop a labeling tool that allows users to:
- Visually display IMU data waveforms
- Manually mark start and end times of stroke actions
- Select stroke category (smash, drive, other)

### Data Preprocessing

#### 1. Data Normalization

```python
def normalize_frame(frame, mean=None, std=None):
    """
    Normalize data frame (Z-score normalization)
    
    Args:
        frame: numpy.ndarray - Raw data frame
        mean: numpy.ndarray - Pre-calculated mean (for test data)
        std: numpy.ndarray - Pre-calculated standard deviation (for test data)
    
    Returns:
        tuple: (normalized frame, mean, std)
    """
    if mean is None or std is None:
        mean = np.mean(frame, axis=0, keepdims=True)
        std = np.std(frame, axis=0, keepdims=True)
    
    # Avoid division by zero
    std = np.where(std == 0, 1, std)
    
    normalized = (frame - mean) / std
    
    return normalized, mean, std
```

#### 2. Data Augmentation

```python
def augment_data(frames, noise_factor=0.01):
    """
    Add noise for data augmentation
    
    Args:
        frames: List[numpy.ndarray] - Raw frame list
        noise_factor: float - Noise intensity
    
    Returns:
        List[numpy.ndarray] - Augmented frame list
    """
    augmented = []
    for frame in frames:
        noise = np.random.normal(0, noise_factor, frame.shape)
        augmented_frame = frame + noise
        augmented.append(augmented_frame)
    
    return augmented
```

### Dataset Organization

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

## System Architecture Flowchart

### Complete Data Flow

```
┌─────────────────┐
│ Badminton Racket│
│   Sensor        │
│  (Arduino IMU)  │
└────────┬────────┘
         │ BLE (50Hz)
         │ 30 bytes/packet
         ▼
┌─────────────────┐
│   Mobile App    │
│   Receiver      │
│  (BLE Client)   │
│  - Parse Data   │
│  - Buffer Mgmt  │
└────────┬────────┘
         │
         ├─────────────────┐
         │                 │
         ▼                 ▼
┌─────────────────┐  ┌─────────────────┐
│  Local Database │  │   WiFi Upload  │
│ (SQLite Cache)  │  │   (HTTP/HTTPS) │
└─────────────────┘  └────────┬────────┘
                              │
                              ▼
                      ┌─────────────────┐
                      │  Server Database│
                      │ (MySQL/PostgreSQL)
                      └────────┬────────┘
                               │
                               ▼
                      ┌─────────────────┐
                      │  AI Training    │
                      │    Module       │
                      │  - Preprocessing│
                      │  - Model Train  │
                      │  - Model Deploy │
                      └─────────────────┘
```

### Mobile App Module Architecture

```
┌─────────────────────────────────────┐
│      Mobile App Architecture         │
├─────────────────────────────────────┤
│                                     │
│  ┌──────────────┐                  │
│  │  BLE Manager │                  │
│  │  - Scan Dev  │                  │
│  │  - Connect   │                  │
│  │  - Recv Data │                  │
│  └──────┬───────┘                  │
│         │                           │
│  ┌──────▼───────┐                  │
│  │ Data Parser  │                  │
│  │  - Parse30B  │                  │
│  │  - Validate  │                  │
│  └──────┬───────┘                  │
│         │                           │
│  ┌──────▼───────┐                  │
│  │ Data Buffer  │                  │
│  │  - Sliding   │                  │
│  │  - 40 frames │                  │
│  └──────┬───────┘                  │
│         │                           │
│  ├──────┴───────┬──────────────────┤
│  │              │                  │
│  ▼              ▼                  │
│  ┌──────────┐  ┌──────────────┐   │
│  │ AI Infer │  │  Data Upload │   │
│  │ (TFLite) │  │  - WiFi Up  │   │
│  │          │  │  - Local Cache│  │
│  └──────────┘  └──────────────┘   │
│                                     │
└─────────────────────────────────────┘
```

---

## Development Notes

### BLE Connection Notes

1. **Connection Timeout Handling**:
   - Set reasonable connection timeout (recommended 15 seconds)
   - Provide retry mechanism when connection fails

2. **Disconnection Reconnection Mechanism**:
   - Monitor connection state changes
   - Automatically rescan and reconnect
   - Display connection status to users

3. **Data Reception Stability**:
   - Check received data length (must be 30 bytes)
   - Handle data parsing errors
   - Record error logs for debugging

### Network Transmission Notes

1. **WiFi Status Check**:
   - Check WiFi connection status before upload
   - Cache data locally when WiFi is not connected

2. **Data Upload Failure Handling**:
   - Implement retry mechanism (maximum 3 times)
   - Store failed data in local database
   - Periodically check and re-upload unsuccessful data

3. **Battery Consumption Optimization**:
   - Batch upload to reduce network requests
   - Use background tasks for upload processing
   - Avoid excessive network requests

### Data Processing Notes

1. **Timestamp Synchronization**:
   - Difference between mobile reception time and sensor time
   - Recommend recording mobile local timestamp
   - Server side uniformly uses UTC time

2. **Data Quality Control**:
   - Check sensor data valid ranges
   - Filter outliers (such as all zeros or extreme values)
   - Validate timestamp continuity

3. **Memory Management**:
   - Avoid accumulating too much data in memory
   - Regularly clean processed data
   - Use appropriate data structure sizes

---

## Troubleshooting

### BLE Connection Issues

#### Issue 1: Unable to Scan Device

**Possible Causes**:
- Sensor not started or BLE not advertising
- Mobile Bluetooth not enabled
- Device too far away

**Solutions**:
1. Check if Arduino program is correctly uploaded
2. Confirm sensor LED indicator status
3. Check mobile Bluetooth permissions
4. Move closer to sensor (recommended within 1 meter)

#### Issue 2: Immediate Disconnection After Connection

**Possible Causes**:
- BLE service UUID mismatch
- Characteristic UUID mismatch
- Mobile BLE driver issues

**Solutions**:
1. Check if UUIDs are completely consistent (including case)
2. Confirm if BLE services and characteristics are correctly discovered
3. Try restarting mobile Bluetooth
4. Check BLE settings in Arduino program

#### Issue 3: Unstable Data Reception

**Possible Causes**:
- Transmission frequency too high
- BLE signal interference
- Insufficient mobile processing performance

**Solutions**:
1. Reduce data transmission frequency (modify Arduino program)
2. Stay away from interference sources like WiFi routers
3. Check if mobile has other BLE connections occupying bandwidth
4. Optimize data reception processing logic

### Data Parsing Issues

#### Issue 1: Data Length Error

**Symptom**: Received data that is not 30 bytes

**Solution**:
```dart
if (data.length != 30) {
  print("Warning: Received data with abnormal length ${data.length} bytes");
  return; // Skip this data point
}
```

#### Issue 2: Abnormal Data Values

**Symptom**: Acceleration or angular velocity values exceed reasonable range

**Solution**:
```dart
bool validateData(Map<String, dynamic> data) {
  // Acceleration range: -16g ~ +16g
  if (data['accelX'].abs() > 16 || 
      data['accelY'].abs() > 16 || 
      data['accelZ'].abs() > 16) {
    return false;
  }
  
  // Angular velocity range: -2000 ~ +2000 dps
  if (data['gyroX'].abs() > 2000 || 
      data['gyroY'].abs() > 2000 || 
      data['gyroZ'].abs() > 2000) {
    return false;
  }
  
  return true;
}
```

### Network Transmission Issues

#### Issue 1: Upload failure

**Possible Causes**:
- Unstable network connection
- Server API error
- Data format error

**Solution**:
1. Implement a retry mechanism
2. Check HTTP status codes and error messages
3. Verify that the JSON format is correct
4. Check server logs

#### Issue 2: Data loss

**Possible Causes**:
- Upload failed but not saved
- Local database write failed
- Application closed unexpectedly

**Solution**:
1. All data must first be saved to the local database
2. Only mark as uploaded after successful upload
3. Periodically check and re-upload unsuccessful data
4. Use transactions to ensure data consistency

---

## Reference Resources

### Official Documentation

- [Seeed XIAO nRF52840 Sense Documentation](https://wiki.seeedstudio.com/XIAO_BLE/)
- [ArduinoBLE Library Documentation](https://www.arduino.cc/reference/en/libraries/arduinoble/)
- [Flutter Blue Plus Documentation](https://pub.dev/packages/flutter_blue_plus)
- [BLE Specification Documentation](https://www.bluetooth.com/specifications/specs/core-specification/)

### Example Code Locations

- **Arduino Main Program**: `src/main/main.ino`
- **Windows Receiver Program**: `APP/windows/visualizer/ble_imu_receiver.py`
- **Past Project Examples**: `examples/Past_Student_Projects/codes/`

### Recommended Development Tools

- **BLE Scan Tools**: 
  - Android: nRF Connect
  - iOS: LightBlue
- **Data Visualization**: 
  - Python: Matplotlib, Plotly
  - Flutter: fl_chart
- **API Testing**: Postman, curl

---

## Contact Information

For technical issues, please contact the project team or refer to the project README file.

---

**Document Version**: v1.1  
**Last Updated**: November 2025  
**Maintainer**: DIID Term Project Team  
**Update Content**: 
- Added Mobile App Result Display and UI Design chapter
- Added Attitude Calibration Function chapter
- Updated System Overview to include demonstration feature requirements  