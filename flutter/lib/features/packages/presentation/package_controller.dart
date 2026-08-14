// // import 'package:flutter_riverpod/flutter_riverpod.dart';
// //
// // import '../../../core/realtime/socket_service.dart';
// // import '../data/package_repository.dart';
// // import '../domain/task_package.dart';
// //
// // final packagesProvider =
// //     AsyncNotifierProvider<PackagesController, List<TaskPackage>>(
// //   PackagesController.new,
// // );
// //
// // class PackagesController extends AsyncNotifier<List<TaskPackage>> {
// //   @override
// //   Future<List<TaskPackage>> build() async {
// //     await ref.read(socketServiceProvider).connect();
// //
// //     ref.read(socketServiceProvider).onPackageStatus((event) {
// //       final id = event['packageId']?.toString();
// //       final rawStatus = event['status']?.toString();
// //
// //       if (id == null || rawStatus == null) return;
// //
// //       final nextStatus = PackageStatus.values.firstWhere(
// //         (e) => e.name == rawStatus,
// //         orElse: () => PackageStatus.processing,
// //       );
// //
// //       final current = state.valueOrNull ?? [];
// //       state = AsyncData(
// //         current
// //             .map((pkg) => pkg.id == id ? pkg.copyWith(status: nextStatus) : pkg)
// //             .toList(),
// //       );
// //     });
// //
// //     return ref.read(packageRepositoryProvider).getPackages();
// //   }
// //
// //   Future<void> refreshPackages() async {
// //     state = const AsyncLoading();
// //     state = await AsyncValue.guard(
// //       ref.read(packageRepositoryProvider).getPackages,
// //     );
// //   }
// //
// //   Future<String> create({
// //     required PackagePriority priority,
// //     required String notes,
// //     required List<PackageItem> items,
// //     double? latitude,
// //     double? longitude,
// //   }) async {
// //     final id = await ref.read(packageRepositoryProvider).createPackage(
// //           priority: priority,
// //           notes: notes,
// //           items: items,
// //           latitude: latitude,
// //           longitude: longitude,
// //         );
// //     await refreshPackages();
// //     return id;
// //   }
// // }
//
//
// import 'dart:async';
//
// import 'package:flutter_riverpod/flutter_riverpod.dart';
//
// import '../../../core/realtime/socket_service.dart';
// import '../data/package_repository.dart';
// import '../domain/task_package.dart';
//
// final packagesProvider =
// AsyncNotifierProvider<PackagesController, List<TaskPackage>>(
//   PackagesController.new,
// );
//
// class PackagesController extends AsyncNotifier<List<TaskPackage>> {
//   StreamSubscription<Map<String, dynamic>>? _socketSubscription;
//
//   @override
//   Future<List<TaskPackage>> build() async {
//     final socketService = ref.read(socketServiceProvider);
//
//     await socketService.connect();
//
//     await _socketSubscription?.cancel();
//
//     _socketSubscription =
//         socketService.packageStatusStream.listen(
//               (event) {
//             print('PACKAGES CONTROLLER EVENT: $event');
//
//             final packageId =
//             event['packageId']?.toString();
//
//             final statusValue =
//             event['status']?.toString();
//
//             if (packageId == null || statusValue == null) {
//               return;
//             }
//
//             final nextStatus =
//             PackageStatus.values.firstWhere(
//                   (status) => status.name == statusValue,
//               orElse: () => PackageStatus.processing,
//             );
//
//             final currentPackages =
//                 state.valueOrNull ?? [];
//
//             state = AsyncData(
//               currentPackages.map(
//                     (package) {
//                   if (package.id != packageId) {
//                     return package;
//                   }
//
//                   print(
//                     'PACKAGE $packageId STATUS '
//                         '${package.status.name} → ${nextStatus.name}',
//                   );
//
//                   return package.copyWith(
//                     status: nextStatus,
//                   );
//                 },
//               ).toList(),
//             );
//           },
//         );
//
//     ref.onDispose(() {
//       _socketSubscription?.cancel();
//     });
//
//     return ref
//         .read(packageRepositoryProvider)
//         .getPackages();
//   }
//
//   Future<void> refreshPackages() async {
//     try {
//       final packages = await ref
//           .read(packageRepositoryProvider)
//           .getPackages();
//
//       state = AsyncData(packages);
//     } catch (error, stackTrace) {
//       state = AsyncError(error, stackTrace);
//     }
//   }
//
//   Future<String> create({
//     required PackagePriority priority,
//     required String notes,
//     required List<PackageItem> items,
//     double? latitude,
//     double? longitude,
//   }) async {
//     final id =
//     await ref.read(packageRepositoryProvider).createPackage(
//       priority: priority,
//       notes: notes,
//       items: items,
//       latitude: latitude,
//       longitude: longitude,
//     );
//
//     await refreshPackages();
//
//     return id;
//   }
// }


import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/connectivity_service.dart';
import '../../../core/realtime/socket_service.dart';
import '../data/package_repository.dart';
import '../domain/task_package.dart';

final packagesProvider =
AsyncNotifierProvider<PackagesController, List<TaskPackage>>(
  PackagesController.new,
);

class PackagesController extends AsyncNotifier<List<TaskPackage>> {
  StreamSubscription<Map<String, dynamic>>? _socketSubscription;
  StreamSubscription<bool>? _connectivitySubscription;

  bool _isSynchronizing = false;

  @override
  Future<List<TaskPackage>> build() async {
    final socketService = ref.read(socketServiceProvider);
    final connectivityService =
    ref.read(connectivityServiceProvider);

    // -----------------------------------------------
    // SOCKET.IO REALTIME
    // -----------------------------------------------

    await socketService.connect();

    await _socketSubscription?.cancel();

    _socketSubscription =
        socketService.packageStatusStream.listen(
              (event) {
            print('PACKAGES CONTROLLER EVENT: $event');

            final packageId =
            event['packageId']?.toString();

            final statusValue =
            event['status']?.toString();

            if (packageId == null || statusValue == null) {
              return;
            }

            final nextStatus =
            PackageStatus.values.firstWhere(
                  (status) => status.name == statusValue,
              orElse: () => PackageStatus.processing,
            );

            final currentPackages =
                state.valueOrNull ?? [];

            state = AsyncData(
              currentPackages.map(
                    (package) {
                  if (package.id != packageId) {
                    return package;
                  }

                  print(
                    'PACKAGE $packageId STATUS '
                        '${package.status.name} → '
                        '${nextStatus.name}',
                  );

                  return package.copyWith(
                    status: nextStatus,
                  );
                },
              ).toList(),
            );
          },
        );

    // -----------------------------------------------
    // AUTOMATIC OFFLINE → ONLINE SYNCHRONIZATION
    // -----------------------------------------------

    await _connectivitySubscription?.cancel();

    _connectivitySubscription =
        connectivityService.onlineStream.listen(
              (isOnline) async {
            print(
              'CONNECTIVITY CHANGED: '
                  '${isOnline ? 'ONLINE' : 'OFFLINE'}',
            );

            if (!isOnline) {
              return;
            }

            await _synchronizeOfflineOperations();
          },
        );

    ref.onDispose(() {
      _socketSubscription?.cancel();
      _connectivitySubscription?.cancel();
    });

    // -----------------------------------------------
    // STARTUP RECOVERY
    // -----------------------------------------------
    //
    // Important:
    // If the application was killed while offline,
    // pending operations still exist in Drift.
    //
    // When the app starts again and internet is
    // available, attempt synchronization automatically.
    // -----------------------------------------------

    if (await connectivityService.isOnline) {
      try {
        final synchronized =
        await ref
            .read(packageRepositoryProvider)
            .syncPendingOperations();

        if (synchronized > 0) {
          print(
            'STARTUP SYNC: '
                '$synchronized operation(s) synchronized',
          );
        }
      } catch (error) {
        print(
          'STARTUP SYNC FAILED: $error',
        );
      }
    }

    // -----------------------------------------------
    // INITIAL PACKAGE LOAD
    // -----------------------------------------------

    return ref
        .read(packageRepositoryProvider)
        .getPackages();
  }

  // -------------------------------------------------
  // AUTO SYNC
  // -------------------------------------------------

  Future<void> _synchronizeOfflineOperations() async {
    // Prevent multiple connectivity events from
    // triggering concurrent synchronization attempts.
    if (_isSynchronizing) {
      print(
        'OFFLINE SYNC: already running',
      );
      return;
    }

    _isSynchronizing = true;

    try {
      print(
        'OFFLINE SYNC: starting',
      );

      final synchronized =
      await ref
          .read(packageRepositoryProvider)
          .syncPendingOperations();

      print(
        'OFFLINE SYNC: '
            '$synchronized operation(s) synchronized',
      );

      // Reload server data after synchronization.
      if (synchronized > 0) {
        await refreshPackages();
      }
    } catch (error) {
      print(
        'OFFLINE SYNC FAILED: $error',
      );
    } finally {
      _isSynchronizing = false;
    }
  }

  // -------------------------------------------------
  // MANUAL REFRESH
  // -------------------------------------------------

  Future<void> refreshPackages() async {
    try {
      final packages =
      await ref
          .read(packageRepositoryProvider)
          .getPackages();

      state = AsyncData(packages);
    } catch (error, stackTrace) {
      // Do not destroy existing dashboard data just
      // because the network disappeared.
      //
      // If packages are already displayed, retain them.
      if (state.valueOrNull != null) {
        print(
          'PACKAGE REFRESH FAILED: $error',
        );

        return;
      }

      state = AsyncError(
        error,
        stackTrace,
      );
    }
  }

  // -------------------------------------------------
  // CREATE PACKAGE
  // -------------------------------------------------

  Future<String> create({
    required PackagePriority priority,
    required String notes,
    required List<PackageItem> items,
    double? latitude,
    double? longitude,
  }) async {
    final repository =
    ref.read(packageRepositoryProvider);

    final connectivity =
    ref.read(connectivityServiceProvider);

    final isOnline =
    await connectivity.isOnline;

    final id = await repository.createPackage(
      priority: priority,
      notes: notes,
      items: items,
      latitude: latitude,
      longitude: longitude,
    );

    if (isOnline) {
      // Online package:
      // reload authoritative server data.
      await refreshPackages();
    } else {
      // Offline package:
      // show it immediately in UI as queued.
      final now = DateTime.now();

      final localPackage = TaskPackage(
        id: id,
        priority: priority,
        status: PackageStatus.queued,
        notes: notes,
        latitude: latitude,
        longitude: longitude,
        items: items,
        attachments: const [],
        createdAt: now,
        updatedAt: now,
      );

      final current =
          state.valueOrNull ?? [];

      state = AsyncData([
        localPackage,
        ...current,
      ]);

      print(
        'OFFLINE PACKAGE CREATED: $id',
      );
    }

    return id;
  }

  // -------------------------------------------------
  // MANUAL SYNC
  // -------------------------------------------------

  Future<int> synchronizeNow() async {
    if (_isSynchronizing) {
      return 0;
    }

    _isSynchronizing = true;

    try {
      final synchronized =
      await ref
          .read(packageRepositoryProvider)
          .syncPendingOperations();

      if (synchronized > 0) {
        await refreshPackages();
      }

      return synchronized;
    } finally {
      _isSynchronizing = false;
    }
  }
}