import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wms/shared/shared.dart';
import 'package:wms/user/features/dashboard/providers/user_profile_providers.dart';
import 'package:wms/user/features/dashboard/screens/valve_setting_controller.dart';
import 'package:wms/user/features/dashboard/screens/valve_setting_dialogs.dart';
import 'package:wms/user/features/dashboard/screens/valve_setting_models.dart';
import 'package:wms/user/features/dashboard/screens/valve_setting_widgets.dart';
import 'package:wms/user/features/dashboard/services/customer_devices_service.dart';
import 'package:wms/user/features/dashboard/services/user_profile_service.dart';

class ValveSettingScreen extends ConsumerWidget {
  const ValveSettingScreen({required this.device, super.key});

  final CustomerDeviceSummary device;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final args = ValveSettingArgs.fromDevice(device);
    return _ValveSettingView(device: device, args: args);
  }
}

class _ValveSettingView extends ConsumerWidget {
  const _ValveSettingView({required this.device, required this.args});

  final CustomerDeviceSummary device;
  final ValveSettingArgs args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(valveSettingProvider(args));
    final state = controller.state;
    final profileState = ref.watch(userProfileProvider);
    final access = _resolveAccess(profileState: profileState);

    return PopScope(
      canPop: !state.isLeaving,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop || state.isLeaving) {
          return;
        }
        controller.markLeaving();
        if (context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.white,
        appBar: AppBar(
          title: const Text('Valve Setting'),
          backgroundColor: AppColors.white,
          surfaceTintColor: AppColors.white,
          elevation: 2,
          shadowColor: const Color(0x26000000),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (var index = 0; index < state.valves.length; index++) ...[
              ValveSettingValveCard(
                valve: state.valves[index],
                canControlValves: access.canControlValves,
                onToggleExpanded: () =>
                    ref.read(valveSettingProvider(args)).toggleExpanded(index),
                onToggleActive: (value) =>
                    ref.read(valveSettingProvider(args)).toggleActive(index, value),
                onToggleManual: (value) async {
                  final notifier = ref.read(valveSettingProvider(args));
                  int? duration;
                  if (value) {
                    duration = await showManualDurationDialog(context);
                    if (duration == null || !context.mounted) {
                      return;
                    }
                  }
                  final error = await notifier.setManualToggleAndTrigger(
                    index,
                    value,
                    duration: duration ?? 0,
                  );
                  if (error != null && context.mounted) {
                    showValveSettingSnackBar(context, error);
                  }
                },
                scheduleChildren: [
                  for (
                    var scheduleIndex = 0;
                    scheduleIndex < state.valves[index].schedules.length;
                    scheduleIndex++
                  ) ...[
                    _buildScheduleCard(
                      context: context,
                      ref: ref,
                      valveIndex: index,
                      scheduleIndex: scheduleIndex,
                      valve: state.valves[index],
                      access: access,
                    ),
                    if (scheduleIndex < state.valves[index].schedules.length - 1)
                      const SizedBox(height: 12),
                  ],
                ],
              ),
              if (index < state.valves.length - 1) const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleCard({
    required BuildContext context,
    required WidgetRef ref,
    required int valveIndex,
    required int scheduleIndex,
    required ValveComponentModel valve,
    required _ValveSettingAccess access,
  }) {
    final notifier = ref.read(valveSettingProvider(args));
    final schedule = valve.schedules[scheduleIndex];
    final isAllSelected = schedule.selectedDays.length == 7;
    final canEditSchedule = schedule.persisted
        ? access.canUpdateSchedules
        : access.canCreateSchedules;
    final validationMessage = _scheduleValidationMessage(
      valve: valve,
      scheduleIndex: scheduleIndex,
    );
    final canSave = canEditSchedule && _canSaveSchedule(valve, scheduleIndex);
    final canAddSchedule =
        access.canCreateSchedules && _canAddSchedule(valve, scheduleIndex);

    return ValveSettingScheduleCard(
      contextForTimeFormat: context,
      schedule: schedule,
      scheduleIndex: scheduleIndex,
      isAllSelected: isAllSelected,
      canEditSchedule: canEditSchedule,
      canDeleteSchedule: access.canDeleteSchedules,
      validationMessage: validationMessage,
      canSave: canSave,
      canAddSchedule: canAddSchedule,
      onToggleExpanded: () =>
          notifier.toggleScheduleExpanded(valveIndex, scheduleIndex),
      onToggleAllDays: () =>
          notifier.toggleAllDays(valveIndex, scheduleIndex),
      onToggleDay: (day) => notifier.toggleDay(valveIndex, scheduleIndex, day),
      onPickFromTime: () async {
        final picked = await pickValveScheduleTime(
          context: context,
          initial: schedule.fromTime ?? const TimeOfDay(hour: 8, minute: 0),
        );
        if (picked != null) {
          notifier.updateScheduleTime(
            valveIndex,
            scheduleIndex,
            isStart: true,
            value: picked,
          );
        }
      },
      onPickToTime: () async {
        final picked = await pickValveScheduleTime(
          context: context,
          initial: schedule.toTime ?? const TimeOfDay(hour: 9, minute: 0),
        );
        if (picked != null) {
          notifier.updateScheduleTime(
            valveIndex,
            scheduleIndex,
            isStart: false,
            value: picked,
          );
        }
      },
      onDelete: () async {
        final confirmed = await confirmValveScheduleDelete(context);
        if (confirmed != true || !context.mounted) {
          return;
        }
        final error = await notifier.deleteSchedule(valveIndex, scheduleIndex);
        if (error != null && context.mounted) {
          showValveSettingSnackBar(context, error);
          return;
        }
        if (context.mounted) {
          showValveSettingSnackBar(context, 'Schedule deleted.');
        }
      },
      onAddSchedule: () async {
        final error = await notifier.submitSchedule(
          valveIndex,
          scheduleIndex,
          addAnotherCard: true,
        );
        if (error != null && context.mounted) {
          showValveSettingSnackBar(context, error);
          return;
        }
        if (context.mounted) {
          showValveSettingSnackBar(context, 'Schedule added successfully.');
        }
      },
      onSave: () async {
        final error = await notifier.submitSchedule(
          valveIndex,
          scheduleIndex,
          addAnotherCard: false,
        );
        if (error != null && context.mounted) {
          showValveSettingSnackBar(context, error);
          return;
        }
        if (context.mounted) {
          showValveSettingSnackBar(
            context,
            schedule.persisted ? 'Schedule updated.' : 'Schedule saved.',
          );
        }
      },
    );
  }

  bool _canAddSchedule(ValveComponentModel valve, int scheduleIndex) {
    final schedule = valve.schedules[scheduleIndex];
    if (schedule.isSubmitting || valve.componentId.trim().isEmpty) {
      return false;
    }
    if (scheduleIndex != valve.schedules.length - 1 || schedule.persisted) {
      return false;
    }
    if (valve.schedules.length >= 3) {
      return false;
    }
    return _scheduleValidationMessage(
          valve: valve,
          scheduleIndex: scheduleIndex,
        ) ==
        null;
  }

  bool _canSaveSchedule(ValveComponentModel valve, int scheduleIndex) {
    final schedule = valve.schedules[scheduleIndex];
    if (schedule.isSubmitting || valve.componentId.trim().isEmpty) {
      return false;
    }
    if (_scheduleValidationMessage(
          valve: valve,
          scheduleIndex: scheduleIndex,
        ) !=
        null) {
      return false;
    }
    return schedule.hasChanges;
  }

  String? _scheduleValidationMessage({
    required ValveComponentModel valve,
    required int scheduleIndex,
  }) {
    return scheduleValidationMessage(
      valve: valve,
      scheduleIndex: scheduleIndex,
    );
  }
}

class _ValveSettingAccess {
  const _ValveSettingAccess({
    required this.canControlValves,
    required this.canCreateSchedules,
    required this.canUpdateSchedules,
    required this.canDeleteSchedules,
  });

  final bool canControlValves;
  final bool canCreateSchedules;
  final bool canUpdateSchedules;
  final bool canDeleteSchedules;

  factory _ValveSettingAccess.full() {
    return const _ValveSettingAccess(
      canControlValves: true,
      canCreateSchedules: true,
      canUpdateSchedules: true,
      canDeleteSchedules: true,
    );
  }

  factory _ValveSettingAccess.none() {
    return const _ValveSettingAccess(
      canControlValves: false,
      canCreateSchedules: false,
      canUpdateSchedules: false,
      canDeleteSchedules: false,
    );
  }
}

_ValveSettingAccess _resolveAccess({
  required AsyncValue<UserProfile> profileState,
}) {
  return profileState.maybeWhen(
    data: (profile) {
      if (profile.isAdmin) {
        return _ValveSettingAccess.full();
      }
      return _ValveSettingAccess(
        canControlValves: profile.permissions.canControlValves,
        canCreateSchedules: profile.permissions.canCreateSchedules,
        canUpdateSchedules: profile.permissions.canUpdateSchedules,
        canDeleteSchedules: profile.permissions.canDeleteSchedules,
      );
    },
    orElse: _ValveSettingAccess.none,
  );
}
