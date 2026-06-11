import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart' as legacy;
import 'package:wms/user/features/valves/models/valve_setting_models.dart';

class ValveScheduleEditorState {
  ValveScheduleEditorState({
    required this.allMode,
    required this.selectedDays,
    required this.fromTime,
    required this.toTime,
    required this.isSubmitting,
    required this.alternateStartDate,
    required this.alternateEndDate,
    required this.alternateInterval,
    required this.timeTouchEnabled,
  });

  final bool allMode;
  final Set<int> selectedDays;
  final TimeOfDay? fromTime;
  final TimeOfDay? toTime;
  final bool isSubmitting;
  final DateTime? alternateStartDate;
  final DateTime? alternateEndDate;
  final int alternateInterval;
  final bool timeTouchEnabled;

  ValveScheduleEditorState copyWith({
    bool? allMode,
    Set<int>? selectedDays,
    Object? fromTime = _marker,
    Object? toTime = _marker,
    bool? isSubmitting,
    Object? alternateStartDate = _marker,
    Object? alternateEndDate = _marker,
    int? alternateInterval,
    bool? timeTouchEnabled,
  }) {
    return ValveScheduleEditorState(
      allMode: allMode ?? this.allMode,
      selectedDays: selectedDays ?? this.selectedDays,
      fromTime: identical(fromTime, _marker) ? this.fromTime : fromTime as TimeOfDay?,
      toTime: identical(toTime, _marker) ? this.toTime : toTime as TimeOfDay?,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      alternateStartDate: identical(alternateStartDate, _marker)
          ? this.alternateStartDate
          : alternateStartDate as DateTime?,
      alternateEndDate: identical(alternateEndDate, _marker)
          ? this.alternateEndDate
          : alternateEndDate as DateTime?,
      alternateInterval: alternateInterval ?? this.alternateInterval,
      timeTouchEnabled: timeTouchEnabled ?? this.timeTouchEnabled,
    );
  }
}

const Object _marker = Object();

final valveScheduleEditorProvider = legacy.ChangeNotifierProvider.autoDispose
    .family<ValveScheduleEditorController, ScheduleCardModel>(
      (ref, schedule) => ValveScheduleEditorController(schedule),
    );

class ValveScheduleEditorController extends ChangeNotifier {
  ValveScheduleEditorController(ScheduleCardModel schedule)
    : _state = ValveScheduleEditorState(
        allMode: !schedule.alternateMode,
        selectedDays: Set<int>.from(schedule.selectedDays),
        fromTime: schedule.fromTime,
        toTime: schedule.toTime,
        isSubmitting: false,
        alternateStartDate: schedule.alternateStartDate,
        alternateEndDate: schedule.alternateEndDate,
        alternateInterval: schedule.alternateInterval,
        timeTouchEnabled: schedule.fromTime != null && schedule.toTime != null,
      );

  late ValveScheduleEditorState _state;

  ValveScheduleEditorState get state => _state;

  bool get hasValidSchedule {
    if (_state.allMode) {
      return _state.selectedDays.isNotEmpty &&
          _state.fromTime != null &&
          _state.toTime != null &&
          durationInMinutes(_state.fromTime!, _state.toTime!) > 0;
    }
    return _state.alternateStartDate != null &&
        _state.alternateEndDate != null &&
        !_state.alternateStartDate!.isAfter(_state.alternateEndDate!) &&
        _state.alternateEndDate!
                .difference(_state.alternateStartDate!)
                .inDays >=
            _state.alternateInterval &&
        _state.alternateInterval >= 1 &&
        _state.alternateInterval <= 6 &&
        _state.fromTime != null &&
        _state.toTime != null &&
        durationInMinutes(_state.fromTime!, _state.toTime!) > 0;
  }

  String get modeLabel => _state.allMode ? 'Weekly' : 'Interval';

  void selectAllMode() {
    _state = _state.copyWith(
      allMode: true,
      selectedDays: <int>{},
      fromTime: null,
      toTime: null,
      alternateStartDate: null,
      alternateEndDate: null,
      alternateInterval: 1,
      timeTouchEnabled: false,
    );
    notifyListeners();
  }

  void selectAlternateMode() {
    _state = _state.copyWith(
      allMode: false,
      selectedDays: <int>{},
      fromTime: null,
      toTime: null,
      alternateStartDate: null,
      alternateEndDate: null,
      alternateInterval: 1,
      timeTouchEnabled: false,
    );
    notifyListeners();
  }

  void toggleDay(int apiDay) {
    if (apiDay == 0) {
      final allDays = dayChips.map((item) => item.apiDay).toSet();
      final nextDays = _state.selectedDays.length == 7 ? <int>{} : allDays;
      _state = _state.copyWith(selectedDays: nextDays);
      notifyListeners();
      return;
    }

    final nextDays = Set<int>.from(_state.selectedDays);
    if (!nextDays.add(apiDay)) {
      nextDays.remove(apiDay);
    }
    _state = _state.copyWith(selectedDays: nextDays);
    notifyListeners();
  }

  void setFromTime(TimeOfDay time) {
    _state = _state.copyWith(fromTime: time, timeTouchEnabled: true);
    notifyListeners();
  }

  void setToTime(TimeOfDay time) {
    _state = _state.copyWith(toTime: time, timeTouchEnabled: true);
    notifyListeners();
  }

  void setAlternateStartDate(DateTime date) {
    _state = _state.copyWith(alternateStartDate: date);
    notifyListeners();
  }

  void setAlternateEndDate(DateTime date) {
    _state = _state.copyWith(alternateEndDate: date);
    notifyListeners();
  }

  void setAlternateInterval(int interval) {
    _state = _state.copyWith(alternateInterval: interval);
    notifyListeners();
  }

  void setIsSubmitting(bool isSubmitting) {
    _state = _state.copyWith(isSubmitting: isSubmitting);
    notifyListeners();
  }

  ScheduleCardModel buildSchedule(ScheduleCardModel original) {
    return original.copyWith(
      selectedDays: Set<int>.from(_state.selectedDays),
      fromTime: _state.fromTime,
      toTime: _state.toTime,
      alternateMode: !_state.allMode,
      alternateStartDate: _state.alternateStartDate,
      alternateEndDate: _state.alternateEndDate,
      alternateInterval: _state.alternateInterval,
    );
  }
}
