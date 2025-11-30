import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/ble_service.dart';
import '../services/firebase_service.dart';
import '../models/imu_data.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isRecording = false;
  String? _selectedLabel;
  StreamSubscription? _dataSubscription;

  final List<String> _actionLabels = ['smash', 'drive', 'toss', 'drop', 'other'];

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();
  }

  @override
  void dispose() {
    _dataSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🏸 Smart Racket'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Consumer<BleService>(
        builder: (context, ble, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 連線狀態卡片
                _buildConnectionCard(ble),
                const SizedBox(height: 12),

                // IMU 資料顯示
                if (ble.connectionState == BleConnectionState.connected) ...[
                  _buildDataCard(ble),
                  const SizedBox(height: 12),
                  _buildRecordingCard(ble),
                ],

                // 掃描結果
                if (ble.connectionState == BleConnectionState.scanning ||
                    (ble.connectionState == BleConnectionState.disconnected &&
                        ble.scanResults.isNotEmpty))
                  _buildScanResultsCard(ble),
              ],
            ),
          );
        },
      ),
    );
  }

  /// 連線狀態卡片
  Widget _buildConnectionCard(BleService ble) {
    final state = ble.connectionState;
    final isConnected = state == BleConnectionState.connected;
    final isScanning = state == BleConnectionState.scanning;
    final isConnecting = state == BleConnectionState.connecting;

    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (state) {
      case BleConnectionState.connected:
        statusColor = Colors.green;
        statusText = '已連線';
        statusIcon = Icons.bluetooth_connected;
        break;
      case BleConnectionState.scanning:
        statusColor = Colors.orange;
        statusText = '掃描中...';
        statusIcon = Icons.bluetooth_searching;
        break;
      case BleConnectionState.connecting:
        statusColor = Colors.blue;
        statusText = '連線中...';
        statusIcon = Icons.bluetooth;
        break;
      default:
        statusColor = Colors.grey;
        statusText = '未連線';
        statusIcon = Icons.bluetooth_disabled;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                      if (isConnected)
                        Text(
                          ble.deviceName,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                    ],
                  ),
                ),
                if (isConnected)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('封包: ${ble.packetCount}', 
                           style: const TextStyle(fontSize: 12)),
                      Text('錯誤: ${ble.errorCount}', 
                           style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isConnecting
                        ? null
                        : isConnected
                            ? () => ble.disconnect()
                            : isScanning
                                ? () => ble.stopScan()
                                : () => ble.startScan(),
                    icon: Icon(
                      isConnected
                          ? Icons.link_off
                          : isScanning
                              ? Icons.stop
                              : Icons.search,
                    ),
                    label: Text(
                      isConnected
                          ? '斷線'
                          : isScanning
                              ? '停止'
                              : '掃描裝置',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isConnected ? Colors.red : null,
                      foregroundColor: isConnected ? Colors.white : null,
                    ),
                  ),
                ),
                if (!isConnected && !isScanning) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: isConnecting ? null : () => ble.autoConnect(),
                      icon: const Icon(Icons.flash_on),
                      label: const Text('快速連線'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// IMU 資料卡片
  Widget _buildDataCard(BleService ble) {
    final data = ble.latestData;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.sensors, size: 20),
                SizedBox(width: 8),
                Text('IMU 即時資料',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(),
            if (data != null) ...[
              _buildSensorRow('加速度計 (g)', 
                  data.accX, data.accY, data.accZ,
                  Colors.blue),
              const SizedBox(height: 12),
              _buildSensorRow('陀螺儀 (°/s)', 
                  data.gyroX, data.gyroY, data.gyroZ,
                  Colors.orange),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('電壓', style: TextStyle(color: Colors.grey[600])),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getVoltageColor(data.voltage).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${data.voltage.toStringAsFixed(2)} V',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _getVoltageColor(data.voltage),
                      ),
                    ),
                  ),
                ],
              ),
            ] else
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('等待資料...', style: TextStyle(color: Colors.grey)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorRow(String label, double x, double y, double z, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        const SizedBox(height: 4),
        Row(
          children: [
            _buildAxisChip('X', x, Colors.red),
            const SizedBox(width: 8),
            _buildAxisChip('Y', y, Colors.green),
            const SizedBox(width: 8),
            _buildAxisChip('Z', z, Colors.blue),
          ],
        ),
      ],
    );
  }

  Widget _buildAxisChip(String axis, double value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(axis, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            Text(
              value.toStringAsFixed(2),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Color _getVoltageColor(double voltage) {
    if (voltage >= 3.7) return Colors.green;
    if (voltage >= 3.4) return Colors.orange;
    return Colors.red;
  }

  /// 錄製卡片
  Widget _buildRecordingCard(BleService ble) {
    final firebase = context.read<FirebaseService>();

    return Card(
      color: _isRecording ? Colors.red.shade50 : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _isRecording ? Icons.fiber_manual_record : Icons.cloud_upload,
                  color: _isRecording ? Colors.red : Colors.grey,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  _isRecording ? '錄製中...' : 'Firebase 錄製',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (_isRecording)
                  Text(
                    '已上傳: ${firebase.uploadedCount}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // 標籤選擇
            if (!_isRecording) ...[
              Text('動作類型（可選）:', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _actionLabels.map((label) {
                  final isSelected = _selectedLabel == label;
                  return ChoiceChip(
                    label: Text(label),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() => _selectedLabel = selected ? label : null);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
            ],

            // 錄製按鈕
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _toggleRecording(ble, firebase),
                icon: Icon(_isRecording ? Icons.stop : Icons.play_arrow),
                label: Text(_isRecording ? '停止錄製' : '開始錄製'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isRecording ? Colors.red : Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),

            if (_isRecording && firebase.currentSessionId != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Session: ${firebase.currentSessionId}',
                  style: TextStyle(color: Colors.grey[500], fontSize: 10),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleRecording(BleService ble, FirebaseService firebase) async {
    if (_isRecording) {
      // 停止錄製
      _dataSubscription?.cancel();
      await firebase.endSession(label: _selectedLabel);
      setState(() => _isRecording = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ 錄製完成！已上傳 ${firebase.uploadedCount} 筆資料'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      // 開始錄製
      await firebase.startSession();
      _dataSubscription = ble.imuDataStream.listen((data) {
        firebase.addData(data);
      });
      setState(() => _isRecording = true);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🔴 開始錄製...'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    }
  }

  /// 掃描結果卡片
  Widget _buildScanResultsCard(BleService ble) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.devices, size: 20),
                SizedBox(width: 8),
                Text('發現的裝置',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(),
            if (ble.scanResults.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: CircularProgressIndicator()),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: ble.scanResults.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final result = ble.scanResults[index];
                  final device = result.device;
                  final name = device.platformName.isNotEmpty
                      ? device.platformName
                      : 'Unknown';
                  final isSmartRacket = name.contains('SmartRacket');

                  return ListTile(
                    leading: Icon(
                      Icons.bluetooth,
                      color: isSmartRacket ? Colors.green : Colors.grey,
                    ),
                    title: Text(
                      name,
                      style: TextStyle(
                        fontWeight: isSmartRacket ? FontWeight.bold : FontWeight.normal,
                        color: isSmartRacket ? Colors.green : null,
                      ),
                    ),
                    subtitle: Text('${result.rssi} dBm'),
                    trailing: isSmartRacket
                        ? const Icon(Icons.star, color: Colors.amber)
                        : null,
                    onTap: () => ble.connect(device),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
