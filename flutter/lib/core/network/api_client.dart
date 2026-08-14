import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/environment.dart';
import '../storage/secure_storage_service.dart';

final dioProvider = Provider<Dio>((ref) {
  final storage = ref.watch(secureStorageProvider);

  final dio = Dio(
    BaseOptions(
      baseUrl: Environment.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await storage.readAccessToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode != 401 ||
            error.requestOptions.path.contains('/auth/refresh')) {
          return handler.next(error);
        }

        final refreshToken = await storage.readRefreshToken();
        if (refreshToken == null) {
          return handler.next(error);
        }

        try {
          final refreshDio = Dio(BaseOptions(baseUrl: Environment.apiBaseUrl));
          final response = await refreshDio.post(
            '/auth/refresh',
            data: {'refreshToken': refreshToken},
          );

          final newAccess = response.data['accessToken'] as String?;
          final newRefresh = response.data['refreshToken'] as String?;

          if (newAccess == null || newRefresh == null) {
            return handler.next(error);
          }

          await storage.saveTokens(
            accessToken: newAccess,
            refreshToken: newRefresh,
          );

          final request = error.requestOptions;
          request.headers['Authorization'] = 'Bearer $newAccess';

          final retryResponse = await dio.fetch(request);
          handler.resolve(retryResponse);
        } catch (_) {
          await storage.clearTokens();
          handler.next(error);
        }
      },
    ),
  );

  return dio;
});
