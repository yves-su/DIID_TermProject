import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../models/imu_frame.dart';

class BLEService {
  // UUIDs from README
  static const String SERVICE_UUID = "0769bb8e-b496-4fdd-b53b-87462ff423d0";
  static const String CHAR_IMU_UUID = "8ee82f5b-76c7-4170-8f49-fff786257090";
  static const String CHAR_TIME_UUID = "8ee82f5b-76c7-4170-8f49-fff786257091";

  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _imuChar;
  BluetoothCharacteristic? _timeChar;

  StreamSubscription<List<ScanResult>>? _scanSubscription;
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;
  StreamSubscription<List<int>>? _imuSubscription;

  // Stream to expose parsed IMU frames to the APP
  final _imuStreamController = StreamController<IMUFrame>.broadcast();
  Stream<IMUFrame> get imuStream => _imuStreamController.stream;

  Future<void> init() async {
    // Check if bluetooth is supported/on
    if (await FlutterBluePlus.isSupported == false) {
      print("BLE not supported");
      return;
    }
    
    // Turn on bluetooth (Android only)
    if (Platform.isAndroid) {
      await FlutterBluePlus.turnOn();
    }
  }

  /// Start scanning for "SmartRacket"
  Future<void> startScan() async {
    await FlutterBluePlus.startScan(
      timeout: const Duration(seconds: 15),
      withServices: [Guid(SERVICE_UUID)], // Filter by Service UUID
    );

    _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      for (ScanResult r in results) {
        if (r.device.platformName == "SmartRacket" || r.advertisementData.connectable) {
            // Found it! 
            // In a real app we might list them. Here we auto-connect for simplicity?
            // User requested "Auto Scan", but typically UI shows a button.
            // Let's stop scan once found (if we implement auto-connect).
        }
      }
    });
  }

  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
    _scanSubscription?.cancel();
  }

  /// Connect to a specific device
  Future<void> connect(BluetoothDevice device) async {
    _connectedDevice = device;
    
    // Listen to connection state
    _connectionSubscription = device.connectionState.listen((state) {
      print("BLE State: $state");
      if (state == BluetoothConnectionState.disconnected) {
        // Handle disconnect logic
      }
    });

    await device.connect();
    
    // Discover Services
    List<BluetoothService> services = await device.discoverServices();
    for (var s in services) {
      if (s.uuid.toString() == SERVICE_UUID) {
        for (var c in s.characteristics) {
          if (c.uuid.toString() == CHAR_IMU_UUID) {
            _imuChar = c;
            await _setupNotification(c);
          } else if (c.uuid.toString() == CHAR_TIME_UUID) {
            _timeChar = c;
          }
        }
      }
    }
    
    // Sync Time after connection
    await syncTime();
  }

  Future<void> disconnect() async {
    await _connectedDevice?.disconnect();
    _scanSubscription?.cancel();
    _connectionSubscription?.cancel();
    _imuSubscription?.cancel();
  }

  Future<void> _setupNotification(BluetoothCharacteristic c) async {
    await c.setNotifyValue(true);
    _imuSubscription = c.lastValueStream.listen((value) {
      _parsePacket(value);
    });
  }
  
  /// Sync phone time to MCU
  Future<void> syncTime() async {
    if (_timeChar == null) return;
    
    int now = DateTime.now().millisecondsSinceEpoch ~/ 1000; // Unix Seconds
    // Convert to 4 bytes little endian
    var data = ByteData(4);
    data.setUint32(0, now, Endian.little);
    
    try {
      await _timeChar!.write(data.buffer.asUint8List());
      print("BLE: Time Synced ($now)");
    } catch (e) {
      print("BLE: Time Sync Failed: $e");
    }
  }

  /// Parse 34-byte packet
  void _parsePacket(List<int> bytes) {
    if (bytes.length < 34) return;

    final bd = ByteData.sublistView(Uint8List.fromList(bytes));
    
    // Little Endian
    // 0-3: timestamp (uint32)
    // 4-5: ms (uint16)
    // 6-9: ax (float) ...
    
    // NOTE: The README says floats are 4 bytes.
    // Ensure the MCU sends IEEE 754 floats.
    
    double ts = bd.getUint32(0, Endian.little).toDouble();
    double ms = bd.getUint16(4, Endian.little).toDouble();
    double combinedTime = ts + (ms / 1000.0);
    
    double ax = bd.getFloat32(6, Endian.little);
    double ay = bd.getFloat32(10, Endian.little);
    double az = bd.getFloat32(14, Endian.little);
    
    double gx = bd.getFloat32(18, Endian.little);
    double gy = bd.getFloat32(22, Endian.little);
    double gz = bd.getFloat32(26, Endian.little);
    
    int voltage = bd.getUint16(30, Endian.little);
    
    final frame = IMUFrame(
      timestamp: combinedTime,
      acc: [ax, ay, az],
      gyro: [gx, gy, gz],
      voltage: voltage / 1000.0, // mV -> V
    );
    
    _imuStreamController.add(frame);
  }
}
