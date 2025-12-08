import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import '../models/imu_frame.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  String? _currentUrl;
  
  // Stream for listening to server messages
  Stream<dynamic>? get stream => _channel?.stream;

  /// Connect to the WebSocket Server
  Future<void> connect(String url) async {
    // If already connected to the same URL, do nothing
    if (_channel != null && _currentUrl == url) return;

    disconnect();
    
    _currentUrl = url;
    try {
      final uri = Uri.parse(url);
      _channel = WebSocketChannel.connect(uri);
      print("WS: Connecting to $url");
    } catch (e) {
      print("WS: Connection Error: $e");
      rethrow;
    }
  }

  /// Send the Window Data (JSON) to Server
  void sendWindow(String clientId, List<IMUFrame> frames) {
    if (_channel == null) return;
    
    // Prepare JSON payload
    // Structure matches server/main.py expectations
    final payload = {
      "client_id": clientId,
      "data": frames.map((f) => f.toJson()).toList(),
    };
    
    try {
      final jsonStr = jsonEncode(payload);
      _channel!.sink.add(jsonStr);
      print("WS: Sent ${frames.length} frames");
    } catch (e) {
      print("WS: Send Error: $e");
    }
  }

  void disconnect() {
    if (_channel != null) {
      _channel!.sink.close(status.goingAway);
      _channel = null;
      print("WS: Disconnected");
    }
  }
}
