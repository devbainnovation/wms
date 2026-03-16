import 'dart:async';
import 'dart:developer' as developer;
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:wms/core/api/api_config.dart';
import 'package:wms/core/api/api_exception.dart';
import 'package:wms/core/api/api_response.dart';

class ApiClient {
  ApiClient({http.Client? client, this.baseUrl = ApiConfig.baseUrl})
    : _client = client ?? http.Client(),
      _ownsClient = client == null;

  static final ValueNotifier<int> inFlightRequestCount = ValueNotifier<int>(0);
  static final ValueNotifier<int> unauthorizedEventCount = ValueNotifier<int>(
    0,
  );
  static int _unauthorizedSuppressionDepth = 0;

  final String baseUrl;
  final http.Client _client;
  final bool _ownsClient;

  Future<ApiResponse> get(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    String? bearerToken,
    bool showGlobalLoader = true,
    bool reportUnauthorized = true,
  }) {
    return _request(
      method: 'GET',
      endpoint: endpoint,
      queryParameters: queryParameters,
      headers: headers,
      bearerToken: bearerToken,
      showGlobalLoader: showGlobalLoader,
      reportUnauthorized: reportUnauthorized,
    );
  }

  Future<ApiResponse> post(
    String endpoint, {
    Object? body,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    String? bearerToken,
    bool showGlobalLoader = true,
    bool reportUnauthorized = true,
  }) {
    return _request(
      method: 'POST',
      endpoint: endpoint,
      body: body,
      queryParameters: queryParameters,
      headers: headers,
      bearerToken: bearerToken,
      showGlobalLoader: showGlobalLoader,
      reportUnauthorized: reportUnauthorized,
    );
  }

  Future<ApiResponse> put(
    String endpoint, {
    Object? body,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    String? bearerToken,
    bool showGlobalLoader = true,
    bool reportUnauthorized = true,
  }) {
    return _request(
      method: 'PUT',
      endpoint: endpoint,
      body: body,
      queryParameters: queryParameters,
      headers: headers,
      bearerToken: bearerToken,
      showGlobalLoader: showGlobalLoader,
      reportUnauthorized: reportUnauthorized,
    );
  }

  Future<ApiResponse> delete(
    String endpoint, {
    Object? body,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    String? bearerToken,
    bool showGlobalLoader = true,
    bool reportUnauthorized = true,
  }) {
    return _request(
      method: 'DELETE',
      endpoint: endpoint,
      body: body,
      queryParameters: queryParameters,
      headers: headers,
      bearerToken: bearerToken,
      showGlobalLoader: showGlobalLoader,
      reportUnauthorized: reportUnauthorized,
    );
  }

  void dispose() {
    if (_ownsClient) {
      _client.close();
    }
  }

  Future<ApiResponse> _request({
    required String method,
    required String endpoint,
    Object? body,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    String? bearerToken,
    required bool showGlobalLoader,
    required bool reportUnauthorized,
  }) async {
    final uri = _buildUri(endpoint, queryParameters);
    final request = http.Request(method, uri);
    if (showGlobalLoader) {
      _incLoading();
    }

    final mergedHeaders = <String, String>{
      'Accept': 'application/json',
      ...?headers,
    };

    if (body != null) {
      mergedHeaders.putIfAbsent('Content-Type', () => 'application/json');
      request.body = body is String ? body : jsonEncode(body);
    }

    final authToken = (bearerToken ?? '').trim();
    if (authToken.isNotEmpty) {
      mergedHeaders['Authorization'] = 'Bearer $authToken';
    }

    request.headers.addAll(mergedHeaders);
    _logRequest(
      method: method,
      uri: uri,
      headers: mergedHeaders,
      body: request.body,
    );

    try {
      final streamed = await _client
          .send(request)
          .timeout(ApiConfig.requestTimeout);
      final response = await http.Response.fromStream(streamed);
      final decodedBody = _decodeBody(response.body);

      _logResponse(
        method: method,
        uri: uri,
        statusCode: response.statusCode,
        headers: response.headers,
        body: decodedBody,
      );

      if (reportUnauthorized && response.statusCode == 401) {
        _notifyUnauthorized();
      }

      return ApiResponse(
        statusCode: response.statusCode,
        data: decodedBody,
        headers: response.headers,
      );
    } on TimeoutException {
      _logError(method: method, uri: uri, message: 'Request timed out.');
      throw const ApiException('Request timed out. Please try again.');
    } catch (error) {
      _logError(method: method, uri: uri, message: error.toString());
      throw ApiException('Network error: $error');
    } finally {
      if (showGlobalLoader) {
        _decLoading();
      }
    }
  }

  Uri _buildUri(String endpoint, Map<String, dynamic>? queryParameters) {
    final normalizedEndpoint = endpoint.startsWith('/')
        ? endpoint
        : '/$endpoint';
    final uri = Uri.parse('$baseUrl$normalizedEndpoint');

    if (queryParameters == null || queryParameters.isEmpty) {
      return uri;
    }

    final converted = <String, String>{
      for (final entry in queryParameters.entries)
        if (entry.value != null) entry.key: entry.value.toString(),
    };

    return uri.replace(queryParameters: converted);
  }

  dynamic _decodeBody(String rawBody) {
    if (rawBody.trim().isEmpty) {
      return null;
    }

    try {
      return jsonDecode(rawBody);
    } catch (_) {
      return rawBody;
    }
  }

  void _logRequest({
    required String method,
    required Uri uri,
    required Map<String, String> headers,
    required String body,
  }) {
    if (kReleaseMode) {
      return;
    }

    final safeHeaders = Map<String, String>.from(headers);
    final authHeader = safeHeaders['Authorization'];
    if (authHeader != null && authHeader.isNotEmpty) {
      safeHeaders['Authorization'] = 'Bearer ***';
    }

    _debugLog('API REQUEST [$method] $uri');
    _debugLog('Headers: ${_pretty(safeHeaders)}');
    _debugLog('Body: ${body.isEmpty ? '<empty>' : _pretty(body)}');
  }

  void _logResponse({
    required String method,
    required Uri uri,
    required int statusCode,
    required Map<String, String> headers,
    required dynamic body,
  }) {
    if (kReleaseMode) {
      return;
    }

    _debugLog('API RESPONSE [$method] $uri -> $statusCode');
    _debugLog('Headers: ${_pretty(headers)}');
    _debugLog('Body: ${body == null ? '<empty>' : _pretty(body)}');
  }

  void _logError({
    required String method,
    required Uri uri,
    required String message,
  }) {
    if (kReleaseMode) {
      return;
    }
    _debugLog('API ERROR [$method] $uri -> $message');
  }

  String _pretty(Object value) {
    try {
      if (value is String) {
        final decoded = jsonDecode(value);
        return const JsonEncoder.withIndent('  ').convert(decoded);
      }
      return const JsonEncoder.withIndent('  ').convert(value);
    } catch (_) {
      return value.toString();
    }
  }

  void _debugLog(String message) {
    if (message.length <= 900) {
      debugPrint('WMS.API $message');
      developer.log(message, name: 'WMS.API');
      return;
    }

    const chunkSize = 900;
    for (var i = 0; i < message.length; i += chunkSize) {
      final end = (i + chunkSize < message.length)
          ? i + chunkSize
          : message.length;
      final chunk = message.substring(i, end);
      debugPrint('WMS.API $chunk');
      developer.log(chunk, name: 'WMS.API');
    }
  }

  void _incLoading() {
    inFlightRequestCount.value = inFlightRequestCount.value + 1;
  }

  void _decLoading() {
    final next = inFlightRequestCount.value - 1;
    inFlightRequestCount.value = next < 0 ? 0 : next;
  }

  void _notifyUnauthorized() {
    if (_unauthorizedSuppressionDepth > 0) {
      return;
    }
    unauthorizedEventCount.value = unauthorizedEventCount.value + 1;
  }

  static void beginUnauthorizedSuppression() {
    _unauthorizedSuppressionDepth = _unauthorizedSuppressionDepth + 1;
  }

  static void endUnauthorizedSuppression() {
    final next = _unauthorizedSuppressionDepth - 1;
    _unauthorizedSuppressionDepth = next < 0 ? 0 : next;
  }
}
