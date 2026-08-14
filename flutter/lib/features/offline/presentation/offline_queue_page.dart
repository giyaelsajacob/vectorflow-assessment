// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
//
// import '../../../core/storage/app_database.dart';
// import '../../packages/data/package_repository.dart';
//
// final offlineQueueProvider = FutureProvider((ref) {
//   return ref.watch(databaseProvider).pendingOperations();
// });
//
// class OfflineQueuePage extends ConsumerWidget {
//   const OfflineQueuePage({super.key});
//
//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final queue = ref.watch(offlineQueueProvider);
//
//     return Scaffold(
//       appBar: AppBar(title: const Text('Offline queue')),
//       floatingActionButton: FloatingActionButton.extended(
//         onPressed: () async {
//           final synced =
//               await ref.read(packageRepositoryProvider).syncPendingOperations();
//           ref.invalidate(offlineQueueProvider);
//           if (context.mounted) {
//             ScaffoldMessenger.of(context).showSnackBar(
//               SnackBar(content: Text('$synced operation(s) synchronized.')),
//             );
//           }
//         },
//         icon: const Icon(Icons.sync),
//         label: const Text('Sync now'),
//       ),
//       body: queue.when(
//         loading: () => const Center(child: CircularProgressIndicator()),
//         error: (error, _) => Center(child: Text(error.toString())),
//         data: (items) => items.isEmpty
//             ? const Center(child: Text('Offline queue is empty.'))
//             : ListView.builder(
//                 padding: const EdgeInsets.all(16),
//                 itemCount: items.length,
//                 itemBuilder: (context, index) {
//                   final item = items[index];
//                   return Card(
//                     child: ListTile(
//                       leading: const Icon(Icons.cloud_off_outlined),
//                       title: Text(item.operation),
//                       subtitle: Text(
//                         '${item.entityId}\nRetry count: ${item.retryCount}',
//                       ),
//                       isThreeLine: true,
//                     ),
//                   );
//                 },
//               ),
//       ),
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/storage/app_database.dart';
import '../../packages/data/package_repository.dart';

final offlineQueueProvider = FutureProvider((ref) {
  return ref.watch(databaseProvider).pendingOperations();
});

class OfflineQueuePage extends ConsumerWidget {
  const OfflineQueuePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queue = ref.watch(offlineQueueProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/dashboard');
            }
          },
        ),
        title: const Text('Offline queue'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          try {
            final synced = await ref
                .read(packageRepositoryProvider)
                .syncPendingOperations();

            ref.invalidate(offlineQueueProvider);

            if (!context.mounted) return;

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '$synced operation(s) synchronized.',
                ),
              ),
            );
          } catch (error) {
            if (!context.mounted) return;

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Synchronization failed: $error',
                ),
              ),
            );
          }
        },
        icon: const Icon(Icons.sync),
        label: const Text('Sync now'),
      ),
      body: queue.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  'Unable to load offline queue.\n\n$error',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () {
                    ref.invalidate(offlineQueueProvider);
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(offlineQueueProvider);
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 180),
                  Icon(
                    Icons.cloud_done_outlined,
                    size: 64,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Offline queue is empty.',
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Pending operations will appear here when you work offline.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(offlineQueueProvider);
            },
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                16,
                16,
                16,
                100,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: Icon(
                        Icons.cloud_off_outlined,
                      ),
                    ),
                    title: Text(
                      item.operation.replaceAll('_', ' '),
                    ),
                    subtitle: Text(
                      'Entity: ${item.entityId}\n'
                          'Status: ${item.status}\n'
                          'Retry count: ${item.retryCount}',
                    ),
                    isThreeLine: false,
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}