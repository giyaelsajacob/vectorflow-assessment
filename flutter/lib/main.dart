// import 'package:flutter/widgets.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
//
// import 'app/app.dart';
// import 'app/bootstrap.dart';
//
// Future<void> main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await bootstrap();
//   runApp(const ProviderScope(child: VectorFlowApp()));
// }


import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/bootstrap.dart';
import 'core/network/connectivity_service.dart';
import 'features/offline/presentation/offline_queue_page.dart';
import 'features/packages/data/package_repository.dart';
import 'features/packages/presentation/package_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await bootstrap();

  runApp(
    const ProviderScope(
      child: AutoSyncRoot(),
    ),
  );
}

class AutoSyncRoot extends ConsumerStatefulWidget {
  const AutoSyncRoot({super.key});

  @override
  ConsumerState<AutoSyncRoot> createState() =>
      _AutoSyncRootState();
}

class _AutoSyncRootState extends ConsumerState<AutoSyncRoot> {
  StreamSubscription<bool>? _connectivitySubscription;

  bool _syncRunning = false;

  @override
  void initState() {
    super.initState();

    Future.microtask(_initializeAutoSync);
  }

  Future<void> _initializeAutoSync() async {
    final connectivity =
    ref.read(connectivityServiceProvider);

    // Listen globally for OFFLINE -> ONLINE changes.
    _connectivitySubscription =
        connectivity.onlineStream.distinct().listen(
              (isOnline) async {
            debugPrint(
              'GLOBAL CONNECTIVITY: '
                  '${isOnline ? 'ONLINE' : 'OFFLINE'}',
            );

            if (isOnline) {
              await _syncPendingOperations();
            }
          },
        );

    // Also recover pending work when the app is
    // reopened while internet is already available.
    final currentlyOnline =
    await connectivity.isOnline;

    if (currentlyOnline) {
      await _syncPendingOperations();
    }
  }

  Future<void> _syncPendingOperations() async {
    if (_syncRunning) {
      debugPrint(
        'GLOBAL AUTO SYNC: already running',
      );
      return;
    }

    _syncRunning = true;

    try {
      debugPrint(
        'GLOBAL AUTO SYNC: starting',
      );

      final count = await ref
          .read(packageRepositoryProvider)
          .syncPendingOperations();

      debugPrint(
        'GLOBAL AUTO SYNC: '
            '$count operation(s) synchronized',
      );

      // Refresh the offline queue immediately.
      ref.invalidate(offlineQueueProvider);

      // Refresh server packages after successful sync.
      if (count > 0) {
        try {
          await ref
              .read(packagesProvider.notifier)
              .refreshPackages();
        } catch (error) {
          debugPrint(
            'PACKAGE REFRESH AFTER SYNC FAILED: $error',
          );
        }
      }
    } catch (error) {
      debugPrint(
        'GLOBAL AUTO SYNC FAILED: $error',
      );
    } finally {
      _syncRunning = false;
    }
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const VectorFlowApp();
  }
}