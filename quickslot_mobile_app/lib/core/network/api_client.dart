import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/application/auth_notifier.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://quickslot-5yyo.onrender.com',
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final authState = ref.read(authNotifierProvider);
        if (authState.currentUserId != null) {
          options.headers['X-User-Id'] = authState.currentUserId;
        }
        return handler.next(options);
      },
    ),
  );

  // Add a simple logger interceptor to help debug API calls
  dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true));

  return dio;
});
