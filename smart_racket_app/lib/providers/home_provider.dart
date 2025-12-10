import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/ble_service.dart';
import '../services/websocket_service.dart';
import '../services/data_buffer_manager.dart';
import '../models/imu_frame.dart';

// ChangeNotifier 是 Flutter 提供的一個狀態管理類別
// 當我們呼叫 notifyListeners() 時，所有監聽這個 Provider 的 UI (Widget) 都會自動刷新
class HomeProvider extends ChangeNotifier {
  // 建立我們需要的服務物件
  final BLEService _bleService = BLEService();             // 負責處理藍牙
  final WebSocketService _wsService = WebSocketService();  // 負責傳資料給伺服器
  final DataBufferManager _bufferManager = DataBufferManager(); // 負責緩衝資料偵測揮拍

  // --- 狀態變數 (State) ---
  // 這些變數改變時，UI 會跟著變
  bool isScanning = false;      // 是否正在掃描藍牙
  bool isConnected = false;     // 是否已連上 MCU
  String connectionStatus = "Disconnected"; // 顯示在 UI 上的連線狀態文字
  String serverStatus = "Disconnected";     // 顯示在 UI 上的伺服器連線狀態
  double batteryVoltage = 0.0;  // 目前球拍的電壓
  
  // 用來監聽裝置連線狀態 (例如意外斷線)
  StreamSubscription<BluetoothConnectionState>? _deviceStateSubscription;

  // 即時圖表資料：為了畫圖，我們會保留最近 50 筆資料
  List<IMUFrame> recentFrames = [];
  
  // 辨識結果：伺服器回傳的分析結果
  String lastResultType = "--";   // 動作類型 (例如殺球)
  String lastResultSpeed = "--";  // 球速
  String lastResultMessage = "Ready"; // 顯示訊息
  
  // --- 設定參數 ---
  double sensitivity = 2.0; // 觸發揮拍的門檻值 (G力)
  // String serverIp = "192.168.1.100"; // 本地測試用 IP
  String serverIp = "diid-termproject-v2.onrender.com"; // 雲端伺服器網址

  // --- 校正相關變數 ---
  bool isCalibrating = false; // 是否正在進行校正
  List<IMUFrame> _calibrationFrames = []; // 暫存校正用的資料
  
  // 校正偏移量 (Offset)：要把感測器的數值扣掉這些才會變回 0
  List<double> accOffset = [0.0, 0.0, 0.0];
  List<double> gyroOffset = [0.0, 0.0, 0.0];
  bool isCalibrated = false; // 是否已經完成校正
  
  // 建構子 (Constructor)：當 App 啟動建立這個 Provider 時會執行
  HomeProvider() {
    _init(); // 執行初始化
  }
  
  // 初始化函式
  void _init() async {
    await _bleService.init(); // 初始化藍牙服務
    
    // 監聽藍牙傳來的感測器資料 (Stream)
    _bleService.imuStream.listen((frame) {
      _handleNewFrame(frame); // 每收到一筆資料，就交給 _handleNewFrame 處理
    });
    
    // 初始化完成後，嘗試連線到伺服器 (因為 Render 免費版會休眠，先連線叫醒它)
    _connectToServer();
  }
  
  // --- 使用者操作動作 (Actions) ---
  
  // 開始傳感器歸零校正
  void startCalibration() {
    isCalibrating = true;      // 標記狀態為「校正中」
    _calibrationFrames.clear(); // 清空舊的暫存資料
    notifyListeners();         // 通知 UI 更新 (顯示轉圈圈)
    print("Calibration Started...");
  }
  
  // 開始掃描藍牙裝置
  Future<void> startScan() async {
    // 1. 請求權限 (Android 需要定位與藍牙權限)
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    // 如果使用者拒絕權限，就無法繼續
    if (statuses.values.any((s) => s.isDenied || s.isPermanentlyDenied)) {
      connectionStatus = "Permission Denied";
      notifyListeners();
      return;
    }

    isScanning = true;
    connectionStatus = "Scanning...";
    notifyListeners(); // 更新 UI 顯示「掃描中」
    
    // 2. 呼叫 BLE Service 開始掃描
    await _bleService.startScan();
    
    // 3. 自動連線邏輯
    // 監聽掃描結果，如果發現名字是 "SmartRacket" 的裝置就自動連線
    FlutterBluePlus.scanResults.listen((results) async {
        for (ScanResult r in results) {
            // 找到目標裝置 且 目前還沒連線
            if (r.device.platformName == "SmartRacket" && !isConnected) {
                print("Found SmartRacket! Connecting...");
                await _bleService.stopScan();    // 找到就停止掃描
                await connectToDevice(r.device); // 開始連線
                break; 
            }
        }
    });
    
    // 安全機制：如果 10 秒後還沒連上，就自動停止掃描，避免一直耗電
    Future.delayed(const Duration(seconds: 10), () {
        if (isScanning && !isConnected) {
            isScanning = false;
            connectionStatus = "Device Not Found";
            _bleService.stopScan();
            notifyListeners();
        }
    });
  }
  
  // 連線到特定裝置
  Future<void> connectToDevice(BluetoothDevice device) async {
    isScanning = false;
    connectionStatus = "Connecting...";
    notifyListeners();
    
    try {
      await _bleService.connect(device); // 呼叫底層連線
      isConnected = true;
      connectionStatus = "Connected";
      notifyListeners();
      
      await _connectToServer(); // 藍牙連上後，確保伺服器也連上

      // 監聽意外斷線
      // 如果使用途中使用者把球拍關機，我們要偵測到並回到可掃描狀態
      _deviceStateSubscription?.cancel(); // 先取消舊的監聽
      _deviceStateSubscription = device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected && isConnected) {
           print("HomeProvider: Device Disconnected Unexpectedly");
           // 執行斷線清理，並顯示狀態
           _performDisconnectCleanup(status: "Device Disconnected");
        }
      });

    } catch (e) {
      connectionStatus = "Connection Failed"; // 連線失敗
      isConnected = false;
      notifyListeners();
    }
  }
  
  // 主動斷開連線
  Future<void> disconnect() async {
    await _performDisconnectCleanup(status: "Disconnected");
  }

  //這是一個共用的清理函式，負責把所有連線切斷並重置狀態
  Future<void> _performDisconnectCleanup({String status = "Disconnected"}) async {
    _deviceStateSubscription?.cancel(); // 停止監聽斷線事件
    await _bleService.disconnect();     // 斷開藍牙
    _wsService.disconnect();            // 斷開伺服器
    isConnected = false;                // 標記為未連線
    connectionStatus = status;          // 更新狀態文字
    notifyListeners();                  // 通知 UI
  }
  
  // 更新設定 (從設定頁面呼叫)
  void updateSettings(double newThreshold, String newIp) {
    sensitivity = newThreshold;
    serverIp = newIp;
    
    _bufferManager.setThreshold(sensitivity); // 更新揮拍偵測靈敏度
    _connectToServer(); // 如果 IP 改了，重新連線
    notifyListeners();
  }

  // --- 內部邏輯函式 (Private) ---
  
  // 連線到 Python 伺服器 (WebSocket)
  Future<void> _connectToServer() async {
    // 組合 WebSocket 網址 (ws:// 或 wss://)
    String url;
    if (serverIp.contains("render.com")) {
      url = "wss://$serverIp/ws/predict"; // 雲端通常這用加密的 wss
    } else {
      url = "ws://$serverIp:8000/ws/predict"; // 本地測試通常用 ws
    }
    
    serverStatus = "Connecting...";
    notifyListeners();
    
    try {
      await _wsService.connect(url);
      serverStatus = "Connected";
      notifyListeners();
      
      // 監聽伺服器回傳的訊息
      _wsService.stream?.listen((message) {
         _handleServerResponse(message); // 收到訊息就處理
      }, onDone: () {
          serverStatus = "Disconnected"; // 伺服器斷線了
          notifyListeners();
      }, onError: (err) {
          serverStatus = "Error"; // 連線錯誤
          notifyListeners();
      });
      
    } catch (e) {
      print("Server Connect Error: $e");
      serverStatus = "Failed";
      notifyListeners();
    }
  }

  // 處理每一筆新的感測器資料 (高頻率呼叫，約 50Hz)
  void _handleNewFrame(IMUFrame frame) {
    IMUFrame processedFrame = frame;

    // 0. 校正邏輯：如果正在校正中，就把資料存起來不算
    if (isCalibrating) {
      _calibrationFrames.add(frame);
      // 收集滿 50 筆 (約 1 秒) 就結束校正
      if (_calibrationFrames.length >= 50) {
        _finishCalibration();
      }
      return; // 校正中不畫圖也不偵測揮拍，直接返回
    }
    
    // 1. 應用校正：如果有校正過，就把數值扣掉偏移量
    if (isCalibrated) {
      processedFrame = IMUFrame(
        timestamp: frame.timestamp,
        acc: [
          frame.acc[0] - accOffset[0],
          frame.acc[1] - accOffset[1],
          frame.acc[2] - accOffset[2],
        ],
        gyro: [
          frame.gyro[0] - gyroOffset[0],
          frame.gyro[1] - gyroOffset[1],
          frame.gyro[2] - gyroOffset[2],
        ],
        voltage: frame.voltage,
      );
    }

    // 2. 更新即時圖表 (只保留最近 50 點，不然記憶體會爆炸)
    recentFrames.add(processedFrame);
    if (recentFrames.length > 50) {
      recentFrames.removeAt(0); // 移除最舊的一筆
    }
    batteryVoltage = processedFrame.voltage;
    
    // 3. 丟給 Buffer Manager 判斷是不是在揮拍
    List<IMUFrame>? window = _bufferManager.addFrame(processedFrame);
    
    // 4. 如果 Buffer Manager 回傳不為 null，代表偵測到揮拍了！
    if (window != null) {
      // 觸發！將整段動作資料送給伺服器
      print("Provider: Triggered! Sending ${window.length} frames...");
      _wsService.sendWindow("device_001", window);
      lastResultMessage = "Analyzing..."; // 更新 UI 顯示「分析中」
    }
    
    // 通知 UI 更新畫面 (例如圖表重繪)
    notifyListeners();
  }
  
  // 完成校正，計算平均值
  void _finishCalibration() {
    double sumAx = 0, sumAy = 0, sumAz = 0;
    double sumGx = 0, sumGy = 0, sumGz = 0;
    int count = _calibrationFrames.length;

    // 加總所有數值
    for (var f in _calibrationFrames) {
      sumAx += f.acc[0];
      sumAy += f.acc[1];
      sumAz += f.acc[2];
      
      sumGx += f.gyro[0];
      sumGy += f.gyro[1];
      sumGz += f.gyro[2];
    }

    // 算平均
    double avgAx = sumAx / count;
    double avgAy = sumAy / count;
    double avgAz = sumAz / count;
    
    double avgGx = sumGx / count;
    double avgGy = sumGy / count;
    double avgGz = sumGz / count;

    // 設定偏移量 (Offset)
    // 目標：平放時 Z 軸應為 1.0G (重力)，XY 軸為 0
    // 公式：校正後 = 原始 - Offset => Offset = 原始 - 目標
    
    accOffset = [avgAx, avgAy, avgAz - 1.0]; // Z 軸扣掉 avgAz 但加回 1.0 (等同 原始 - (avg - 1))
    gyroOffset = [avgGx, avgGy, avgGz];      // 陀螺儀靜止時應該全是 0
    
    // 更新狀態
    isCalibrating = false;
    isCalibrated = true;
    _calibrationFrames.clear();

    print("Calibration Done!");
    print("Acc Offset: $accOffset");
    
    notifyListeners();
  }
  
  // 處理伺服器回傳的辨識結果
  void _handleServerResponse(dynamic message) {
    // 解析 JSON
    // 格式範例: {"type": "Smash", "speed": 185.5, "display": true, "message": "..."}
    try {
        final Map<String, dynamic> data = jsonDecode(message);
        bool display = data['display'] ?? false; // 伺服器叫我們顯示才顯示
        
        if (display) {
            lastResultType = data['type'] ?? "Unknown";
            var spd = data['speed'];
            lastResultSpeed = (spd != null) ? "$spd km/h" : ""; // 有球速才顯示
            lastResultMessage = data['message'] ?? "";
            notifyListeners(); // 通知 UI 更新結果
        }
    } catch (e) {
        print("JSON Error: $e");
    }
  }
}
