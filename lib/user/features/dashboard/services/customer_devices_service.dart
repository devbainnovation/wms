import 'package:wms/core/api/api.dart';

class CustomerDeviceComponent {
  const CustomerDeviceComponent({
    required this.componentId,
    required this.displayName,
    required this.type,
  });

  final String componentId;
  final String displayName;
  final String type;
}

class CustomerDeviceSummary {
  const CustomerDeviceSummary({
    required this.espId,
    required this.macAddress,
    required this.displayName,
    required this.fwVersion,
    required this.lastHeartbeat,
    required this.amcExpiry,
    required this.rechargeExpiry,
    required this.createdAt,
    required this.components,
    required this.componentDetails,
    required this.isActive,
    required this.isOnline,
  });

  final String espId;
  final String macAddress;
  final String displayName;
  final String fwVersion;
  final String lastHeartbeat;
  final String amcExpiry;
  final String rechargeExpiry;
  final String createdAt;
  final List<String> components;
  final List<CustomerDeviceComponent> componentDetails;
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

    String readFromMap(Map<String, dynamic> map, List<String> keys) {
      for (final key in keys) {
        final raw = map[key];
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

    List<CustomerDeviceComponent> readComponents() {
      final raw = json['components'];
      if (raw is! List) {
        return const <CustomerDeviceComponent>[];
      }
      return raw
          .map<CustomerDeviceComponent?>((item) {
            if (item is Map<String, dynamic>) {
              final name = readFromMap(item, const [
                'displayName',
                'name',
                'componentName',
              ]);
              final id = readFromMap(item, const [
                'componentId',
                'compId',
                'id',
              ]);
              final resolvedName = name.isNotEmpty ? name : id;
              if (resolvedName.isEmpty) {
                return null;
              }
              return CustomerDeviceComponent(
                componentId: id,
                displayName: resolvedName,
                type: readFromMap(item, const ['type']),
              );
            }
            final text = item.toString().trim();
            if (text.isEmpty) {
              return null;
            }
            return CustomerDeviceComponent(
              componentId: '',
              displayName: text,
              type: '',
            );
          })
          .whereType<CustomerDeviceComponent>()
          .toList();
    }

    final componentDetails = readComponents();

    return CustomerDeviceSummary(
      espId: read(const ['espId', 'id', 'deviceId']),
      macAddress: read(const ['macAddress']),
      displayName: read(const ['displayName', 'name', 'espId']),
      fwVersion: read(const ['fwVersion']),
      lastHeartbeat: read(const ['lastHeartbeat']),
      amcExpiry: read(const ['amcExpiry']),
      rechargeExpiry: read(const ['rechargeExpiry']),
      createdAt: read(const ['createdAt']),
      components: componentDetails
          .map((item) => item.displayName)
          .where((value) => value.trim().isNotEmpty)
          .toList(),
      componentDetails: componentDetails,
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

  Future<ApiResponse> triggerManualAction({
    required String bearerToken,
    required String componentId,
    required String action,
  }) async {
    final normalizedComponentId = componentId.trim();
    if (normalizedComponentId.isEmpty) {
      throw const ApiException('Component ID is missing.');
    }

    final normalizedAction = action.trim().toUpperCase();
    if (normalizedAction != 'ON' && normalizedAction != 'OFF') {
      throw const ApiException('Action must be ON or OFF.');
    }

    final response = await _apiClient.post(
      ApiEndpoints.customerManualTriggers,
      bearerToken: bearerToken,
      queryParameters: <String, dynamic>{
        'componentId': normalizedComponentId,
        'action': normalizedAction,
      },
    );

    if (!response.isSuccess) {
      throw ApiException(
        _extractMessage(response.data) ?? 'Unable to trigger manual action.',
        statusCode: response.statusCode,
      );
    }

    return response;
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
