import 'package:wms/admin/features/devices/services/admin_device_component_service.dart';

enum TriggerType {
  manual('MANUAL'),
  scheduled('SCHEDULED'),
  auto('AUTO'),
  autoCutoff('AUTO_CUTOFF');

  const TriggerType(this.value);
  final String value;

  static TriggerType? fromString(String? value) {
    if (value == null) return null;
    return TriggerType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => TriggerType.manual,
    );
  }
}

class TriggerLog {
  const TriggerLog({
    required this.logId,
    required this.espId,
    required this.componentId,
    required this.componentName,
    required this.componentType,
    required this.action,
    required this.status,
    required this.triggeredAt,
    this.confirmedAt,
    this.durationMins,
    required this.triggerType,
    this.notes,
    this.triggeredBy,
    this.triggeredByUsername,
    this.actorName,
    this.scheduleId,
  });

  final int logId;
  final String espId;
  final int componentId;
  final String componentName;
  final AdminComponentType componentType;
  final String action;
  final String status;
  final DateTime triggeredAt;
  final DateTime? confirmedAt;
  final int? durationMins;
  final TriggerType triggerType;
  final String? notes;
  final String? triggeredBy;
  final String? triggeredByUsername;
  final String? actorName;
  final int? scheduleId;

  factory TriggerLog.fromJson(Map<String, dynamic> json) {
    return TriggerLog(
      logId: (json['logId'] as num).toInt(),
      espId: json['espId'] ?? '',
      componentId: (json['componentId'] as num).toInt(),
      componentName: json['componentName'] ?? '',
      componentType: _parseComponentType(json['componentType']),
      action: json['action'] ?? '',
      status: json['status'] ?? '',
      triggeredAt: DateTime.parse(json['triggeredAt']),
      confirmedAt: json['confirmedAt'] != null ? DateTime.parse(json['confirmedAt']) : null,
      durationMins: (json['durationMins'] as num?)?.toInt(),
      triggerType: TriggerType.fromString(json['triggerType']) ?? TriggerType.manual,
      notes: json['notes'],
      triggeredBy: json['triggeredBy'],
      triggeredByUsername: json['triggeredByUsername'],
      actorName: json['actorName'],
      scheduleId: (json['scheduleId'] as num?)?.toInt(),
    );
  }

  static AdminComponentType _parseComponentType(String? type) {
    if (type == 'MOTOR') return AdminComponentType.motor;
    if (type == 'VALVE') return AdminComponentType.valve;
    if (type == 'SENSOR') return AdminComponentType.sensor;
    return AdminComponentType.motor; // Default
  }
}

class TriggerLogPageResult {
  const TriggerLogPageResult({
    required this.items,
    required this.page,
    required this.size,
    required this.totalPages,
    required this.totalElements,
  });

  final List<TriggerLog> items;
  final int page;
  final int size;
  final int totalPages;
  final int totalElements;

  bool get hasNext => page < totalPages - 1;
  bool get hasPrevious => page > 0;
}

class TriggerLogQuery {
  const TriggerLogQuery({
    this.page = 0,
    this.size = 20,
    this.espId,
    this.triggerType,
    this.componentType,
    this.actorId,
    this.startTime,
    this.endTime,
  });

  final int page;
  final int size;
  final String? espId;
  final TriggerType? triggerType;
  final AdminComponentType? componentType;
  final String? actorId;
  final DateTime? startTime;
  final DateTime? endTime;

  TriggerLogQuery copyWith({
    int? page,
    int? size,
    String? espId,
    TriggerType? triggerType,
    AdminComponentType? componentType,
    String? actorId,
    DateTime? startTime,
    DateTime? endTime,
    bool clearTriggerType = false,
    bool clearComponentType = false,
    bool clearStartTime = false,
    bool clearEndTime = false,
  }) {
    return TriggerLogQuery(
      page: page ?? this.page,
      size: size ?? this.size,
      espId: espId ?? this.espId,
      triggerType: clearTriggerType ? null : (triggerType ?? this.triggerType),
      componentType: clearComponentType ? null : (componentType ?? this.componentType),
      actorId: actorId ?? this.actorId,
      startTime: clearStartTime ? null : (startTime ?? this.startTime),
      endTime: clearEndTime ? null : (endTime ?? this.endTime),
    );
  }
}
