import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/presentation/auth_controller.dart';
import '../domain/task_package.dart';
import 'package_controller.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final packages = ref.watch(packagesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('VectorFlow'),
        actions: [
          IconButton(
            tooltip: 'Offline queue',
            onPressed: () => context.push('/offline'),
            icon: const Icon(Icons.cloud_off_outlined),
          ),
          IconButton(
            tooltip: 'History',
            onPressed: () => context.push('/history'),
            icon: const Icon(Icons.history),
          ),
          IconButton(
            tooltip: 'Profile',
            onPressed: () => context.push('/profile'),
            icon: const Icon(Icons.person_outline),
          ),
          IconButton(
            tooltip: 'Logout',
            onPressed: () async {
              await ref.read(authControllerProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/packages/create'),
        icon: const Icon(Icons.add),
        label: const Text('Create package'),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(packagesProvider.notifier).refreshPackages(),
        child: packages.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => ListView(
            children: [
              const SizedBox(height: 160),
              Icon(Icons.cloud_off, size: 56, color: Theme.of(context).hintColor),
              const SizedBox(height: 12),
              Text(
                'Backend unavailable\n$error',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Center(
                child: OutlinedButton(
                  onPressed: () =>
                      ref.read(packagesProvider.notifier).refreshPackages(),
                  child: const Text('Retry'),
                ),
              ),
            ],
          ),
          data: (items) {
            final processing = items
                .where((e) => e.status == PackageStatus.processing)
                .length;
            final completed = items
                .where((e) => e.status == PackageStatus.completed)
                .length;

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Dashboard',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _MetricCard(
                        label: 'Total',
                        value: items.length.toString(),
                        icon: Icons.inventory_2_outlined,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MetricCard(
                        label: 'Processing',
                        value: processing.toString(),
                        icon: Icons.sync,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MetricCard(
                        label: 'Completed',
                        value: completed.toString(),
                        icon: Icons.check_circle_outline,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Recent packages',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                if (items.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('No packages yet. Create your first one.'),
                    ),
                  ),
                ...items.take(10).map(
                      (pkg) => Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Text(pkg.priority.name[0].toUpperCase()),
                          ),
                          title: Text(pkg.id),
                          subtitle: Text(
                            '${pkg.priority.name.toUpperCase()} • ${pkg.status.name}',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => context.push('/packages/${pkg.id}'),
                        ),
                      ),
                    ),
                const SizedBox(height: 96),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Icon(icon),
            const SizedBox(height: 8),
            Text(value, style: Theme.of(context).textTheme.headlineSmall),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
