import 'dart:convert';

import 'package:wms/core/api/api.dart';
import 'package:wms/core/auth/models/auth_models.dart';

class AuthApiService {
  AuthApiService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<AuthSession> login({
    required String username,
    required String password,
    String? deviceInfo,
    String? fcmToken,
  }) async {
    try {
      final payload = <String, dynamic>{
        'username': username,
        'password': password,
        'deviceInfo': 'string',
      };

      final response = await _apiClient.post(
        ApiEndpoints.authLogin,
        body: payload,
        showGlobalLoader: false,
      );

      if (response.statusCode == 200) {
        final body = response.dataAsMap;
        if (body == null) {
          throw const AuthApiException('Invalid login response from server.');
        }
        final session = AuthSession.fromJson(body);
        if (!session.isValid) {
          throw const AuthApiException('Invalid login response from server.');
        }
        return session;
      }

      if (response.statusCode == 401) {
        throw const AuthApiException(
          'Invalid username or password.',
          statusCode: 401,
        );
      }

      throw AuthApiException(
        _extractErrorMessage(response.data),
        statusCode: response.statusCode,
      );
    } catch (error) {
      if (error is ApiException) {
        throw AuthApiException(error.message, statusCode: error.statusCode);
      }
      if (error is AuthApiException) {
        rethrow;
      }
      throw AuthApiException('Login failed: $error');
    }
  }

  Future<void> logout(String sessionId) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.authLogout(sessionId),
        reportUnauthorized: false,
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return;
      }

      throw AuthApiException(
        _extractErrorMessage(response.data),
        statusCode: response.statusCode,
      );
    } catch (error) {
      if (error is ApiException) {
        throw AuthApiException(error.message, statusCode: error.statusCode);
      }
      if (error is AuthApiException) {
        rethrow;
      }
      throw AuthApiException('Logout failed: $error');
    }
  }

  String _extractErrorMessage(dynamic body) {
    if (body == null) {
      return 'Login failed. Please try again.';
    }

    if (body is Map<String, dynamic>) {
      final message = body['message'] ?? body['error'] ?? body['detail'];
      if (message != null && message.toString().trim().isNotEmpty) {
        return message.toString();
      }
      return 'Login failed. Please try again.';
    }

    if (body is String) {
      if (body.trim().isEmpty) {
        return 'Login failed. Please try again.';
      }
      final rawBody = body;
      try {
        final decoded = jsonDecode(rawBody);
        if (decoded is Map<String, dynamic>) {
          final message =
              decoded['message'] ?? decoded['error'] ?? decoded['detail'];
          if (message != null && message.toString().trim().isNotEmpty) {
            return message.toString();
          }
        }
      } catch (_) {
        // Keep fallback below for non-JSON error bodies.
      }
    }

    try {
      final decoded = jsonDecode(body.toString());
      if (decoded is Map<String, dynamic>) {
        final message =
            decoded['message'] ?? decoded['error'] ?? decoded['detail'];
        if (message != null && message.toString().trim().isNotEmpty) {
          return message.toString();
        }
      }
    } catch (_) {
      // Keep fallback below for non-JSON error bodies.
    }

    return 'Login failed. Please try again.';
  }
}
