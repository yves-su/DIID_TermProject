import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/ble_service.dart';
import '../services/websocket_service.dart';
import '../services/data_buffer_manager.dart';
import '../models/imu_frame.dart';

class HomeProvider extends ChangeNotifier {
  final BLEService _bleService = BLEService();
  final WebSocketService _wsService = WebSocketService();
  final DataBufferManager _bufferManager = DataBufferManager();

  // State Variables
  bool isScanning = false;
  bool isConnected = false;
  String connectionStatus = "Disconnected";
  double batteryVoltage = 0.0;
  
  // Real-time Graph Data
  List<IMUFrame> recentFrames = [];
  
  // Recognition Result
  String lastResultType = "--";
  String lastResultSpeed = "--";
  String lastResultMessage = "Ready";
  
  // Configuration (Dynamic)
  double sensitivity = 2.0; // Default threshold
  String serverIp = "192.168.1.100"; // Default, to be set by UI
  
  HomeProvider() {
    _init();
  }
  
  void _init() async {
    await _bleService.init();
    
    // Listen to IMU stream
    _bleService.imuStream.listen((frame) {
      _handleNewFrame(frame);
    });
    
    // Listen to WebSocket stream (Server responses)
    // Note: We need to connect first.
  }
  
  // --- Actions ---
  
  Future<void> startScan() async {
    // 1. Request Permissions
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    if (statuses.values.any((s) => s.isDenied || s.isPermanentlyDenied)) {
      connectionStatus = "Permission Denied";
      notifyListeners();
      return;
    }

    isScanning = true;
    connectionStatus = "Scanning...";
    notifyListeners();
    
    // 2. Start Scan
    await _bleService.startScan();
    
    // 3. Auto-Connect Logic (Listen to Scan Results here)
    // We listen to the global FlutterBluePlus stream for simplicity
    FlutterBluePlus.scanResults.listen((results) async {
        for (ScanResult r in results) {
            // Check for SmartRacket
            if (r.device.platformName == "SmartRacket" && !isConnected) {
                print("Found SmartRacket! Connecting...");
                await _bleService.stopScan(); // Stop scanning
                await connectToDevice(r.device); // Connect
                break; 
            }
        }
    });
    
    // Safety timeout
    Future.delayed(const Duration(seconds: 10), () {
        if (isScanning && !isConnected) {
            isScanning = false;
            connectionStatus = "Device Not Found";
            _bleService.stopScan();
            notifyListeners();
        }
    });
  }
  
  Future<void> connectToDevice(BluetoothDevice device) async {
    isScanning = false;
    connectionStatus = "Connecting...";
    notifyListeners();
    
    try {
      await _bleService.connect(device);
      isConnected = true;
      connectionStatus = "Connected";
      notifyListeners();
      
      await _connectToServer();
    } catch (e) {
      connectionStatus = "Connection Failed";
      isConnected = false;
      notifyListeners();
    }
  }
  
  Future<void> disconnect() async {
    await _bleService.disconnect();
    _wsService.disconnect();
    isConnected = false;
    connectionStatus = "Disconnected";
    notifyListeners();
  }
  
  void updateSettings(double newThreshold, String newIp) {
    sensitivity = newThreshold;
    serverIp = newIp;
    
    _bufferManager.setThreshold(sensitivity);
    _connectToServer(); // Reconnect if IP changed
    notifyListeners();
  }

  // --- Internal ---
  
  Future<void> _connectToServer() async {
    final url = "ws://$serverIp:8000/ws/predict";
    try {
      await _wsService.connect(url);
      _wsService.stream?.listen((message) {
         _handleServerResponse(message);
      });
    } catch (e) {
      print("Server Connect Error: $e");
    }
  }

  void _handleNewFrame(IMUFrame frame) {
    // 1. Update Real-time Graph (Keep last 50 points for display)
    recentFrames.add(frame);
    if (recentFrames.length > 50) {
      recentFrames.removeAt(0);
    }
    batteryVoltage = frame.voltage;
    
    // 2. Add to Buffer Manager
    List<IMUFrame>? window = _bufferManager.addFrame(frame);
    
    // 3. Trigger?
    if (window != null) {
      // Send to Server
      print("Provider: Triggered! Sending ${window.length} frames...");
      _wsService.sendWindow("device_001", window);
      lastResultMessage = "Analyzing...";
    }
    
    // Notify UI (high frequency! might need optimization using StreamBuilder in UI)
    notifyListeners();
  }
  
  void _handleServerResponse(dynamic message) {
    // Parse JSON
    // {"type": "Smash", "speed": 185.5, "display": true, "message": "..."}
    try {
        final Map<String, dynamic> data = jsonDecode(message);
        bool display = data['display'] ?? false;
        
        if (display) {
            lastResultType = data['type'] ?? "Unknown";
            var spd = data['speed'];
            lastResultSpeed = (spd != null) ? "$spd km/h" : "";
            lastResultMessage = data['message'] ?? "";
            notifyListeners();
        }
    } catch (e) {
        print("JSON Error: $e");
    }
  }
}
