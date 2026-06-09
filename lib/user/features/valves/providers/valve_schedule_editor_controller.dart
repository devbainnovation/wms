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
  });

  final bool allMode;
  final Set<int> selectedDays;
  final TimeOfDay? fromTime;
  final TimeOfDay? toTime;
  final bool isSubmitting;

  ValveScheduleEditorState copyWith({
    bool? allMode,
    Set<int>? selectedDays,
    TimeOfDay? fromTime,
    TimeOfDay? toTime,
    bool? isSubmitting,
  }) {
    return ValveScheduleEditorState(
      allMode: allMode ?? this.allMode,
      selectedDays: selectedDays ?? this.selectedDays,
      fromTime: fromTime ?? this.fromTime,
      toTime: toTime ?? this.toTime,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}

final valveScheduleEditorProvider = legacy.ChangeNotifierProvider.autoDispose
    .family<ValveScheduleEditorController, ScheduleCardModel>(
      (ref, schedule) => ValveScheduleEditorController(schedule),
    );

class ValveScheduleEditorController extends ChangeNotifier {
  ValveScheduleEditorController(ScheduleCardModel schedule)
    : _state = ValveScheduleEditorState(
        allMode: schedule.selectedDays.length == 7,
        selectedDays: Set<int>.from(schedule.selectedDays),
        fromTime: schedule.fromTime,
        toTime: schedule.toTime,
        isSubmitting: false,
      );

  late ValveScheduleEditorState _state;

  ValveScheduleEditorState get state => _state;

  bool get hasValidSchedule {
    return _state.selectedDays.isNotEmpty &&
        _state.fromTime != null &&
        _state.toTime != null &&
        durationInMinutes(_state.fromTime!, _state.toTime!) > 0;
  }

  String get modeLabel => _state.allMode ? 'All days' : 'Alternate days';

  void selectAllMode() {
    _state = _state.copyWith(
      allMode: true,
      selectedDays: dayChips.map((item) => item.apiDay).toSet(),
    );
    notifyListeners();
  }

  void selectAlternateMode() {
    _state = _state.copyWith(
      allMode: false,
      selectedDays: _state.selectedDays.length == 7
          ? <int>{}
          : _state.selectedDays,
    );
    notifyListeners();
  }

  void toggleDay(int apiDay) {
    if (_state.allMode) {
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
    _state = _state.copyWith(fromTime: time);
    notifyListeners();
  }

  void setToTime(TimeOfDay time) {
    _state = _state.copyWith(toTime: time);
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
    );
  }
}
