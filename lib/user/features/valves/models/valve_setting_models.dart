import 'package:flutter/material.dart';
import 'package:wms/user/features/dashboard/services/customer_devices_service.dart';

class ValveSettingArgs {
  const ValveSettingArgs({
    required this.deviceId,
    required this.displayName,
    required this.espId,
    required this.components,
  });

  final String deviceId;
  final String displayName;
  final String espId;
  final List<CustomerDeviceComponent> components;

  factory ValveSettingArgs.fromDevice(CustomerDeviceSummary device) {
    final componentDetails = device.componentDetails.isNotEmpty
        ? device.componentDetails
              .where((item) => item.type.trim().toUpperCase() == 'VALVE')
              .toList()
        : device.components
              .map(
                (name) => CustomerDeviceComponent(
                  componentId: '',
                  displayName: name,
                  installedArea: '',
                  type: 'VALVE',
                ),
              )
              .toList();

    final items = componentDetails.isEmpty
        ? <CustomerDeviceComponent>[
            const CustomerDeviceComponent(
              componentId: '',
              displayName: '',
              installedArea: '',
              type: 'VALVE',
            ),
          ]
        : componentDetails;

    return ValveSettingArgs(
      deviceId: device.espId,
      displayName: device.displayName,
      espId: device.espId,
      components: items,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! ValveSettingArgs || other.deviceId != deviceId) {
      return false;
    }
    if (other.components.length != components.length) {
      return false;
    }
    for (var index = 0; index < components.length; index++) {
      final left = components[index];
      final right = other.components[index];
      if (left.componentId != right.componentId ||
          left.displayName != right.displayName ||
          left.installedArea != right.installedArea ||
          left.type != right.type) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
    deviceId,
    Object.hashAll(
      components.map(
        (item) =>
            '${item.componentId}|${item.displayName}|${item.installedArea}|${item.type}',
      ),
    ),
  );
}

class ValveSettingState {
  const ValveSettingState({
    required this.valves,
    required this.isLeaving,
  });

  final List<ValveComponentModel> valves;
  final bool isLeaving;

  ValveSettingState copyWith({
    List<ValveComponentModel>? valves,
    bool? isLeaving,
  }) {
    return ValveSettingState(
      valves: valves ?? this.valves,
      isLeaving: isLeaving ?? this.isLeaving,
    );
  }
}

class DayChipData {
  const DayChipData({
    required this.apiDay,
    required this.shortLabel,
    required this.fullLabel,
  });

  final int apiDay;
  final String shortLabel;
  final String fullLabel;
}

class ValveComponentModel {
  const ValveComponentModel({
    required this.valveLabel,
    required this.componentName,
    required this.componentId,
    required this.isActive,
    required this.isExpanded,
    required this.manualActionOn,
    required this.isLoadingSchedules,
    required this.hasLoadedSchedules,
    required this.schedules,
    required this.lastUpdated,
  });

  final String valveLabel;
  final String componentName;
  final String componentId;
  final bool isActive;
  final bool isExpanded;
  final bool manualActionOn;
  final bool isLoadingSchedules;
  final bool hasLoadedSchedules;
  final List<ScheduleCardModel> schedules;
  final DateTime lastUpdated;

  ValveComponentModel copyWith({
    String? valveLabel,
    String? componentName,
    String? componentId,
    bool? isActive,
    bool? isExpanded,
    bool? manualActionOn,
    bool? isLoadingSchedules,
    bool? hasLoadedSchedules,
    List<ScheduleCardModel>? schedules,
    DateTime? lastUpdated,
  }) {
    return ValveComponentModel(
      valveLabel: valveLabel ?? this.valveLabel,
      componentName: componentName ?? this.componentName,
      componentId: componentId ?? this.componentId,
      isActive: isActive ?? this.isActive,
      isExpanded: isExpanded ?? this.isExpanded,
      manualActionOn: manualActionOn ?? this.manualActionOn,
      isLoadingSchedules: isLoadingSchedules ?? this.isLoadingSchedules,
      hasLoadedSchedules: hasLoadedSchedules ?? this.hasLoadedSchedules,
      schedules: schedules ?? this.schedules,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  ValveComponentModel updateSchedule(
    int index,
    ScheduleCardModel Function(ScheduleCardModel item) update,
  ) {
    final nextSchedules = List<ScheduleCardModel>.from(schedules);
    nextSchedules[index] = update(nextSchedules[index]);
    return copyWith(schedules: nextSchedules);
  }
}

class ScheduleCardModel {
  const ScheduleCardModel({
    required this.cardKey,
    required this.persisted,
    required this.scheduleId,
    required this.isExpanded,
    required this.selectedDays,
    required this.initialSelectedDays,
    required this.fromTime,
    required this.initialFromTime,
    required this.toTime,
    required this.initialToTime,
    required this.isSubmitting,
  });

  final String cardKey;
  final bool persisted;
  final String scheduleId;
  final bool isExpanded;
  final Set<int> selectedDays;
  final Set<int> initialSelectedDays;
  final TimeOfDay? fromTime;
  final TimeOfDay? initialFromTime;
  final TimeOfDay? toTime;
  final TimeOfDay? initialToTime;
  final bool isSubmitting;

  factory ScheduleCardModel.createDraft() {
    return ScheduleCardModel(
      cardKey: DateTime.now().microsecondsSinceEpoch.toString(),
      persisted: false,
      scheduleId: '',
      isExpanded: false,
      selectedDays: <int>{},
      initialSelectedDays: <int>{},
      fromTime: null,
      initialFromTime: null,
      toTime: null,
      initialToTime: null,
      isSubmitting: false,
    );
  }

  factory ScheduleCardModel.fromRemote(CustomerComponentSchedule schedule) {
    final from = TimeOfDay(
      hour: schedule.startTime.hour,
      minute: schedule.startTime.minute,
    );
    final to = TimeOfDay(
      hour: schedule.endTime.hour,
      minute: schedule.endTime.minute,
    );
    final days = schedule.days.toSet();
    return ScheduleCardModel(
      cardKey: schedule.scheduleId.isEmpty
          ? DateTime.now().microsecondsSinceEpoch.toString()
          : schedule.scheduleId,
      persisted: true,
      scheduleId: schedule.scheduleId,
      isExpanded: false,
      selectedDays: days,
      initialSelectedDays: Set<int>.from(days),
      fromTime: from,
      initialFromTime: from,
      toTime: to,
      initialToTime: to,
      isSubmitting: false,
    );
  }

  ScheduleCardModel copyWith({
    String? cardKey,
    bool? persisted,
    String? scheduleId,
    bool? isExpanded,
    Set<int>? selectedDays,
    Set<int>? initialSelectedDays,
    TimeOfDay? fromTime,
    Object? initialFromTime = _marker,
    TimeOfDay? toTime,
    Object? initialToTime = _marker,
    bool? isSubmitting,
  }) {
    return ScheduleCardModel(
      cardKey: cardKey ?? this.cardKey,
      persisted: persisted ?? this.persisted,
      scheduleId: scheduleId ?? this.scheduleId,
      isExpanded: isExpanded ?? this.isExpanded,
      selectedDays: selectedDays ?? this.selectedDays,
      initialSelectedDays: initialSelectedDays ?? this.initialSelectedDays,
      fromTime: fromTime ?? this.fromTime,
      initialFromTime: identical(initialFromTime, _marker)
          ? this.initialFromTime
          : initialFromTime as TimeOfDay?,
      toTime: toTime ?? this.toTime,
      initialToTime: identical(initialToTime, _marker)
          ? this.initialToTime
          : initialToTime as TimeOfDay?,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }

  bool get hasChanges {
    if (!_sameDaySet(selectedDays, initialSelectedDays)) {
      return true;
    }
    if (!_sameTimeOfDay(fromTime, initialFromTime)) {
      return true;
    }
    if (!_sameTimeOfDay(toTime, initialToTime)) {
      return true;
    }
    return !persisted;
  }
}

bool sameTimeOfDay(TimeOfDay? left, TimeOfDay? right) {
  if (left == null || right == null) {
    return left == right;
  }
  return left.hour == right.hour && left.minute == right.minute;
}

bool _sameTimeOfDay(TimeOfDay? left, TimeOfDay? right) =>
    sameTimeOfDay(left, right);

bool sameDaySet(Set<int> left, Set<int> right) {
  if (left.length != right.length) {
    return false;
  }
  for (final item in left) {
    if (!right.contains(item)) {
      return false;
    }
  }
  return true;
}

bool _sameDaySet(Set<int> left, Set<int> right) => sameDaySet(left, right);

CustomerScheduleTime scheduleTimeFrom(TimeOfDay value) {
  return CustomerScheduleTime(hour: value.hour, minute: value.minute);
}

int durationInMinutes(TimeOfDay from, TimeOfDay to) {
  return toMinutes(to) - toMinutes(from);
}

int toMinutes(TimeOfDay value) => value.hour * 60 + value.minute;

String? scheduleValidationMessage({
  required ValveComponentModel valve,
  required int scheduleIndex,
}) {
  final schedule = valve.schedules[scheduleIndex];
  if (schedule.selectedDays.isEmpty) {
    return 'Select at least one day.';
  }
  if (schedule.fromTime == null || schedule.toTime == null) {
    return 'Select both From and To time.';
  }

  final fromMinutes = toMinutes(schedule.fromTime!);
  final toMinutesValue = toMinutes(schedule.toTime!);
  if (fromMinutes >= toMinutesValue) {
    return '"To" time must be greater than "From" time.';
  }

  for (var index = 0; index < valve.schedules.length; index++) {
    if (index == scheduleIndex) {
      continue;
    }
    final other = valve.schedules[index];
    if (other.selectedDays.isEmpty ||
        other.fromTime == null ||
        other.toTime == null) {
      continue;
    }

    final sharedDays =
        schedule.selectedDays.intersection(other.selectedDays).isNotEmpty;
    if (!sharedDays) {
      continue;
    }

    final otherStart = toMinutes(other.fromTime!);
    final otherEnd = toMinutes(other.toTime!);
    final overlaps = fromMinutes < otherEnd && otherStart < toMinutesValue;
    if (overlaps) {
      return 'Schedule time overlaps another card for the selected day.';
    }
  }

  return null;
}

const List<DayChipData> dayChips = <DayChipData>[
  DayChipData(apiDay: 1, shortLabel: 'M', fullLabel: 'Monday'),
  DayChipData(apiDay: 2, shortLabel: 'T', fullLabel: 'Tuesday'),
  DayChipData(apiDay: 3, shortLabel: 'W', fullLabel: 'Wednesday'),
  DayChipData(apiDay: 4, shortLabel: 'T', fullLabel: 'Thursday'),
  DayChipData(apiDay: 5, shortLabel: 'F', fullLabel: 'Friday'),
  DayChipData(apiDay: 6, shortLabel: 'S', fullLabel: 'Saturday'),
  DayChipData(apiDay: 7, shortLabel: 'S', fullLabel: 'Sunday'),
];

const Object _marker = Object();
