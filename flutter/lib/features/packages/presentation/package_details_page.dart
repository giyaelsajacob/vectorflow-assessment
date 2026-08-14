// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
//
// import '../data/package_repository.dart';
// import '../domain/task_package.dart';
//
// final packageDetailsProvider =
//     FutureProvider.family<TaskPackage, String>((ref, id) {
//   return ref.watch(packageRepositoryProvider).getPackage(id);
// });
//
// class PackageDetailsPage extends ConsumerWidget {
//   const PackageDetailsPage({super.key, required this.packageId});
//
//   final String packageId;
//
//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final details = ref.watch(packageDetailsProvider(packageId));
//
//     return Scaffold(
//       appBar: AppBar(title: const Text('Package details')),
//       body: details.when(
//         loading: () => const Center(child: CircularProgressIndicator()),
//         error: (error, _) => Center(
//           child: Padding(
//             padding: const EdgeInsets.all(24),
//             child: Text(
//               'Package may still be waiting for synchronization.\n\n$error',
//               textAlign: TextAlign.center,
//             ),
//           ),
//         ),
//         data: (pkg) => ListView(
//           padding: const EdgeInsets.all(16),
//           children: [
//             Text(pkg.id, style: Theme.of(context).textTheme.titleLarge),
//             const SizedBox(height: 8),
//             Chip(label: Text(pkg.priority.name.toUpperCase())),
//             const SizedBox(height: 16),
//             _StatusTimeline(status: pkg.status),
//             const Divider(height: 32),
//             Text('Items', style: Theme.of(context).textTheme.titleLarge),
//             ...pkg.items.map(
//               (item) => ListTile(
//                 contentPadding: EdgeInsets.zero,
//                 leading: const Icon(Icons.inventory_2_outlined),
//                 title: Text(item.name),
//                 subtitle: Text(item.description),
//                 trailing: Text('× ${item.quantity}'),
//               ),
//             ),
//             const Divider(height: 32),
//             Text('Notes', style: Theme.of(context).textTheme.titleLarge),
//             const SizedBox(height: 8),
//             Text(pkg.notes?.isNotEmpty == true ? pkg.notes! : 'No notes'),
//             const Divider(height: 32),
//             Text('Location', style: Theme.of(context).textTheme.titleLarge),
//             const SizedBox(height: 8),
//             Text(
//               pkg.latitude == null
//                   ? 'Not provided'
//                   : '${pkg.latitude}, ${pkg.longitude}',
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// class _StatusTimeline extends StatelessWidget {
//   const _StatusTimeline({required this.status});
//
//   final PackageStatus status;
//
//   @override
//   Widget build(BuildContext context) {
//     final steps = [
//       PackageStatus.submitted,
//       PackageStatus.processing,
//       PackageStatus.completed,
//     ];
//
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text('Processing status', style: Theme.of(context).textTheme.titleLarge),
//         const SizedBox(height: 12),
//         ...steps.map((step) {
//           final complete = status.index >= step.index;
//           return ListTile(
//             contentPadding: EdgeInsets.zero,
//             leading: Icon(
//               complete ? Icons.check_circle : Icons.radio_button_unchecked,
//             ),
//             title: Text(step.name.toUpperCase()),
//           );
//         }),
//       ],
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/package_repository.dart';
import '../domain/task_package.dart';
import 'package_controller.dart';

final packageDetailsProvider =
FutureProvider.family<TaskPackage, String>((ref, id) {
  return ref.watch(packageRepositoryProvider).getPackage(id);
});

class PackageDetailsPage extends ConsumerWidget {
  const PackageDetailsPage({
    super.key,
    required this.packageId,
  });

  final String packageId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final details = ref.watch(packageDetailsProvider(packageId));

    // Watch realtime package list.
    // Socket.IO updates packagesProvider inside PackagesController.
    final packagesState = ref.watch(packagesProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: () {
            context.go('/dashboard');
          },
        ),
        title: const Text('Package details'),
      ),
      body: details.when(
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
                  'Unable to load package.\n\n$error',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () {
                    ref.invalidate(
                      packageDetailsProvider(packageId),
                    );
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (serverPackage) {
          // Default to the package fetched from REST.
          TaskPackage packageToDisplay = serverPackage;

          // If Socket.IO has delivered a newer package status,
          // use that status immediately.
          final realtimePackages = packagesState.valueOrNull;

          if (realtimePackages != null) {
            for (final realtimePackage in realtimePackages) {
              if (realtimePackage.id == packageId) {
                packageToDisplay = serverPackage.copyWith(
                  status: realtimePackage.status,
                );
                break;
              }
            }
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(
                packageDetailsProvider(packageId),
              );

              await ref.read(
                packageDetailsProvider(packageId).future,
              );
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  packageToDisplay.id,
                  style: Theme.of(context).textTheme.titleLarge,
                ),

                const SizedBox(height: 8),

                Align(
                  alignment: Alignment.centerLeft,
                  child: Chip(
                    label: Text(
                      packageToDisplay.priority.name.toUpperCase(),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                _StatusTimeline(
                  status: packageToDisplay.status,
                ),

                const Divider(height: 32),

                Text(
                  'Items',
                  style: Theme.of(context).textTheme.titleLarge,
                ),

                if (packageToDisplay.items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text('No items added.'),
                  ),

                ...packageToDisplay.items.map(
                      (item) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.inventory_2_outlined,
                    ),
                    title: Text(item.name),
                    subtitle: item.description.isEmpty
                        ? null
                        : Text(item.description),
                    trailing: Text(
                      '× ${item.quantity}',
                    ),
                  ),
                ),

                const Divider(height: 32),

                Text(
                  'Notes',
                  style: Theme.of(context).textTheme.titleLarge,
                ),

                const SizedBox(height: 8),

                Text(
                  packageToDisplay.notes?.isNotEmpty == true
                      ? packageToDisplay.notes!
                      : 'No notes',
                ),

                const Divider(height: 32),

                Text(
                  'Location',
                  style: Theme.of(context).textTheme.titleLarge,
                ),

                const SizedBox(height: 8),

                Text(
                  packageToDisplay.latitude == null
                      ? 'Not provided'
                      : '${packageToDisplay.latitude}, '
                      '${packageToDisplay.longitude}',
                ),

                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatusTimeline extends StatelessWidget {
  const _StatusTimeline({
    required this.status,
  });

  final PackageStatus status;

  @override
  Widget build(BuildContext context) {
    final steps = [
      PackageStatus.submitted,
      PackageStatus.processing,
      PackageStatus.completed,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Processing status',
          style: Theme.of(context).textTheme.titleLarge,
        ),

        const SizedBox(height: 12),

        ...steps.map(
              (step) {
            final complete = status.index >= step.index;
            final current = status == step;

            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                complete
                    ? Icons.check_circle
                    : Icons.radio_button_unchecked,
              ),
              title: Text(
                step.name.toUpperCase(),
                style: TextStyle(
                  fontWeight:
                  current ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}