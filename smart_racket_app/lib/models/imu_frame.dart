class IMUFrame {
  final double timestamp; // Unix timestamp in seconds
  final List<double> acc; // [x, y, z] in G
  final List<double> gyro; // [x, y, z] in dps
  final double voltage; // battery voltage

  IMUFrame({
    required this.timestamp,
    required this.acc,
    required this.gyro,
    this.voltage = 0.0,
  });

  Map<String, dynamic> toJson() {
    return {
      "ts": timestamp,
      "acc": acc,
      "gyro": gyro,
      // Voltage is usually not needed for inference, but kept in model
    };
  }
  
  @override
  String toString() {
    return 'IMUFrame(ts: $timestamp, acc: $acc)';
  }
}
