import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/storage/secure_storage_service.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.watch(dioProvider),
    ref.watch(secureStorageProvider),
  );
});

class AuthRepository {
  AuthRepository(this._dio, this._storage);

  final Dio _dio;
  final SecureStorageService _storage;

  Future<void> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post(
      '/auth/login',
      data: {'email': email, 'password': password},
    );

    await _storage.saveTokens(
      accessToken: response.data['accessToken'] as String,
      refreshToken: response.data['refreshToken'] as String,
    );
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await _dio.post(
      '/auth/register',
      data: {'name': name, 'email': email, 'password': password},
    );

    await _storage.saveTokens(
      accessToken: response.data['accessToken'] as String,
      refreshToken: response.data['refreshToken'] as String,
    );
  }

  Future<bool> hasSession() async {
    final token = await _storage.readAccessToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> logout() => _storage.clearTokens();
}
