import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityService(Connectivity());
});

class ConnectivityService {
  ConnectivityService(this._connectivity);
  final Connectivity _connectivity;

  Stream<bool> get onlineStream => _connectivity.onConnectivityChanged.map(
        (results) => !results.contains(ConnectivityResult.none),
      );

  Future<bool> get isOnline async {
    final result = await _connectivity.checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }
}
