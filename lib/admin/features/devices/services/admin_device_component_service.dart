import 'package:wms/core/api/api.dart';

enum AdminComponentType { valve, sensor, motor }

extension AdminComponentTypeX on AdminComponentType {
  String get apiValue {
    switch (this) {
      case AdminComponentType.valve:
        return 'VALVE';
      case AdminComponentType.sensor:
        return 'SENSOR';
      case AdminComponentType.motor:
        return 'MOTOR';
    }
  }

  String get label {
    switch (this) {
      case AdminComponentType.valve:
        return 'VALVE';
      case AdminComponentType.sensor:
        return 'SENSOR';
      case AdminComponentType.motor:
        return 'MOTOR';
    }
  }
}

AdminComponentType _parseComponentType(dynamic raw) {
  final value = raw?.toString().trim().toUpperCase() ?? '';
  switch (value) {
    case 'SENSOR':
      return AdminComponentType.sensor;
    case 'MOTOR':
      return AdminComponentType.motor;
    case 'VALVE':
    default:
      return AdminComponentType.valve;
  }
}

class AdminDeviceComponentRequest {
  const AdminDeviceComponentRequest({
    required this.type,
    required this.gpioPin,
    required this.name,
    required this.installedArea,
    required this.active,
  });

  final AdminComponentType type;
  final int gpioPin;
  final String name;
  final String installedArea;
  final bool active;

  Map<String, dynamic> toJson() {
    return {
      'type': type.apiValue,
      'gpioPin': gpioPin,
      'name': name,
      'installedArea': installedArea,
      'active': active,
    };
  }
}

class AdminDeviceComponent {
  const AdminDeviceComponent({
    required this.id,
    required this.type,
    required this.gpioPin,
    required this.name,
    required this.installedArea,
    required this.active,
  });

  final String id;
  final AdminComponentType type;
  final int gpioPin;
  final String name;
  final String installedArea;
  final bool active;

  factory AdminDeviceComponent.fromJson(Map<String, dynamic> json) {
    final id = (json['id'] ?? json['compId'] ?? json['componentId'] ?? '')
        .toString();
    final gpioPin = (json['gpioPin'] as num?)?.toInt() ?? 0;
    final name = (json['name'] ?? '').toString();
    final installedArea = (json['installedArea'] ?? '').toString();
    final active = (json['active'] ?? json['isActive'] ?? true) == true;
    final type = _parseComponentType(json['type']);

    return AdminDeviceComponent(
      id: id,
      type: type,
      gpioPin: gpioPin,
      name: name,
      installedArea: installedArea,
      active: active,
    );
  }
}

class AdminDeviceComponentService {
  AdminDeviceComponentService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<AdminDeviceComponent>> getComponents({
    required String bearerToken,
    required String deviceId,
  }) async {
    final response = await _apiClient.get(
      ApiEndpoints.adminDeviceComponents(deviceId),
      bearerToken: bearerToken,
    );

    if (!response.isSuccess) {
      throw ApiException(
        'Unable to fetch components.',
        statusCode: response.statusCode,
      );
    }

    final body = response.data;
    final rawList = switch (body) {
      List<dynamic>() => body,
      Map<String, dynamic>() =>
        body['content'] is List
            ? body['content'] as List<dynamic>
            : const <dynamic>[],
      _ => const <dynamic>[],
    };

    return rawList
        .whereType<Map<String, dynamic>>()
        .map(AdminDeviceComponent.fromJson)
        .toList();
  }

  Future<void> addComponent({
    required String bearerToken,
    required String deviceId,
    required AdminDeviceComponentRequest request,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.adminDeviceComponents(deviceId),
      bearerToken: bearerToken,
      body: request.toJson(),
    );
    _handleMutationResponse(response, 'Component creation failed.');
  }

  Future<void> updateComponent({
    required String bearerToken,
    required String deviceId,
    required String compId,
    required AdminDeviceComponentRequest request,
  }) async {
    final response = await _apiClient.put(
      ApiEndpoints.adminDeviceComponentById(deviceId, compId),
      bearerToken: bearerToken,
      body: request.toJson(),
    );
    _handleMutationResponse(response, 'Component update failed.');
  }

  Future<void> deleteComponent({
    required String bearerToken,
    required String deviceId,
    required String compId,
  }) async {
    final response = await _apiClient.delete(
      ApiEndpoints.adminDeviceComponentById(deviceId, compId),
      bearerToken: bearerToken,
    );
    _handleMutationResponse(response, 'Component delete failed.');
  }

  void _handleMutationResponse(ApiResponse response, String fallbackMessage) {
    if (response.isSuccess) {
      return;
    }

    final body = response.data;
    if (body is Map<String, dynamic>) {
      final message = body['message'] ?? body['error'] ?? body['detail'];
      if (message != null && message.toString().trim().isNotEmpty) {
        throw ApiException(message.toString(), statusCode: response.statusCode);
      }
    }

    throw ApiException(fallbackMessage, statusCode: response.statusCode);
  }
}
