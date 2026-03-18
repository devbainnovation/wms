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

class CustomerScheduleTime {
  const CustomerScheduleTime({
    required this.hour,
    required this.minute,
    this.second = 0,
    this.nano = 0,
  });

  final int hour;
  final int minute;
  final int second;
  final int nano;

  factory CustomerScheduleTime.fromValue(dynamic value) {
    if (value is Map<String, dynamic>) {
      return CustomerScheduleTime.fromJson(value);
    }
    if (value is String) {
      return CustomerScheduleTime.fromFormattedString(value);
    }
    return const CustomerScheduleTime(hour: 0, minute: 0);
  }

  factory CustomerScheduleTime.fromFormattedString(String value) {
    final match = RegExp(
      r'^\s*(\d{1,2}):(\d{2})(?::(\d{2}))?\s*$',
    ).firstMatch(value);
    if (match == null) {
      return const CustomerScheduleTime(hour: 0, minute: 0);
    }

    return CustomerScheduleTime(
      hour: int.tryParse(match.group(1) ?? '') ?? 0,
      minute: int.tryParse(match.group(2) ?? '') ?? 0,
      second: int.tryParse(match.group(3) ?? '') ?? 0,
    );
  }

  factory CustomerScheduleTime.fromJson(Map<String, dynamic> json) {
    return CustomerScheduleTime(
      hour: (json['hour'] as num?)?.toInt() ?? 0,
      minute: (json['minute'] as num?)?.toInt() ?? 0,
      second: (json['second'] as num?)?.toInt() ?? 0,
      nano: (json['nano'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hour': hour,
      'minute': minute,
      'second': second,
      'nano': nano,
    };
  }

  String toFormattedString() {
    final normalizedHour = hour.clamp(0, 23);
    final normalizedMinute = minute.clamp(0, 59);
    return '${normalizedHour.toString().padLeft(2, '0')}:${normalizedMinute.toString().padLeft(2, '0')}';
  }
}

class CustomerComponentScheduleRequest {
  const CustomerComponentScheduleRequest({
    required this.days,
    required this.startTime,
    required this.endTime,
    required this.durationMins,
    required this.enabled,
  });

  final List<int> days;
  final CustomerScheduleTime startTime;
  final CustomerScheduleTime endTime;
  final int durationMins;
  final bool enabled;

  Map<String, dynamic> toJson() {
    return {
      'days': days,
      'startTime': startTime.toFormattedString(),
      'endTime': endTime.toFormattedString(),
      'durationMins': durationMins,
      'isEnabled': enabled,
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'days': days,
      'startTime': startTime.toJson(),
      'endTime': endTime.toJson(),
      'durationMins': durationMins,
      'enabled': enabled,
    };
  }
}

class CustomerComponentSchedule {
  const CustomerComponentSchedule({
    required this.scheduleId,
    required this.days,
    required this.startTime,
    required this.endTime,
    required this.durationMins,
    required this.enabled,
  });

  final String scheduleId;
  final List<int> days;
  final CustomerScheduleTime startTime;
  final CustomerScheduleTime endTime;
  final int durationMins;
  final bool enabled;

  factory CustomerComponentSchedule.fromJson(Map<String, dynamic> json) {
    final rawDays = json['days'];
    final days = rawDays is List
        ? rawDays
              .map((item) => _normalizeScheduleDay((item as num?)?.toInt()))
              .whereType<int>()
              .toList()
        : const <int>[];

    return CustomerComponentSchedule(
      scheduleId: (json['id'] ?? json['scheduleId'] ?? '').toString().trim(),
      days: days,
      startTime: CustomerScheduleTime.fromValue(json['startTime']),
      endTime: CustomerScheduleTime.fromValue(json['endTime']),
      durationMins: (json['durationMins'] as num?)?.toInt() ?? 0,
      enabled: (json['isEnabled'] ?? json['enabled']) != false,
    );
  }
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

  Future<List<CustomerComponentSchedule>> getComponentSchedules({
    required String bearerToken,
    required String componentId,
  }) async {
    final normalizedComponentId = componentId.trim();
    if (normalizedComponentId.isEmpty) {
      return const <CustomerComponentSchedule>[];
    }

    final response = await _apiClient.get(
      ApiEndpoints.appSchedules,
      bearerToken: bearerToken,
      queryParameters: <String, dynamic>{'componentId': normalizedComponentId},
      showGlobalLoader: false,
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

    return rawList
        .whereType<Map<String, dynamic>>()
        .map(CustomerComponentSchedule.fromJson)
        .toList();
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
      body: request.toUpdateJson(),
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

int? _normalizeScheduleDay(int? day) {
  if (day == null) {
    return null;
  }
  if (day == 0) {
    return 7;
  }
  if (day >= 1 && day <= 7) {
    return day;
  }
  return null;
}
