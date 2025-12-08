import 'dart:collection';
import 'dart:math';
import '../models/imu_frame.dart';

class DataBufferManager {
  // Configurable parameters
  int _windowSize = 40; // Total frames to keep (e.g., 40 frames ~ 0.8s)
  int _preTriggerFrames = 20; // Frames to keep BEFORE the peak
  double _triggerThreshold = 2.0; // Acceleration threshold in G
  
  // Internal buffer
  final ListQueue<IMUFrame> _buffer = ListQueue<IMUFrame>();
  
  // State
  bool _isCoolingDown = false;
  DateTime? _lastTriggerTime;
  final Duration _coolDownDuration = const Duration(seconds: 1);

  // Setters for dynamic configuration
  void setThreshold(double value) {
    _triggerThreshold = value;
  }
  
  void setWindowConfig(int size, int preTrigger) {
    _windowSize = size;
    _preTriggerFrames = preTrigger;
  }

  /// Add a new frame and check if it triggers a swing event.
  /// Returns a list of frames (Window) if triggered, otherwise null.
  List<IMUFrame>? addFrame(IMUFrame frame) {
    // 1. Add to buffer
    _buffer.add(frame);
    
    // Keep buffer slightly larger than needed to ensure we have history
    // We need at least _windowSize, but let's keep a bit more to be safe
    if (_buffer.length > _windowSize * 2) {
      _buffer.removeFirst();
    }

    // 2. Check cool down
    if (_isCoolingDown) {
      if (DateTime.now().difference(_lastTriggerTime!) > _coolDownDuration) {
        _isCoolingDown = false;
      }
      return null;
    }

    // 3. Check trigger condition
    // Calculate magnitude of acceleration (excluding gravity typically, but here we use raw)
    // Simple magnitude check: sqrt(x^2 + y^2 + z^2)
    double mag = sqrt(pow(frame.acc[0], 2) + pow(frame.acc[1], 2) + pow(frame.acc[2], 2));
    
    // If we exceed threshold and have enough history
    if (mag > _triggerThreshold && _buffer.length >= _windowSize) {
      // TRIGGERED!
      return _extractWindow();
    }
    
    return null;
  }

  List<IMUFrame> _extractWindow() {
    _isCoolingDown = true;
    _lastTriggerTime = DateTime.now();

    // Logic: We are at the PEAK (or just passed it).
    // We want to capture: [Current - Pre, Current + Post]
    // Wait... if we trigger NOW, we only have "Current" and "History". 
    // We don't have "Future" data yet.
    
    // STRATEGY ADJUSTMENT:
    // Real-time classification usually implies we detect the PEAK.
    // However, to get the "Post-peak" data, we would need to wait/buffer more frames 
    // OR we assume the "Trigger" happens at the END of the swing?
    //
    // usually:
    // 1. Continuous buffering.
    // 2. Detect Peak > Threshold.
    // 3. Wait for N more frames (Post-peak).
    // 4. Then extract the window.
    
    // For simplicity in V3.0 (Low Latency):
    // Let's assume the trigger happens near the END of the acceleration phase (impact).
    // So we take the LAST N frames.
    // 
    // If the user wants "Centered" window (e.g. Peak in the middle), 
    // we technically need to "delay" the sending by `_windowSize - _preTriggerFrames`.
    //
    // For now, let's just dump the LAST `_windowSize` frames available in the buffer.
    // This gives us mostly "Events leading up to now".
    
    List<IMUFrame> all = _buffer.toList();
    int count = all.length;
    
    if (count < _windowSize) {
      return all; // Should not happen due to check above
    }
    
    // Take the last _windowSize frames
    return all.sublist(count - _windowSize, count);
  }
  
  void clear() {
    _buffer.clear();
    _isCoolingDown = false;
  }
}
