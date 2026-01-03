import 'dart:collection';

import '../models/imu_frame.dart';

class DataBufferManager {
  // ---- Windowing / trigger parameters ----
  //
  // DataBufferManager 的職責是把連續 IMUFrame 串流做「條件觸發式視窗擷取」：
  // - _windowSize：總共要輸出的視窗長度 (Total Length)
  // - _postTriggerFrames：觸發後要再多收集幾張 (Wait count)
  // - _triggerThresholdG：以加速度向量大小（g）作為觸發門檻
  //
  // 行為：
  // 平常一直收資料進 Buffer。
  // 當滿足 Trigger 條件時，進入「收集剩餘資料模式」。
  // 繼續收集 _postTriggerFrames 張之後，回傳最後的 _windowSize 張。
  // (這樣就能達成例如：總共 40 張，Trigger 後收集 10 張 -> 結果就是 Trigger 前 30 張 + Trigger 後 10 張)
  int _windowSize = 40;
  int _postTriggerFrames = 20;
  double _triggerThresholdG = 2.0;

  // ---- Collecting State ----
  bool _isCollecting = false;
  int _collectingCounter = 0;

  // ---- Cooldown control ----
  //
  // 觸發後的冷卻時間：避免一次揮拍或高能量區段在短時間內連續觸發多次。
  // 這裡使用「系統時間」作為 cooldown 判斷基準（wall clock），
  // 不依賴 frame.timestamp（避免 timestamp 不穩、掉包、重置等導致 cooldown 失效或卡住）。
  Duration _coolDownDuration = const Duration(seconds: 1);

  // ✅ 用系統時間做 cooldown（避免 frame.timestamp 不穩造成誤判或卡住）
  int _lastTriggerWallMs = 0;

  // ---- Internal buffer ----
  //
  // 用 ListQueue 當滑動緩衝：高頻 add/removeFirst 成本穩定。
  // buffer 不是無限長，會在 _trimToMaxKeep() 限制最大保留量，避免觸發時 toList 太重。
  final ListQueue<IMUFrame> _buffer = ListQueue<IMUFrame>();

  // ---- Convenience setters ----
  //
  // 對外暴露兩個同義方法（便於上層呼叫習慣一致），最後都走 thresholdG setter 做驗證。
  void setThresholdG(double value) => thresholdG = value;
  void updateThreshold(double value) => thresholdG = value;

  // ---- Threshold validation ----
  //
  // 門檻必須是正數且 finite；無效值直接忽略（保持既有設定），避免 runtime 進入不可預期狀態。
  double get thresholdG => _triggerThresholdG;
  set thresholdG(double v) {
    if (!v.isFinite || v.isNaN || v <= 0) return;
    _triggerThresholdG = v;
  }

  // ---- Read-only accessors for UI / settings ----
  int get windowSize => _windowSize;
  int get postTriggerFrames => _postTriggerFrames; // Export for UI
  Duration get coolDownDuration => _coolDownDuration;

  // ---- Window configuration ----
  //
  // 允許 UI/上層調整參數：
  // - windowSize 下限 10
  // - postTriggerFrames 必須 < windowSize (不然全是 trigger 後的資料也不合理，雖然技術上可行)
  void setWindowConfig({
    int? windowSize,
    int? postTriggerFrames, // New: 以前是 preTrigger，現在改設 trigger 後要留多少
    Duration? coolDown,
  }) {
    if (windowSize != null && windowSize >= 10) _windowSize = windowSize;
    if (postTriggerFrames != null && postTriggerFrames >= 0) {
      _postTriggerFrames = postTriggerFrames;
    }
    if (coolDown != null) _coolDownDuration = coolDown;

    // Safety: Post 不可大於 Window (會導致抓不到 Trigger 前的資料)
    if (_postTriggerFrames >= _windowSize) {
      _postTriggerFrames = _windowSize ~/ 2;
    }

    _trimToMaxKeep();
  }

  // ---- Streaming entry point ----
  //
  // addFrame() 是資料串流入口 + 狀態機：
  // 1) 基本檢查與 buffer 維護
  // 2) 若正在 Collecting 狀態 -> 倒數，數完這一次就 Output
  // 3) 若 Idle 狀態 -> 檢查 Trigger -> 若中，進入 Collecting (或直接 Output)
  List<IMUFrame>? addFrame(IMUFrame frame) {
    if (!_isFrameFinite(frame)) return null;

    _buffer.addLast(frame);
    _trimToMaxKeep();

    // --- State Machine ---

    // 1. 若正在收集 Trigger 後續資料
    if (_isCollecting) {
      _collectingCounter--;
      if (_collectingCounter <= 0) {
        // 收集完畢，產出資料，回到 Idle
        _isCollecting = false;
        return _extractWindow();
      }
      return null;
    }

    // 2. 若在 Idle，檢查 Cooldown
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    if (_lastTriggerWallMs != 0) {
      final dt = nowMs - _lastTriggerWallMs;
      if (dt < _coolDownDuration.inMilliseconds) return null;
    }

    // 3. 檢查 Buffer 長度是否足夠 (至少要有 windowSize 這麼多才有資料可切)
    if (_buffer.length < _windowSize) return null;

    // 4. 檢查 Trigger 條件
    final ax = frame.acc[0];
    final ay = frame.acc[1];
    final az = frame.acc[2];

    // compare squared magnitude (避免 sqrt overhead)
    final mag2 = ax * ax + ay * ay + az * az;
    final th2 = _triggerThresholdG * _triggerThresholdG;

    if (mag2 > th2) {
      _lastTriggerWallMs = nowMs;

      if (_postTriggerFrames > 0) {
        // 設定倒數計時，繼續收資料
        _isCollecting = true;
        _collectingCounter = _postTriggerFrames;
        return null;
      } else {
        // 不需要後續資料，直接噴
        return _extractWindow();
      }
    }
    return null;
  }

  // ---- Window extraction ----
  //
  // 視窗擷取策略：
  // - 直接取 buffer 當中「最後 _windowSize」筆資料
  // - 因為 State Machine 保證了我們是在 (Trigger + Post) 之後才呼叫這裡
  // - 所以這一段資料就會包含： [ ... Pre ... (Trigger) ... Post ...]
  List<IMUFrame> _extractWindow() {
    final list = _buffer.toList(growable: false);
    
    // 如果 buffer 很長，只取最後 windowSize
    if (list.length > _windowSize) {
      return list.sublist(list.length - _windowSize);
    }
    
    // 不足的話就全給 (理論上 addFrame 已經擋過長度 check，不應發生)
    return list;
  }

  // ---- Buffer cap ----
  //
  // buffer 上限設為 windowSize * 3 就很夠了
  void _trimToMaxKeep() {
    final maxKeep = _windowSize * 3;
    while (_buffer.length > maxKeep) {
      _buffer.removeFirst();
    }
  }

  // ---- Hard reset ----
  void clear() {
    _buffer.clear();
    _lastTriggerWallMs = 0;
    _isCollecting = false;
    _collectingCounter = 0;
  }

  // ---- Data integrity guard ----
  bool _isFrameFinite(IMUFrame f) {
    bool ok3(List<double> a) =>
        a.length == 3 && a.every((v) => v.isFinite && !v.isNaN);

    return f.timestamp.isFinite &&
        !f.timestamp.isNaN &&
        ok3(f.acc) &&
        ok3(f.gyro) &&
        f.voltage.isFinite &&
        !f.voltage.isNaN;
  }
}
