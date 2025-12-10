import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import '../models/imu_frame.dart';

class WebSocketService {
  WebSocketChannel? _channel; // WebSocket 連線通道
  String? _currentUrl;        // 目前連線的網址 (用來避免重複連線)
  
  // 監聽來自伺服器的訊息 (Stream)
  // 這是一個管子，伺服器丟訊息過來，我們這邊就會收到
  Stream<dynamic>? get stream => _channel?.stream;

  /// 連線到 WebSocket 伺服器
  Future<void> connect(String url) async {
    // 如果已經連線中，而且網址一樣，就不用重連了
    if (_channel != null && _currentUrl == url) return;

    disconnect(); // 先斷開舊的連線
    
    _currentUrl = url;
    try {
      final uri = Uri.parse(url); // 解析網址格式
      _channel = WebSocketChannel.connect(uri); // 建立連線
      print("WS: Connecting to $url");
    } catch (e) {
      print("WS: Connection Error: $e");
      rethrow; // 把錯誤往上丟，讓呼叫這段程式的人知道出錯了
    }
  }

  /// 傳送揮拍視窗資料 (List<IMUFrame>) 給伺服器
  void sendWindow(String clientId, List<IMUFrame> frames) {
    if (_channel == null) return; // 沒連線就不能傳
    
    // 準備要傳送的 JSON 資料
    // 這裡的格式必須跟 Python 伺服器端 (server/main.py) 規定的一樣
    final payload = {
      "client_id": clientId, // 告訴伺服器是誰傳的
      // 把 List<IMUFrame> 裡面的每一筆資料都轉成 JSON 格式
      "data": frames.map((f) => f.toJson()).toList(),
    };
    
    try {
      // 將資料轉成 JSON 字串 (String)
      final jsonStr = jsonEncode(payload);
      // 透過水管 (Sink) 丟給伺服器
      _channel!.sink.add(jsonStr);
      print("WS: Sent ${frames.length} frames");
    } catch (e) {
      print("WS: Send Error: $e");
    }
  }

  /// 斷開連線
  void disconnect() {
    if (_channel != null) {
      // 告訴伺服器我們要離開了 (goingAway 代表正常關閉)
      _channel!.sink.close(status.goingAway);
      _channel = null;
      print("WS: Disconnected");
    }
  }
}
