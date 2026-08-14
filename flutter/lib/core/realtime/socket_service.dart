// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:socket_io_client/socket_io_client.dart' as io;
//
// import '../config/environment.dart';
// import '../storage/secure_storage_service.dart';
//
// final socketServiceProvider = Provider<SocketService>((ref) {
//   final service = SocketService(ref.watch(secureStorageProvider));
//   ref.onDispose(service.dispose);
//   return service;
// });
//
// class SocketService {
//   SocketService(this._storage);
//
//   final SecureStorageService _storage;
//   io.Socket? _socket;
//
//   Future<void> connect() async {
//     final token = await _storage.readAccessToken();
//
//     _socket ??= io.io(
//       Environment.socketUrl,
//       io.OptionBuilder()
//           .setTransports(['websocket'])
//           .disableAutoConnect()
//           .setAuth({'token': token})
//           .build(),
//     );
//
//     if (!(_socket?.connected ?? false)) {
//       _socket?.connect();
//     }
//   }
//
//   void onPackageStatus(void Function(Map<String, dynamic>) listener) {
//     _socket?.off('package.status.updated');
//     _socket?.on('package.status.updated', (data) {
//       if (data is Map) {
//         listener(Map<String, dynamic>.from(data));
//       }
//     });
//   }
//
//   void dispose() {
//     _socket?.dispose();
//     _socket = null;
//   }
// }



import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../config/environment.dart';
import '../storage/secure_storage_service.dart';

final socketServiceProvider = Provider<SocketService>((ref) {
  final service = SocketService(
    ref.watch(secureStorageProvider),
  );

  ref.onDispose(service.dispose);

  return service;
});

class SocketService {
  SocketService(this._storage);

  final SecureStorageService _storage;

  io.Socket? _socket;

  final _packageStatusController =
  StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get packageStatusStream =>
      _packageStatusController.stream;

  bool get isConnected => _socket?.connected ?? false;

  Future<void> connect() async {
    final token = await _storage.readAccessToken();

    if (token == null || token.isEmpty) {
      print('SOCKET: No access token available');
      return;
    }

    // If already connected, do nothing.
    if (_socket?.connected == true) {
      print('SOCKET: Already connected');
      return;
    }

    // Dispose any old socket before creating a new one.
    _socket?.dispose();

    _socket = io.io(
      Environment.socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .disableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(10)
          .setReconnectionDelay(1000)
          .setAuth({
        'token': token,
      })
          .build(),
    );

    _socket!.onConnect((_) {
      print('SOCKET: CONNECTED');
      print('SOCKET ID: ${_socket?.id}');
    });

    _socket!.onDisconnect((reason) {
      print('SOCKET: DISCONNECTED -> $reason');
    });

    _socket!.onConnectError((error) {
      print('SOCKET CONNECT ERROR: $error');
    });

    _socket!.onError((error) {
      print('SOCKET ERROR: $error');
    });

    _socket!.on(
      'package.status.updated',
          (data) {
        print('SOCKET PACKAGE UPDATE: $data');

        if (data is Map) {
          _packageStatusController.add(
            Map<String, dynamic>.from(data),
          );
        }
      },
    );

    _socket!.connect();
  }

  void onPackageStatus(
      void Function(Map<String, dynamic>) listener,
      ) {
    packageStatusStream.listen(listener);
  }

  void dispose() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;

    _packageStatusController.close();
  }
}