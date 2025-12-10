import 'dart:collection';
import 'dart:math';
import '../models/imu_frame.dart';

class DataBufferManager {
  // --- 設定參數 (Configuration) ---
  // _windowSize: 我們要抓取的資料「視窗」大小。
  // 40 筆資料約等於 0.8 秒 (若傳輸是 50Hz)，代表一個完整揮拍動作的時間長度。
  int _windowSize = 40; 
  
  // _preTriggerFrames: 當偵測到揮拍時，我們要保留從比較早開始的幾筆資料。
  // 因為揮拍最大的力道通常在中間，所以要往前抓一些資料才會有完整的「上揮」動作。
  int _preTriggerFrames = 20; 
  
  // _triggerThreshold: 揮拍的力道門檻值 (單位：G 重力加速度)。
  // 數字越大代表要揮得越用力才會觸發。
  double _triggerThreshold = 2.0; 
  
  // --- 內部緩衝區 (Internal Buffer) ---
  // 使用 ListQueue (佇列) 來當作暫存區，因為它的「先進先出」(FIFO) 效率很高。
  // 可以把它想像成一條輸送帶，舊資料從一頭掉出去，新資料從另一頭放進來。
  final ListQueue<IMUFrame> _buffer = ListQueue<IMUFrame>();
  
  // --- 狀態變數 (State) ---
  // 冷卻時間控制：避免一次揮拍判定成兩次。
  bool _isCoolingDown = false; // 是否在冷卻中
  DateTime? _lastTriggerTime;  // 上次觸發的時間
  final Duration _coolDownDuration = const Duration(seconds: 1); // 冷卻時間設為 1 秒

  // --- 動態設定函式 (Setters) ---
  // 讓外部 (例如設定頁面) 可以隨時更改參數

  // 設定觸發門檻值
  void setThreshold(double value) {
    _triggerThreshold = value;
  }
  
  // 設定視窗大小
  void setWindowConfig(int size, int preTrigger) {
    _windowSize = size;
    _preTriggerFrames = preTrigger;
  }

  /// 加入一筆新資料，並檢查是否觸發揮拍事件
  /// 回傳值：如果在揮拍中，回傳整段揮拍資料 (List<IMUFrame>)，否則回傳 null
  List<IMUFrame>? addFrame(IMUFrame frame) {
    // 1. 將新資料加入緩衝區
    _buffer.add(frame);
    
    // 保持緩衝區大小
    // 我們需要保留的歷史資料量至少要等於視窗大小 (_windowSize)
    // 這裡保留 2 倍是為了安全起見，確保資料夠用
    if (_buffer.length > _windowSize * 2) {
      _buffer.removeFirst(); // 移除最舊的一筆資料 (因為輸送帶滿了)
    }

    // 2. 檢查是否在冷卻時間內
    // 如果剛揮完拍，還在喘氣 (冷卻)，就不偵測新的揮拍
    if (_isCoolingDown) {
      // 檢查是不是已經過了一秒
      if (DateTime.now().difference(_lastTriggerTime!) > _coolDownDuration) {
        _isCoolingDown = false; // 冷卻結束，可以再揮了
      }
      return null;
    }

    // 3. 檢查觸發條件
    // 計算加速度的「合力大小」(Magnitude)
    // 公式：sqrt(x^2 + y^2 + z^2)
    // 這裡包含了重力，但只要揮拍夠大力，數值會遠大於 1G (重力)
    double mag = sqrt(pow(frame.acc[0], 2) + pow(frame.acc[1], 2) + pow(frame.acc[2], 2));
    
    // 如果 合力大小 超過 門檻值 且 緩衝區資料夠多 (至少累積到視窗大小)
    if (mag > _triggerThreshold && _buffer.length >= _windowSize) {
      // 觸發了！ (TRIGGERED!)
      return _extractWindow();
    }
    
    return null; // 沒事發生
  }

  // 取出揮拍資料視窗
  List<IMUFrame> _extractWindow() {
    _isCoolingDown = true; // 進入冷卻狀態
    _lastTriggerTime = DateTime.now(); // 記下現在時間

    // 邏輯說明：
    // 目前的策略是：當加速度超過門檻 (通常是擊球瞬間或最大發力點)，
    // 我們就擷取「過去這一段時間」的資料送去分析。
    
    // 理想狀況是：取「擊球前」+「擊球後」的資料。
    // 但因為我們要是「即時」的，所以沒辦法拿到「未來」(擊球後) 的資料，
    // 除非我們故意延遲送出。
    
    // 簡單版策略 (V3.0)：
    // 假設觸發點是動作的後半段，我們直接取出緩衝區中「最後的 N 筆」資料。
    // 這就包含了「導致這次觸發的前因後果 (歷史資料)」。
    
    List<IMUFrame> all = _buffer.toList(); // 把 Queue 轉成 List 方便切割
    int count = all.length;
    
    // 防呆：雖然前面有檢查，但還是確認一下資料夠不夠切
    if (count < _windowSize) {
      return all; 
    }
    
    // 擷取最後 _windowSize 筆資料 (例如最後 40 筆)
    // sublist(start, end)
    return all.sublist(count - _windowSize, count);
  }
  
  // 清除緩衝區 (通常在斷線或重置時呼叫)
  void clear() {
    _buffer.clear();
    _isCoolingDown = false;
  }
}
