import 'package:flutter/foundation.dart';
import 'package:wms/core/api/api.dart';
import 'package:wms/user/features/dashboard/services/customer_devices_models.dart';

export 'customer_devices_models.dart';

class CustomerDevicesService {
  CustomerDevicesService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<CustomerDeviceSummary>> getDevices({
    required String bearerToken,
  }) async {
    final response = await _apiClient.get(
      ApiEndpoints.appDashboard,
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

  Future<List<CustomerDeviceSummary>> getCustomerDevices({
    required String bearerToken,
  }) async {
    final response = await _apiClient.get(
      ApiEndpoints.customerDevices,
      bearerToken: bearerToken,
      showGlobalLoader: false,
    );

    if (!response.isSuccess) {
      throw ApiException(
        _extractMessage(response.data) ?? 'Unable to fetch customer devices.',
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

  Future<List<CustomerDeviceComponent>> getDeviceComponents({
    required String bearerToken,
    required String espId,
  }) async {
    final normalizedEspId = espId.trim();
    if (normalizedEspId.isEmpty) {
      throw const ApiException('Device ID is missing.');
    }

    final response = await _apiClient.get(
      ApiEndpoints.customerDeviceComponents(normalizedEspId),
      bearerToken: bearerToken,
      showGlobalLoader: false,
    );

    if (!response.isSuccess) {
      throw ApiException(
        _extractMessage(response.data) ?? 'Unable to fetch device components.',
        statusCode: response.statusCode,
      );
    }

    final data = response.data;
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(_mapDeviceComponent)
          .toList();
    }

    if (data is Map<String, dynamic>) {
      final content = data['content'] ?? data['items'] ?? data['data'];
      if (content is List) {
        return content
            .whereType<Map<String, dynamic>>()
            .map(_mapDeviceComponent)
            .toList();
      }
    }

    return const <CustomerDeviceComponent>[];
  }

  Future<ApiResponse> triggerManualAction({
    required String bearerToken,
    required String componentId,
    required String action,
    int? duration,
  }) async {
    final normalizedComponentId = componentId.trim();
    if (normalizedComponentId.isEmpty) {
      throw const ApiException('Component ID is missing.');
    }

    final normalizedAction = action.trim().toUpperCase();
    if (normalizedAction != 'ON' && normalizedAction != 'OFF') {
      throw const ApiException('Action must be ON or OFF.');
    }
    final resolvedDuration = duration;
    if (normalizedAction == 'ON' &&
        resolvedDuration != null &&
        (resolvedDuration < 0 || resolvedDuration > 300)) {
      throw const ApiException(
        'Duration must be between 0 and 300 minutes.',
      );
    }
    if (normalizedAction == 'OFF' &&
        resolvedDuration != null &&
        resolvedDuration < 0) {
      throw const ApiException('Duration is invalid.');
    }

    final queryParameters = <String, dynamic>{
      'componentId': normalizedComponentId,
      'action': normalizedAction,
    };
    if (resolvedDuration != null) {
      queryParameters['duration'] = resolvedDuration;
    }

    final response = await _apiClient.post(
      ApiEndpoints.customerManualTriggers,
      bearerToken: bearerToken,
      queryParameters: queryParameters,
    );

    if (!response.isSuccess) {
      throw ApiException(
        _extractMessage(response.data) ?? 'Unable to trigger manual action.',
        statusCode: response.statusCode,
      );
    }

    return response;
  }

  Future<ApiResponse> updateMotorSettings({
    required String bearerToken,
    required String motorId,
    required String sensorId,
    required int min,
    required int max,
  }) async {
    final normalizedMotorId = motorId.trim();
    final normalizedSensorId = sensorId.trim();

    if (normalizedMotorId.isEmpty) {
      throw const ApiException('Motor ID is missing.');
    }
    if (normalizedSensorId.isEmpty) {
      throw const ApiException('Sensor ID is missing.');
    }
    if (min <= 0 || max <= 0) {
      throw const ApiException('Min and max must be greater than 0.');
    }
    if (min > max) {
      throw const ApiException('Min cannot be greater than max.');
    }

    final response = await _apiClient.put(
      ApiEndpoints.customerMotorSettings,
      bearerToken: bearerToken,
      queryParameters: <String, dynamic>{
        'motorId': normalizedMotorId,
        'sensorId': normalizedSensorId,
        'min': min,
        'max': max,
      },
    );

    if (!response.isSuccess) {
      throw ApiException(
        _extractMessage(response.data) ?? 'Unable to update motor settings.',
        statusCode: response.statusCode,
      );
    }

    return response;
  }

  Future<CustomerMotorSettings> getMotorSettings({
    required String bearerToken,
    required String motorId,
  }) async {
    final normalizedMotorId = motorId.trim();
    if (normalizedMotorId.isEmpty) {
      throw const ApiException('Motor ID is missing.');
    }

    final response = await _apiClient.get(
      ApiEndpoints.customerMotorSettings,
      bearerToken: bearerToken,
      queryParameters: <String, dynamic>{'motorId': normalizedMotorId},
      showGlobalLoader: false,
    );

    if (!response.isSuccess) {
      throw ApiException(
        _extractMessage(response.data) ?? 'Unable to fetch motor settings.',
        statusCode: response.statusCode,
      );
    }

    final body = response.dataAsMap;
    if (body == null) {
      throw const ApiException('Invalid motor settings response.');
    }

    return CustomerMotorSettings.fromJson(body);
  }

  Future<List<CustomerComponentSchedule>> getComponentSchedules({
    required String bearerToken,
    required String componentId,
  }) async {
    final normalizedComponentId = componentId.trim();
    debugPrint(
      'CUSTOMER_DEVICES getComponentSchedules:start componentId=$normalizedComponentId',
    );
    if (normalizedComponentId.isEmpty) {
      debugPrint(
        'CUSTOMER_DEVICES getComponentSchedules: skipped empty componentId',
      );
      return const <CustomerComponentSchedule>[];
    }

    final response = await _apiClient.get(
      ApiEndpoints.appComponentSchedules(normalizedComponentId),
      bearerToken: bearerToken,
      showGlobalLoader: false,
    );
    debugPrint(
      'CUSTOMER_DEVICES getComponentSchedules: status=${response.statusCode}, '
      'componentId=$normalizedComponentId',
    );

    if (!response.isSuccess) {
      throw ApiException(
        _extractMessage(response.data) ?? 'Unable to fetch schedules.',
        statusCode: response.statusCode,
      );
    }

    final data = response.data;
    final rawList = switch (data) {
      List<dynamic>() => data,
      Map<String, dynamic>() =>
        data['content'] is List
            ? data['content'] as List<dynamic>
            : data['data'] is List
            ? data['data'] as List<dynamic>
            : data['items'] is List
            ? data['items'] as List<dynamic>
            : const <dynamic>[],
      _ => const <dynamic>[],
    };

    final schedules = rawList
        .whereType<Map<String, dynamic>>()
        .map(CustomerComponentSchedule.fromJson)
        .toList();
    debugPrint(
      'CUSTOMER_DEVICES getComponentSchedules: parsed=${schedules.length}, '
      'componentId=$normalizedComponentId',
    );
    return schedules;
  }

  Future<ApiResponse> createSchedule({
    required String bearerToken,
    required String componentId,
    required CustomerComponentScheduleRequest request,
  }) async {
    final normalizedComponentId = componentId.trim();
    if (normalizedComponentId.isEmpty) {
      throw const ApiException('Component ID is missing.');
    }

    final response = await _apiClient.post(
      ApiEndpoints.appSchedules,
      bearerToken: bearerToken,
      queryParameters: <String, dynamic>{'componentId': normalizedComponentId},
      body: request.toJson(),
    );

    if (!response.isSuccess) {
      throw ApiException(
        _extractMessage(response.data) ?? 'Unable to save schedule.',
        statusCode: response.statusCode,
      );
    }

    return response;
  }

  Future<ApiResponse> updateSchedule({
    required String bearerToken,
    required String componentId,
    required String scheduleId,
    required CustomerComponentScheduleRequest request,
  }) async {
    final normalizedComponentId = componentId.trim();
    final normalizedScheduleId = scheduleId.trim();
    if (normalizedComponentId.isEmpty) {
      throw const ApiException('Component ID is missing.');
    }
    if (normalizedScheduleId.isEmpty) {
      throw const ApiException('Schedule ID is missing.');
    }

    final response = await _apiClient.put(
      ApiEndpoints.appScheduleById(normalizedScheduleId),
      bearerToken: bearerToken,
      queryParameters: <String, dynamic>{'componentId': normalizedComponentId},
      body: request.toJson(),
    );

    if (!response.isSuccess) {
      throw ApiException(
        _extractMessage(response.data) ?? 'Unable to update schedule.',
        statusCode: response.statusCode,
      );
    }

    return response;
  }

  Future<ApiResponse> deleteSchedule({
    required String bearerToken,
    required String componentId,
    required String scheduleId,
  }) async {
    final normalizedComponentId = componentId.trim();
    final normalizedScheduleId = scheduleId.trim();
    if (normalizedComponentId.isEmpty) {
      throw const ApiException('Component ID is missing.');
    }
    if (normalizedScheduleId.isEmpty) {
      throw const ApiException('Schedule ID is missing.');
    }

    final response = await _apiClient.delete(
      ApiEndpoints.appScheduleById(normalizedScheduleId),
      bearerToken: bearerToken,
      queryParameters: <String, dynamic>{'componentId': normalizedComponentId},
    );

    if (!response.isSuccess) {
      throw ApiException(
        _extractMessage(response.data) ?? 'Unable to delete schedule.',
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

  CustomerDeviceComponent _mapDeviceComponent(Map<String, dynamic> json) {
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

    return CustomerDeviceComponent(
      componentId: read(const ['componentId', 'id']),
      displayName: read(const ['name', 'displayName']),
      installedArea: read(const ['installedArea']),
      type: read(const ['type']),
      gpioPin: (json['gpioPin'] as num?)?.toInt() ?? 0,
    );
  }
}
