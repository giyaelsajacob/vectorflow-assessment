import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/login_page.dart';
import '../features/auth/presentation/register_page.dart';
import '../features/history/presentation/history_page.dart';
import '../features/offline/presentation/offline_queue_page.dart';
import '../features/packages/presentation/create_package_page.dart';
import '../features/packages/presentation/dashboard_page.dart';
import '../features/packages/presentation/package_details_page.dart';
import '../features/profile/presentation/profile_page.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        builder: (_, __) => const RegisterPage(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (_, __) => const DashboardPage(),
      ),
      GoRoute(
        path: '/packages/create',
        builder: (_, __) => const CreatePackagePage(),
      ),
      GoRoute(
        path: '/packages/:id',
        builder: (_, state) => PackageDetailsPage(
          packageId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/offline',
        builder: (_, __) => const OfflineQueuePage(),
      ),
      GoRoute(
        path: '/history',
        builder: (_, __) => const HistoryPage(),
      ),
      GoRoute(
        path: '/profile',
        builder: (_, __) => const ProfilePage(),
      ),
    ],
  );
});
