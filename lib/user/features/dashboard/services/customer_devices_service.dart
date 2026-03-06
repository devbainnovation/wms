import 'package:wms/core/api/api.dart';

class CustomerDeviceSummary {
  const CustomerDeviceSummary({
    required this.espId,
    required this.macAddress,
    required this.displayName,
    required this.fwVersion,
    required this.lastHeartbeat,
    required this.createdAt,
    required this.isActive,
    required this.isOnline,
  });

  final String espId;
  final String macAddress;
  final String displayName;
  final String fwVersion;
  final String lastHeartbeat;
  final String createdAt;
  final bool isActive;
  final bool isOnline;

  factory CustomerDeviceSummary.fromJson(Map<String, dynamic> json) {
    String read(List<String> keys) {
      for (final key in keys) {
        final raw = json[key];
        if (raw == null) {
          continue;
        }
        final value = raw.toString().trim();
        if (value.isNotEmpty && value.toLowerCase() != 'null') {
          return value;
        }
      }
      return '';
    }

    bool readBool(List<String> keys) {
      for (final key in keys) {
        final value = json[key];
        if (value is bool) {
          return value;
        }
        if (value is String) {
          final normalized = value.trim().toLowerCase();
          if (normalized == 'true') {
            return true;
          }
          if (normalized == 'false') {
            return false;
          }
        }
      }
      return false;
    }

    return CustomerDeviceSummary(
      espId: read(const ['espId', 'id', 'deviceId']),
      macAddress: read(const ['macAddress']),
      displayName: read(const ['displayName', 'name', 'espId']),
      fwVersion: read(const ['fwVersion']),
      lastHeartbeat: read(const ['lastHeartbeat']),
      createdAt: read(const ['createdAt']),
      isActive: readBool(const ['active', 'isActive']),
      isOnline: readBool(const ['online', 'isOnline']),
    );
  }
}

class CustomerDevicesService {
  CustomerDevicesService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<CustomerDeviceSummary>> getDevices({
    required String bearerToken,
  }) async {
    final response = await _apiClient.get(
      ApiEndpoints.customerDevices,
      bearerToken: bearerToken,
      showGlobalLoader: false,
    );

    if (!response.isSuccess) {
      throw ApiException(
        _extractMessage(response.data) ?? 'Unable to fetch devices.',
        statusCode: response.statusCode,
      );
    }

    final data = response.data;
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(CustomerDeviceSummary.fromJson)
          .toList();
    }

    if (data is Map<String, dynamic>) {
      final content = data['content'] ?? data['items'] ?? data['data'];
      if (content is List) {
        return content
            .whereType<Map<String, dynamic>>()
            .map(CustomerDeviceSummary.fromJson)
            .toList();
      }
    }

    return const <CustomerDeviceSummary>[];
  }

  String? _extractMessage(dynamic body) {
    if (body is! Map<String, dynamic>) {
      return null;
    }
    final rawMessage =
        body['message'] ??
        body['error'] ??
        body['detail'] ??
        body['errorMessage'];
    if (rawMessage == null) {
      return null;
    }
    final message = rawMessage.toString().trim();
    return message.isEmpty ? null : message;
  }
}
