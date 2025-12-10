import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../models/imu_frame.dart';

class BLEService {
  // UUIDs: 這些是藍牙裝置的身分證字號，必須跟 Arduino 程式碼裡面的一樣
  static const String SERVICE_UUID = "0769bb8e-b496-4fdd-b53b-87462ff423d0";
  static const String CHAR_IMU_UUID = "8ee82f5b-76c7-4170-8f49-fff786257090";
  static const String CHAR_TIME_UUID = "8ee82f5b-76c7-4170-8f49-fff786257091";

  // 用來儲存目前連線的裝置和特徵值 (Characteristic)
  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _imuChar;  // 用來收感測器資料
  BluetoothCharacteristic? _timeChar; // 用來傳送時間

  // 用來管理各種監聽器 (Listener)，不用時要取消訂閱 (cancel) 以免記憶體洩漏
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;
  StreamSubscription<List<int>>? _imuSubscription;

  // Stream (串流) 控制器：
  // 這是我們自己建立的一個廣播站，當我們收到藍牙資料並整理好之後，
  // 就透過這個 Stream 廣播給 APP 的其他介面 (UI) 知道
  final _imuStreamController = StreamController<IMUFrame>.broadcast();
  Stream<IMUFrame> get imuStream => _imuStreamController.stream;

  // --- 初始化 ---
  Future<void> init() async {
    // 檢查手機支不支援藍牙，或是有沒有開
    if (await FlutterBluePlus.isSupported == false) {
      print("BLE not supported");
      return;
    }
    
    // 如果是 Android 手機，嘗試幫使用者打開藍牙
    if (Platform.isAndroid) {
      await FlutterBluePlus.turnOn();
    }
  }

  /// 開始掃描名為 "SmartRacket" 的裝置
  Future<void> startScan() async {
    // 使用 FlutterBluePlus 開始掃描
    await FlutterBluePlus.startScan(
      timeout: const Duration(seconds: 15), // 掃 15 秒後自動停止
      withServices: [Guid(SERVICE_UUID)],   // 只找我們要的那個服務 UUID，過濾掉雜訊
    );

    // 監聽掃描結果
    _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      for (ScanResult r in results) {
        if (r.device.platformName == "SmartRacket" || r.advertisementData.connectable) {
            // 找到了！
            // 這裡通常會更新 UI 列表讓使用者選
        }
      }
    });
  }

  /// 停止掃描
  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
    _scanSubscription?.cancel();
  }

  /// 連線到指定的裝置
  Future<void> connect(BluetoothDevice device) async {
    _connectedDevice = device;
    
    // 監聽連線狀態 (例如突然斷線了)
    _connectionSubscription = device.connectionState.listen((state) {
      print("BLE State: $state");
      if (state == BluetoothConnectionState.disconnected) {
        // 這裡可以處理斷線後的邏輯 (目前交給 Provider 處理)
      }
    });

    // 真正的連線動作
    await device.connect();
    
    // 連線成功後，要「探索服務」(Discover Services)
    // 就像是進入一間餐廳 (連線)，要先拿菜單 (服務列表) 才知道怎麼點餐
    List<BluetoothService> services = await device.discoverServices();
    for (var s in services) {
      if (s.uuid.toString() == SERVICE_UUID) {
        // 找到我們的主服務了！接著找裡面的特徵值
        for (var c in s.characteristics) {
          if (c.uuid.toString() == CHAR_IMU_UUID) {
            _imuChar = c;
            await _setupNotification(c); // 訂閱通知，這樣資料來了才會收到
          } else if (c.uuid.toString() == CHAR_TIME_UUID) {
            _timeChar = c;
          }
        }
      }
    }
    
    // 連線完成後，順便幫 MCU 對時
    await syncTime();
  }

  /// 斷開連線並清理資源
  Future<void> disconnect() async {
    await _connectedDevice?.disconnect();
    _scanSubscription?.cancel();
    _connectionSubscription?.cancel();
    _imuSubscription?.cancel();
  }

  /// 訂閱特徵值通知
  // 這樣當 MCU 發送資料 (Notify) 時，我們就會收到
  Future<void> _setupNotification(BluetoothCharacteristic c) async {
    await c.setNotifyValue(true); // 開啟通知
    // 監聽資料流
    _imuSubscription = c.lastValueStream.listen((value) {
      _parsePacket(value); // 解析收到的原始資料 (bytes)
    });
  }
  
  /// 將手機目前的時間同步給 MCU
  Future<void> syncTime() async {
    if (_timeChar == null) return;
    
    // 取得現在時間 (Unix Timestamp 秒數)
    int now = DateTime.now().millisecondsSinceEpoch ~/ 1000; 
    
    // 將整數轉換成 4 個 byte (Little Endian 排列)
    var data = ByteData(4);
    data.setUint32(0, now, Endian.little);
    
    try {
      await _timeChar!.write(data.buffer.asUint8List());
      print("BLE: Time Synced ($now)");
    } catch (e) {
      print("BLE: Time Sync Failed: $e");
    }
  }

  /// 解析 34-byte 的資料封包
  // 這邊必須跟 Arduino 的 struct DataPacket 結構完全對應
  void _parsePacket(List<int> bytes) {
    if (bytes.length < 34) return; // 資料長度不足，丟棄

    // 使用 ByteData 來方便讀取各種型態 (int, float)
    final bd = ByteData.sublistView(Uint8List.fromList(bytes));
    
    // Little Endian: 低位元組在前
    // 0-3: timestamp (uint32)
    // 4-5: ms (uint16)
    // 6-9: ax (float) ...
    
    double ts = bd.getUint32(0, Endian.little).toDouble();
    double ms = bd.getUint16(4, Endian.little).toDouble();
    double combinedTime = ts + (ms / 1000.0); // 結合成完整時間
    
    // 讀取加速度 (ax, ay, az)
    double ax = bd.getFloat32(6, Endian.little);
    double ay = bd.getFloat32(10, Endian.little);
    double az = bd.getFloat32(14, Endian.little);
    
    // 讀取角速度 (gx, gy, gz)
    double gx = bd.getFloat32(18, Endian.little);
    double gy = bd.getFloat32(22, Endian.little);
    double gz = bd.getFloat32(26, Endian.little);
    
    // 讀取電壓 (mV)
    int voltage = bd.getUint16(30, Endian.little);
    
    // 建立 IMUFrame 物件
    final frame = IMUFrame(
      timestamp: combinedTime,
      acc: [ax, ay, az],
      gyro: [gx, gy, gz],
      voltage: voltage / 1000.0, // 換算成伏特 (V)
    );
    
    // 透過 Stream 發送出去給 UI 或是 Provider
    _imuStreamController.add(frame);
  }
}
