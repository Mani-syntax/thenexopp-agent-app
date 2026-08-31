import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../../core/constants/api_constants.dart';
import 'dio_provider.dart';
import 'auth_provider.dart';

class WebSocketService {
  io.Socket? _socket;
  final Ref _ref;

  WebSocketService(this._ref);

  Future<void> connect() async {
    final storage = _ref.read(secureStorageProvider);
    final token = await storage.getAccessToken();
    if (token == null) return;

    _socket = io.io(
      ApiConstants.webSocketUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .setAuth({'token': token})
          .build(),
    );

    _socket?.onConnect((_) {
      debugPrint('[Socket.io] Connected to server namespace /ws');
    });

    _socket?.on('agent.status.updated', (data) {
      if (data != null && data['status'] != null) {
        final status = data['status'];
        final reason = data['rejectionReason'];
        _ref.read(authProvider.notifier).updateAgentState(status, rejectionReason: reason);
      }
    });

    _socket?.on('kyc.status.updated', (data) {
      if (data != null && data['status'] == 'REJECTED') {
        _ref.read(authProvider.notifier).updateAgentState('REJECTED', rejectionReason: data['rejectionReason']);
      }
    });

    _socket?.onDisconnect((_) {
      debugPrint('[Socket.io] Disconnected from server');
    });
  }

  void disconnect() {
    _socket?.disconnect();
  }
}

final webSocketProvider = Provider<WebSocketService>((ref) {
  final service = WebSocketService(ref);
  ref.onDispose(() => service.disconnect());
  return service;
});
