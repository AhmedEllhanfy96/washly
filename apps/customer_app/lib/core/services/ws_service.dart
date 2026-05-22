import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'api_client.dart';

final wsServiceProvider = Provider<WsService>((ref) => WsService());

class WsService {
  final _storage = const FlutterSecureStorage();
  WebSocketChannel? _channel;
  final _controller = StreamController<Map<String, dynamic>>.broadcast();
  bool _disposed = false;

  Stream<Map<String, dynamic>> get events => _controller.stream;

  Future<void> connect() async {
    if (_disposed) return;
    final token = await _storage.read(key: 'auth_token');
    final uri = Uri.parse('$wsUrl${token != null ? '?token=$token' : ''}');
    try {
      _channel = WebSocketChannel.connect(uri);
      await _channel!.ready.timeout(const Duration(seconds: 5));
      _channel!.stream.listen(
        (msg) {
          if (_disposed) return;
          try {
            final data = jsonDecode(msg as String) as Map<String, dynamic>;
            _controller.add(data);
          } catch (_) {}
        },
        onError: (_) => _reconnect(),
        onDone: () => _reconnect(),
      );
    } catch (_) {
      _reconnect();
    }
  }

  void _reconnect() {
    if (_disposed) return;
    Future.delayed(const Duration(seconds: 3), connect);
  }

  void disconnect() {
    _channel?.sink.close();
    _channel = null;
  }

  void dispose() {
    _disposed = true;
    disconnect();
    _controller.close();
  }
}
