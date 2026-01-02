import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'api_service.dart';

class WebSocketService {
  static String get baseUrl => 'ws://${ApiService.serverIp}:8000';

  WebSocketChannel? _channel;
  int? _userId;

  Function(Map<String, dynamic>)? onMessageReceived;
  Function(int userId, String username, bool isOnline)? onStatusUpdate;
  Function()? onConnected;
  Function()? onDisconnected;

  bool get isConnected => _channel != null;

  void connect(int userId) {
    if (_channel != null) return;

    _userId = userId;

    try {
      final uri = Uri.parse('$baseUrl/ws/$userId');
      print('Connecting WebSocket: $uri');

      _channel = WebSocketChannel.connect(uri);

      _channel!.stream.listen(
        (data) => _handleIncomingMessage(data),
        onError: (error) {
          print('WebSocket error: $error');
          _handleDisconnect();
        },
        onDone: () {
          print('WebSocket closed');
          _handleDisconnect();
        },
      );

      onConnected?.call();
      _startPingTimer();
    } catch (e) {
      print('WebSocket connection failed: $e');
      _handleDisconnect();
    }
  }

  void _handleIncomingMessage(dynamic data) {
    try {
      final message = jsonDecode(data.toString()) as Map<String, dynamic>;
      final type = message['type'] as String?;

      switch (type) {
        case 'message':
          onMessageReceived?.call(message);
          break;

        case 'status':
          final userId = message['user_id'] as int?;
          final username = message['username'] as String?;
          final isOnline = message['is_online'] as bool?;

          if (userId != null && username != null && isOnline != null) {
            onStatusUpdate?.call(userId, username, isOnline);
          }
          break;

        case 'pong':
          // heartbeat response
          break;

        default:
          print('Unknown WS message: $type');
      }
    } catch (e) {
      print('WS parse error: $e');
    }
  }

  void _handleDisconnect() {
    _channel = null;
    _pingTimer?.cancel();
    _pingTimer = null;
    onDisconnected?.call();
  }

  void send(Map<String, dynamic> message) {
    if (_channel == null) return;

    try {
      _channel!.sink.add(jsonEncode(message));
    } catch (e) {
      print('WS send error: $e');
    }
  }

  Timer? _pingTimer;

  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_channel != null) {
        send({'type': 'ping'});
      } else {
        timer.cancel();
      }
    });
  }

  void disconnect() {
    _pingTimer?.cancel();
    _pingTimer = null;
    _channel?.sink.close();
    _channel = null;
    _userId = null;
  }

  void reconnect() {
    if (_userId != null) {
      disconnect();
      Future.delayed(const Duration(seconds: 1), () {
        connect(_userId!);
      });
    }
  }
}
