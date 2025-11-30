import 'dart:typed_data';

/// IMU 資料模型
/// 封包格式 (30 bytes, Little-Endian):
/// [Timestamp(4)][AccX(4)][AccY(4)][AccZ(4)][GyroX(4)][GyroY(4)][GyroZ(4)][Voltage(2)]
class IMUData {
  final int timestamp;      // 毫秒時間戳
  final double accX;        // 加速度 X (g)
  final double accY;        // 加速度 Y (g)
  final double accZ;        // 加速度 Z (g)
  final double gyroX;       // 角速度 X (dps)
  final double gyroY;       // 角速度 Y (dps)
  final double gyroZ;       // 角速度 Z (dps)
  final double voltage;     // 電壓 (V)
  final DateTime receivedAt;

  IMUData({
    required this.timestamp,
    required this.accX,
    required this.accY,
    required this.accZ,
    required this.gyroX,
    required this.gyroY,
    required this.gyroZ,
    required this.voltage,
    DateTime? receivedAt,
  }) : receivedAt = receivedAt ?? DateTime.now();

  /// 從 BLE 封包解析資料 (30 bytes)
  static IMUData? fromPacket(List<int> packet) {
    // 驗證封包長度
    if (packet.length != 30) {
      print('Invalid packet length: ${packet.length}, expected 30');
      return null;
    }

    try {
      final buffer = ByteData.sublistView(Uint8List.fromList(packet));
      
      // 解析各欄位 (Little-Endian)
      int offset = 0;
      
      // Timestamp (4 bytes)
      final timestamp = buffer.getUint32(offset, Endian.little);
      offset += 4;
      
      // Accelerometer XYZ (12 bytes)
      final accX = buffer.getFloat32(offset, Endian.little);
      offset += 4;
      final accY = buffer.getFloat32(offset, Endian.little);
      offset += 4;
      final accZ = buffer.getFloat32(offset, Endian.little);
      offset += 4;
      
      // Gyroscope XYZ (12 bytes)
      final gyroX = buffer.getFloat32(offset, Endian.little);
      offset += 4;
      final gyroY = buffer.getFloat32(offset, Endian.little);
      offset += 4;
      final gyroZ = buffer.getFloat32(offset, Endian.little);
      offset += 4;
      
      // Voltage (2 bytes) - 原始值除以 100
      final voltageRaw = buffer.getUint16(offset, Endian.little);
      final voltage = voltageRaw / 100.0;

      return IMUData(
        timestamp: timestamp,
        accX: accX,
        accY: accY,
        accZ: accZ,
        gyroX: gyroX,
        gyroY: gyroY,
        gyroZ: gyroZ,
        voltage: voltage,
      );
    } catch (e) {
      print('Error parsing packet: $e');
      return null;
    }
  }

  /// 轉換為 Firebase JSON 格式
  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp,
      'acc': {'x': accX, 'y': accY, 'z': accZ},
      'gyro': {'x': gyroX, 'y': gyroY, 'z': gyroZ},
      'voltage': voltage,
      'received_at': receivedAt.toIso8601String(),
    };
  }

  /// 驗證資料是否在合理範圍內
  bool isValid() {
    // 加速度範圍: ±16g
    if (accX.abs() > 16 || accY.abs() > 16 || accZ.abs() > 16) {
      return false;
    }
    // 角速度範圍: ±2000 dps
    if (gyroX.abs() > 2000 || gyroY.abs() > 2000 || gyroZ.abs() > 2000) {
      return false;
    }
    // 電壓範圍: 2.5V ~ 4.5V
    if (voltage < 2.5 || voltage > 4.5) {
      return false;
    }
    return true;
  }

  @override
  String toString() {
    return 'IMU[t:$timestamp] Acc(${accX.toStringAsFixed(2)}, ${accY.toStringAsFixed(2)}, ${accZ.toStringAsFixed(2)}) '
        'Gyro(${gyroX.toStringAsFixed(1)}, ${gyroY.toStringAsFixed(1)}, ${gyroZ.toStringAsFixed(1)}) '
        'V:${voltage.toStringAsFixed(2)}';
  }
}
