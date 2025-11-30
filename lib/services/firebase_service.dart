import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:uuid/uuid.dart';
import '../models/imu_data.dart';

/// Firebase Realtime Database 服務
class FirebaseService {
  // 使用你的 Firebase Realtime Database URL
  late final DatabaseReference _database;
  final Uuid _uuid = const Uuid();

  // 當前 session
  String? _currentSessionId;
  String? get currentSessionId => _currentSessionId;
  
  bool get isRecording => _currentSessionId != null;

  // 資料緩衝區（批次上傳用）
  final List<IMUData> _dataBuffer = [];
  static const int BUFFER_SIZE = 50;

  // 統計
  int _uploadedCount = 0;
  int get uploadedCount => _uploadedCount;
  
  int _pendingCount = 0;
  int get pendingCount => _pendingCount;

  FirebaseService() {
    _database = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: 'https://smart-badminton-ca6f3-default-rtdb.asia-southeast1.firebasedatabase.app',
    ).ref();
  }

  /// 開始新的錄製 session
  Future<String> startSession({String deviceId = 'SmartRacket'}) async {
    _currentSessionId = _uuid.v4().substring(0, 8);
    _uploadedCount = 0;
    _pendingCount = 0;
    _dataBuffer.clear();

    await _database.child('sessions/$_currentSessionId/metadata').set({
      'created_at': DateTime.now().toIso8601String(),
      'device_id': deviceId,
      'sample_rate': 50,
      'status': 'recording',
    });

    print('Started session: $_currentSessionId');
    return _currentSessionId!;
  }

  /// 新增 IMU 資料
  Future<void> addData(IMUData data) async {
    if (_currentSessionId == null) return;

    _dataBuffer.add(data);
    _pendingCount = _dataBuffer.length;

    if (_dataBuffer.length >= BUFFER_SIZE) {
      await _flushBuffer();
    }
  }

  /// 批次上傳
  Future<void> _flushBuffer() async {
    if (_currentSessionId == null || _dataBuffer.isEmpty) return;

    try {
      final updates = <String, dynamic>{};
      for (var data in _dataBuffer) {
        final dataId = _uuid.v4().substring(0, 8);
        updates['sessions/$_currentSessionId/raw_data/$dataId'] = data.toJson();
      }

      await _database.update(updates);
      _uploadedCount += _dataBuffer.length;
      _dataBuffer.clear();
      _pendingCount = 0;

      print('Uploaded batch: total $_uploadedCount');
    } catch (e) {
      print('Upload error: $e');
    }
  }

  /// 結束錄製
  Future<void> endSession({String? label}) async {
    if (_currentSessionId == null) return;

    await _flushBuffer();

    await _database.child('sessions/$_currentSessionId/metadata').update({
      'status': 'completed',
      'ended_at': DateTime.now().toIso8601String(),
      'total_samples': _uploadedCount,
    });

    if (label != null && label.isNotEmpty) {
      await _database.child('sessions/$_currentSessionId/label').set(label);
    }

    print('Ended session: $_currentSessionId with $uploadedCount samples');
    _currentSessionId = null;
  }

  /// 取消 session
  Future<void> cancelSession() async {
    if (_currentSessionId == null) return;

    try {
      await _database.child('sessions/$_currentSessionId').remove();
    } catch (e) {
      print('Cancel error: $e');
    }
    
    _dataBuffer.clear();
    _currentSessionId = null;
    _uploadedCount = 0;
    _pendingCount = 0;
  }
}