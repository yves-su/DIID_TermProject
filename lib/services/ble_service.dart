import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../models/imu_data.dart';

/// BLE 服務 UUID (與 Arduino 相同)
const String SERVICE_UUID = "0769bb8e-b496-4fdd-b53b-87462ff423d0";
const String CHARACTERISTIC_UUID = "8ee82f5b-76c7-4170-8f49-fff786257090";
const String DEVICE_NAME = "SmartRacket";

/// BLE 連線狀態
enum BleConnectionState {
  disconnected,
  scanning,
  connecting,
  connected,
}

/// BLE 服務 - 管理藍牙連線和資料接收
class BleService extends ChangeNotifier {
  // 連線狀態
  BleConnectionState _connectionState = BleConnectionState.disconnected;
  BleConnectionState get connectionState => _connectionState;

  // 已連線的裝置
  BluetoothDevice? _connectedDevice;
  BluetoothDevice? get connectedDevice => _connectedDevice;
  String get deviceName => _connectedDevice?.platformName ?? '未連線';

  // 掃描到的裝置列表
  List<ScanResult> _scanResults = [];
  List<ScanResult> get scanResults => _scanResults;

  // IMU 資料串流
  final StreamController<IMUData> _imuDataController = StreamController.broadcast();
  Stream<IMUData> get imuDataStream => _imuDataController.stream;

  // 最新的 IMU 資料
  IMUData? _latestData;
  IMUData? get latestData => _latestData;

  // 統計資料
  int _packetCount = 0;
  int get packetCount => _packetCount;
  
  int _errorCount = 0;
  int get errorCount => _errorCount;

  // 訂閱
  StreamSubscription? _scanSubscription;
  StreamSubscription? _connectionSubscription;
  StreamSubscription? _characteristicSubscription;

  BleService() {
    _init();
  }

  Future<void> _init() async {
    // 監聽藍牙狀態
    FlutterBluePlus.adapterState.listen((state) {
      if (state != BluetoothAdapterState.on) {
        _updateConnectionState(BleConnectionState.disconnected);
      }
    });
  }

  /// 開始掃描裝置
  Future<void> startScan() async {
    if (_connectionState == BleConnectionState.scanning) return;

    _scanResults.clear();
    _updateConnectionState(BleConnectionState.scanning);

    await _scanSubscription?.cancel();

    // 監聽掃描結果
    _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      _scanResults = results.where((r) {
        final name = r.device.platformName;
        return name.isNotEmpty;
      }).toList();
      notifyListeners();
    });

    // 開始掃描 (10 秒)
    await FlutterBluePlus.startScan(
      timeout: const Duration(seconds: 10),
    );

    // 掃描結束
    Future.delayed(const Duration(seconds: 10), () {
      if (_connectionState == BleConnectionState.scanning) {
        _updateConnectionState(BleConnectionState.disconnected);
      }
    });
  }

  /// 停止掃描
  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
    if (_connectionState == BleConnectionState.scanning) {
      _updateConnectionState(BleConnectionState.disconnected);
    }
  }

  /// 自動連線到 SmartRacket
  Future<bool> autoConnect() async {
    _updateConnectionState(BleConnectionState.scanning);
    _scanResults.clear();

    // 掃描
    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));
    await Future.delayed(const Duration(seconds: 5));
    await FlutterBluePlus.stopScan();

    // 找 SmartRacket
    for (var result in _scanResults) {
      if (result.device.platformName.contains(DEVICE_NAME)) {
        await connect(result.device);
        return _connectionState == BleConnectionState.connected;
      }
    }

    _updateConnectionState(BleConnectionState.disconnected);
    return false;
  }

  /// 連線到裝置
  Future<void> connect(BluetoothDevice device) async {
    try {
      _updateConnectionState(BleConnectionState.connecting);
      await FlutterBluePlus.stopScan();

      // 連線
      await device.connect(timeout: const Duration(seconds: 10));
      _connectedDevice = device;

      // 監聽連線狀態
      _connectionSubscription = device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          _handleDisconnect();
        }
      });

      // 發現服務
      List<BluetoothService> services = await device.discoverServices();
      
      // 找到目標服務和特徵
      for (var service in services) {
        if (service.uuid.toString().toLowerCase() == SERVICE_UUID.toLowerCase()) {
          for (var characteristic in service.characteristics) {
            if (characteristic.uuid.toString().toLowerCase() == CHARACTERISTIC_UUID.toLowerCase()) {
              // 啟用通知
              await characteristic.setNotifyValue(true);
              
              // 監聽資料
              _characteristicSubscription = characteristic.onValueReceived.listen(_handleData);
              
              _packetCount = 0;
              _errorCount = 0;
              _updateConnectionState(BleConnectionState.connected);
              print('Connected to $DEVICE_NAME!');
              return;
            }
          }
        }
      }

      throw Exception('Service or characteristic not found');
    } catch (e) {
      print('Connection error: $e');
      await disconnect();
    }
  }

  /// 處理接收到的資料
  void _handleData(List<int> data) {
    final imuData = IMUData.fromPacket(data);
    if (imuData != null) {
      _latestData = imuData;
      _packetCount++;
      _imuDataController.add(imuData);
      notifyListeners();
    } else {
      _errorCount++;
    }
  }

  /// 斷線
  Future<void> disconnect() async {
    await _characteristicSubscription?.cancel();
    await _connectionSubscription?.cancel();
    await _connectedDevice?.disconnect();
    _handleDisconnect();
  }

  void _handleDisconnect() {
    _connectedDevice = null;
    _latestData = null;
    _updateConnectionState(BleConnectionState.disconnected);
  }

  void _updateConnectionState(BleConnectionState state) {
    _connectionState = state;
    notifyListeners();
  }

  /// 重置統計
  void resetStats() {
    _packetCount = 0;
    _errorCount = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    _connectionSubscription?.cancel();
    _characteristicSubscription?.cancel();
    _imuDataController.close();
    super.dispose();
  }
}
