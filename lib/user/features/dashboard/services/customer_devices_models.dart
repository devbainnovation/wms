class CustomerDeviceComponent {
  const CustomerDeviceComponent({
    required this.componentId,
    required this.displayName,
    required this.installedArea,
    required this.type,
  });

  final String componentId;
  final String displayName;
  final String installedArea;
  final String type;
}

class CustomerMotorSummary {
  const CustomerMotorSummary({
    required this.componentId,
    required this.name,
    required this.status,
    required this.startedAt,
    required this.estimatedOffAt,
  });

  final String componentId;
  final String name;
  final String status;
  final String startedAt;
  final String estimatedOffAt;

  bool get isOn => status.trim().toUpperCase() == 'ON';

  factory CustomerMotorSummary.fromJson(Map<String, dynamic> json) {
    return CustomerMotorSummary(
      componentId: _readTextFromJson(json, const ['componentId', 'id']),
      name: _readTextFromJson(json, const ['name', 'displayName']),
      status: _readTextFromJson(json, const ['status']),
      startedAt: _readTextFromJson(json, const ['startedAt']),
      estimatedOffAt: _readTextFromJson(json, const ['estimatedOffAt']),
    );
  }
}

class CustomerValveSummary {
  const CustomerValveSummary({
    required this.componentId,
    required this.name,
    required this.status,
    required this.installedArea,
    required this.startedAt,
    required this.estimatedOffAt,
  });

  final String componentId;
  final String name;
  final String status;
  final String installedArea;
  final String startedAt;
  final String estimatedOffAt;

  bool get isOn => status.trim().toUpperCase() == 'ON';

  factory CustomerValveSummary.fromJson(Map<String, dynamic> json) {
    return CustomerValveSummary(
      componentId: _readTextFromJson(json, const ['componentId', 'id']),
      name: _readTextFromJson(json, const ['name', 'displayName']),
      status: _readTextFromJson(json, const ['status']),
      installedArea: _readTextFromJson(json, const ['installedArea']),
      startedAt: _readTextFromJson(json, const ['startedAt']),
      estimatedOffAt: _readTextFromJson(json, const ['estimatedOffAt']),
    );
  }
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
    required this.motor,
    required this.valves,
    required this.allValvesOff,
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
  final CustomerMotorSummary? motor;
  final List<CustomerValveSummary> valves;
  final bool allValvesOff;
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
                installedArea: readFromMap(item, const ['installedArea']),
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
              installedArea: '',
              type: '',
            );
          })
          .whereType<CustomerDeviceComponent>()
          .toList();
    }

    CustomerMotorSummary? readMotor() {
      final raw = json['motor'];
      if (raw is Map<String, dynamic>) {
        return CustomerMotorSummary.fromJson(raw);
      }
      return null;
    }

    List<CustomerValveSummary> readValves() {
      final raw = json['valves'];
      if (raw is! List) {
        return const <CustomerValveSummary>[];
      }
      return raw
          .whereType<Map<String, dynamic>>()
          .map(CustomerValveSummary.fromJson)
          .toList();
    }

    final componentDetails = readComponents();
    final motor = readMotor();
    final valves = readValves();
    final hasExplicitMotorOrValves =
        json.containsKey('motor') || json.containsKey('valves');
    final resolvedIsActive = hasExplicitMotorOrValves
        ? (motor?.isOn ?? false)
        : readBool(const ['active', 'isActive']);

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
      motor: motor,
      valves: valves,
      allValvesOff:
          (json['allValvesOff'] as bool?) ??
          (valves.isEmpty ? true : !valves.any((item) => item.isOn)),
      isActive: resolvedIsActive,
      isOnline: readBool(const ['online', 'isOnline']),
    );
  }
}

String _readTextFromJson(Map<String, dynamic> json, List<String> keys) {
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
