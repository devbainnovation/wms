import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart' as legacy;
import 'package:wms/core/core.dart';
import 'package:wms/user/features/dashboard/providers/providers.dart';
import 'package:wms/user/features/dashboard/services/customer_devices_service.dart';
import 'package:wms/user/features/valves/models/valve_setting_models.dart';

final valveSettingProvider = legacy.ChangeNotifierProvider.autoDispose
    .family<ValveSettingController, ValveSettingArgs>(
      (ref, args) => ValveSettingController(ref, args),
    );

class ValveSettingController extends ChangeNotifier {
  ValveSettingController(this.ref, this.args)
    : _state = ValveSettingState(
        valves: _buildValves(args.components),
        isLeaving: false,
        isLoadingComponents: args.components.isEmpty,
        isRefreshingComponents: false,
      ) {
    debugPrint(
      'VALVE_SETTING init: valves=${args.components.length}, firstValveComponentId='
      '${args.components.isNotEmpty ? args.components.first.componentId : 'n/a'}',
    );
    Future<void>.microtask(reloadDeviceComponents);
  }

  final Ref ref;
  final ValveSettingArgs args;
  ValveSettingState _state;

  ValveSettingState get state => _state;

  static List<ValveComponentModel> _buildValves(
    List<CustomerDeviceComponent> components,
  ) {
    final sortedComponents = List<CustomerDeviceComponent>.from(components)
      ..sort((left, right) => left.gpioPin.compareTo(right.gpioPin));

    return List<ValveComponentModel>.generate(sortedComponents.length, (index) {
      final component = sortedComponents[index];
      final currentState = component.currentState.trim().toUpperCase();
      return ValveComponentModel(
        valveLabel: component.installedArea.trim().isEmpty
            ? 'Valve ${index + 1}'
            : component.installedArea,
        componentName: component.displayName,
        componentId: component.componentId,
        isActive: component.active,
        isExpanded: false,
        manualActionOn: currentState == 'ON',
        isLoadingSchedules: false,
        hasLoadedSchedules: false,
        schedules: <ScheduleCardModel>[ScheduleCardModel.createDraft()],
        lastUpdated: component.stateChangedAt ?? DateTime.now(),
      );
    });
  }

  void markLeaving() {
    _state = _state.copyWith(isLeaving: true);
    notifyListeners();
  }

  Future<void> toggleExpanded(int valveIndex) async {
    final shouldExpand = !_state.valves[valveIndex].isExpanded;
    debugPrint(
      'VALVE_SETTING toggleExpanded: valveIndex=$valveIndex, '
      'shouldExpand=$shouldExpand, componentId=${_state.valves[valveIndex].componentId}',
    );
    _state = _state.copyWith(
      valves: List<ValveComponentModel>.generate(_state.valves.length, (index) {
        final current = _state.valves[index];
        if (index == valveIndex) {
          return current.copyWith(isExpanded: !current.isExpanded);
        }
        return current.copyWith(isExpanded: false);
      }),
    );
    notifyListeners();

    if (shouldExpand) {
      await _ensureSchedulesLoaded(
        valveIndex,
        showLoader: true,
        showErrors: false,
      );
    }
  }

  void toggleDay(int valveIndex, int scheduleIndex, int day) {
    final schedule = _state.valves[valveIndex].schedules[scheduleIndex];
    final nextDays = Set<int>.from(schedule.selectedDays);
    if (!nextDays.add(day)) {
      nextDays.remove(day);
    }
    _updateSchedule(
      valveIndex,
      scheduleIndex,
      (item) => item.copyWith(selectedDays: nextDays),
    );
  }

  void toggleAllDays(int valveIndex, int scheduleIndex) {
    final schedule = _state.valves[valveIndex].schedules[scheduleIndex];
    final nextDays = schedule.selectedDays.length == 7
        ? <int>{}
        : dayChips.map((item) => item.apiDay).toSet();
    _updateSchedule(
      valveIndex,
      scheduleIndex,
      (item) => item.copyWith(selectedDays: nextDays),
    );
  }

  void toggleScheduleExpanded(int valveIndex, int scheduleIndex) {
    final valve = _state.valves[valveIndex];
    final nextSchedules = List<ScheduleCardModel>.generate(
      valve.schedules.length,
      (index) {
        final current = valve.schedules[index];
        return current.copyWith(
          isExpanded: index == scheduleIndex ? !current.isExpanded : false,
        );
      },
    );
    _updateValve(valveIndex, (item) => item.copyWith(schedules: nextSchedules));
  }

  void updateScheduleTime(
    int valveIndex,
    int scheduleIndex, {
    required bool isStart,
    required TimeOfDay value,
  }) {
    _updateSchedule(
      valveIndex,
      scheduleIndex,
      (item) => isStart
          ? item.copyWith(fromTime: value)
          : item.copyWith(toTime: value),
    );
  }

  Future<String?> setManualToggleAndTrigger(
    int valveIndex,
    bool value, {
    required int duration,
  }) async {
    _updateValve(valveIndex, (item) => item.copyWith(manualActionOn: value));

    final action = value ? 'ON' : 'OFF';
    try {
      final componentId = _state.valves[valveIndex].componentId.trim();
      if (componentId.isEmpty) {
        throw const ApiException('Component ID missing for this valve.');
      }
      final token = await _resolveToken();
      if (token.isEmpty) {
        throw const ApiException('Session expired. Please login again.');
      }
      await ref
          .read(customerManualTriggerControllerProvider.notifier)
          .trigger(
            componentId: componentId,
            action: action,
            duration: value ? duration : null,
          );
      return null;
    } catch (error) {
      _updateValve(valveIndex, (item) => item.copyWith(manualActionOn: !value));
      return error.toString();
    }
  }

  Future<String?> validateManualToggleOn(int valveIndex) async {
    try {
      await _ensureSchedulesLoaded(
        valveIndex,
        showLoader: false,
        showErrors: true,
      );
    } catch (error) {
      return error.toString();
    }

    final valve = _state.valves[valveIndex];
    if (hasRunningScheduleNow(valve)) {
      return 'A schedule is already running for the current day and time.';
    }
    return null;
  }

  Future<String?> submitSchedule(
    int valveIndex,
    int scheduleIndex, {
    required bool addAnotherCard,
  }) async {
    final valve = _state.valves[valveIndex];
    final schedule = valve.schedules[scheduleIndex];
    final validationError = scheduleValidationMessage(
      valve: valve,
      scheduleIndex: scheduleIndex,
    );
    if (validationError != null) {
      return validationError;
    }

    final componentId = valve.componentId.trim();
    if (componentId.isEmpty) {
      return 'Component ID missing for this valve.';
    }

    _updateSchedule(
      valveIndex,
      scheduleIndex,
      (item) => item.copyWith(isSubmitting: true),
    );

    try {
      final token = await _resolveToken();
      if (token.isEmpty) {
        throw const ApiException('Session expired. Please login again.');
      }

      final request = CustomerComponentScheduleRequest(
        days: schedule.selectedDays.toList()..sort(),
        startTime: scheduleTimeFrom(schedule.fromTime!),
        endTime: scheduleTimeFrom(schedule.toTime!),
        durationMins: durationInMinutes(schedule.fromTime!, schedule.toTime!),
        enabled: true,
      );

      if (schedule.persisted) {
        await ref
            .read(customerDevicesServiceProvider)
            .updateSchedule(
              bearerToken: token,
              componentId: componentId,
              scheduleId: schedule.scheduleId,
              request: request,
            );
      } else {
        await ref
            .read(customerDevicesServiceProvider)
            .createSchedule(
              bearerToken: token,
              componentId: componentId,
              request: request,
            );
      }

      await _refreshSchedules(valveIndex, showLoader: false, showErrors: false);

      final refreshedValve = _state.valves[valveIndex];
      if (addAnotherCard &&
          refreshedValve.schedules.length < 3 &&
          refreshedValve.schedules.every((item) => item.persisted)) {
        _updateValve(
          valveIndex,
          (item) => item.copyWith(
            schedules: <ScheduleCardModel>[
              ...item.schedules,
              ScheduleCardModel.createDraft(),
            ],
          ),
        );
      }
      return null;
    } catch (error) {
      _updateSchedule(
        valveIndex,
        scheduleIndex,
        (item) => item.copyWith(isSubmitting: false),
      );
      return error.toString();
    }
  }

  Future<String?> deleteSchedule(int valveIndex, int scheduleIndex) async {
    final valve = _state.valves[valveIndex];
    final schedule = valve.schedules[scheduleIndex];
    final componentId = valve.componentId.trim();
    if (componentId.isEmpty) {
      return 'Component ID missing for this valve.';
    }
    if (!schedule.persisted || schedule.scheduleId.trim().isEmpty) {
      return 'Schedule ID missing.';
    }

    _updateSchedule(
      valveIndex,
      scheduleIndex,
      (item) => item.copyWith(isSubmitting: true),
    );

    try {
      final token = await _resolveToken();
      if (token.isEmpty) {
        throw const ApiException('Session expired. Please login again.');
      }

      await ref
          .read(customerDevicesServiceProvider)
          .deleteSchedule(
            bearerToken: token,
            componentId: componentId,
            scheduleId: schedule.scheduleId,
          );

      await _refreshSchedules(valveIndex, showLoader: false, showErrors: false);
      return null;
    } catch (error) {
      _updateSchedule(
        valveIndex,
        scheduleIndex,
        (item) => item.copyWith(isSubmitting: false),
      );
      return error.toString();
    }
  }

  Future<String?> reloadDeviceComponents() async {
    final hadValves = _state.valves.isNotEmpty;
    _state = _state.copyWith(
      isLoadingComponents: !hadValves,
      isRefreshingComponents: hadValves,
    );
    notifyListeners();

    try {
      final token = await _resolveToken();
      if (token.isEmpty) {
        throw const ApiException('Session expired. Please login again.');
      }

      final components = await ref
          .read(customerDevicesServiceProvider)
          .getDeviceComponents(bearerToken: token, espId: args.espId);

      final valves = components
          .where((item) => item.type.trim().toUpperCase() == 'VALVE')
          .toList();

      _state = _state.copyWith(
        valves: _buildValves(valves),
        isLoadingComponents: false,
        isRefreshingComponents: false,
      );
      notifyListeners();
      unawaited(_preloadAllValveSchedules());
      return null;
    } catch (error) {
      debugPrint('VALVE_SETTING loadDeviceComponents:error $error');
      _state = _state.copyWith(
        isLoadingComponents: false,
        isRefreshingComponents: false,
        valves: hadValves ? _state.valves : const <ValveComponentModel>[],
      );
      notifyListeners();
      return error.toString();
    }
  }

  Future<void> _ensureSchedulesLoaded(
    int valveIndex, {
    required bool showLoader,
    required bool showErrors,
  }) async {
    final valve = _state.valves[valveIndex];
    debugPrint(
      'VALVE_SETTING ensureSchedulesLoaded: valveIndex=$valveIndex, '
      'componentId=${valve.componentId}, hasLoaded=${valve.hasLoadedSchedules}, '
      'isLoading=${valve.isLoadingSchedules}, showLoader=$showLoader',
    );
    if (valve.hasLoadedSchedules || valve.isLoadingSchedules) {
      debugPrint(
        'VALVE_SETTING ensureSchedulesLoaded: skipped valveIndex=$valveIndex',
      );
      return;
    }
    await _refreshSchedules(
      valveIndex,
      showLoader: showLoader,
      showErrors: showErrors,
    );
  }

  Future<void> _preloadAllValveSchedules() async {
    for (var valveIndex = 0; valveIndex < _state.valves.length; valveIndex++) {
      await _ensureSchedulesLoaded(
        valveIndex,
        showLoader: true,
        showErrors: false,
      );
    }
  }

  Future<void> _refreshSchedules(
    int valveIndex, {
    required bool showLoader,
    required bool showErrors,
  }) async {
    final valve = _state.valves[valveIndex];
    final componentId = valve.componentId.trim();
    debugPrint(
      'VALVE_SETTING refreshSchedules:start valveIndex=$valveIndex, '
      'componentId=$componentId, showLoader=$showLoader, showErrors=$showErrors',
    );
    if (componentId.isEmpty) {
      debugPrint(
        'VALVE_SETTING refreshSchedules: empty componentId for valveIndex=$valveIndex',
      );
      _updateValve(
        valveIndex,
        (item) => item.copyWith(
          isLoadingSchedules: false,
          hasLoadedSchedules: true,
          schedules: <ScheduleCardModel>[ScheduleCardModel.createDraft()],
        ),
      );
      return;
    }

    if (showLoader) {
      _updateValve(
        valveIndex,
        (item) => item.copyWith(isLoadingSchedules: true),
      );
    }

    try {
      final token = await _resolveToken();
      if (token.isEmpty) {
        throw const ApiException('Session expired. Please login again.');
      }
      debugPrint(
        'VALVE_SETTING refreshSchedules: token resolved for valveIndex=$valveIndex',
      );

      final schedules = await ref
          .read(customerDevicesServiceProvider)
          .getComponentSchedules(bearerToken: token, componentId: componentId);
      debugPrint(
        'VALVE_SETTING refreshSchedules: received ${schedules.length} schedules '
        'for valveIndex=$valveIndex, componentId=$componentId',
      );

      final nextCards = schedules
          .take(3)
          .map(ScheduleCardModel.fromRemote)
          .toList();
      if (nextCards.length < 3) {
        nextCards.add(ScheduleCardModel.createDraft());
      }

      _updateValve(
        valveIndex,
        (item) => item.copyWith(
          schedules: nextCards,
          isLoadingSchedules: false,
          hasLoadedSchedules: true,
          lastUpdated: DateTime.now(),
        ),
      );
    } catch (error) {
      debugPrint(
        'VALVE_SETTING refreshSchedules:error valveIndex=$valveIndex, '
        'componentId=$componentId, error=$error',
      );
      _updateValve(
        valveIndex,
        (item) => item.copyWith(
          isLoadingSchedules: false,
          hasLoadedSchedules: false,
          schedules: item.schedules.isEmpty
              ? <ScheduleCardModel>[ScheduleCardModel.createDraft()]
              : item.schedules,
        ),
      );
      if (showErrors) {
        rethrow;
      }
    }
  }

  Future<String> _resolveToken() async {
    final session = ref.read(currentAuthSessionProvider);
    var token = (session?.token ?? '').trim();
    debugPrint(
      'VALVE_SETTING resolveToken: sessionTokenPresent=${token.isNotEmpty}',
    );
    if (token.isEmpty) {
      final remembered = await ref
          .read(authLocalStorageProvider)
          .loadLoginData();
      token = (remembered?.token ?? '').trim();
      debugPrint(
        'VALVE_SETTING resolveToken: storageTokenPresent=${token.isNotEmpty}',
      );
    }
    debugPrint('VALVE_SETTING LOGIN TOKEN: $token');
    return token;
  }

  void _updateValve(
    int index,
    ValveComponentModel Function(ValveComponentModel item) update,
  ) {
    final nextValves = List<ValveComponentModel>.from(_state.valves);
    nextValves[index] = update(nextValves[index]);
    _state = _state.copyWith(valves: nextValves);
    notifyListeners();
  }

  void _updateSchedule(
    int valveIndex,
    int scheduleIndex,
    ScheduleCardModel Function(ScheduleCardModel item) update,
  ) {
    _updateValve(
      valveIndex,
      (valve) => valve.updateSchedule(scheduleIndex, update),
    );
  }
}
