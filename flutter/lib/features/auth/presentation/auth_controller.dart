import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_repository.dart';

final authControllerProvider =
    AsyncNotifierProvider<AuthController, bool>(AuthController.new);

class AuthController extends AsyncNotifier<bool> {
  @override
  Future<bool> build() {
    return ref.watch(authRepositoryProvider).hasSession();
  }

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(authRepositoryProvider).login(
            email: email,
            password: password,
          );
      return true;
    });
  }

  Future<void> register(String name, String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(authRepositoryProvider).register(
            name: name,
            email: email,
            password: password,
          );
      return true;
    });
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AsyncData(false);
  }
}
