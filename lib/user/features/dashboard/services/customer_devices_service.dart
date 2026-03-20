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
    required int duration,
  }) async {
    final normalizedComponentId = componentId.trim();
    if (normalizedComponentId.isEmpty) {
      throw const ApiException('Component ID is missing.');
    }

    final normalizedAction = action.trim().toUpperCase();
    if (normalizedAction != 'ON' && normalizedAction != 'OFF') {
      throw const ApiException('Action must be ON or OFF.');
    }
    if (normalizedAction == 'ON' && (duration < 1 || duration > 300)) {
      throw const ApiException('Duration must be between 1 and 300 minutes.');
    }
    if (normalizedAction == 'OFF' && duration < 0) {
      throw const ApiException('Duration is invalid.');
    }

    final response = await _apiClient.post(
      ApiEndpoints.customerManualTriggers,
      bearerToken: bearerToken,
      queryParameters: <String, dynamic>{
        'componentId': normalizedComponentId,
        'action': normalizedAction,
        'duration': duration,
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

  Future<List<CustomerComponentSchedule>> getComponentSchedules({
    required String bearerToken,
    required String componentId,
  }) async {
    final normalizedComponentId = componentId.trim();
    debugPrint(
      'CUSTOMER_DEVICES getComponentSchedules:start componentId=$normalizedComponentId',
    );
    if (normalizedComponentId.isEmpty) {
      debugPrint('CUSTOMER_DEVICES getComponentSchedules: skipped empty componentId');
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
}
