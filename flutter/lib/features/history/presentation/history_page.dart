import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../packages/presentation/package_controller.dart';

class HistoryPage extends ConsumerWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final packages = ref.watch(packagesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: packages.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
        data: (items) => ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (context, index) {
            final pkg = items[index];
            return ListTile(
              title: Text(pkg.id),
              subtitle: Text(
                '${pkg.status.name} • ${pkg.priority.name}',
              ),
              trailing: Text(
                '${pkg.createdAt.day}/${pkg.createdAt.month}/${pkg.createdAt.year}',
              ),
            );
          },
        ),
      ),
    );
  }
}
