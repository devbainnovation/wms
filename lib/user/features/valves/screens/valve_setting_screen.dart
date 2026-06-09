import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wms/shared/shared.dart';
import 'package:wms/user/features/dashboard/providers/user_profile_providers.dart';
import 'package:wms/user/features/dashboard/services/customer_devices_service.dart';
import 'package:wms/user/features/dashboard/services/user_profile_service.dart';
import 'package:wms/user/features/valves/models/valve_setting_models.dart';
import 'package:wms/user/features/valves/providers/valve_setting_controller.dart';
import 'package:wms/user/features/valves/screens/valve_schedule_editor_screen.dart';
import 'package:wms/user/features/valves/screens/valve_setting_dialogs.dart';
import 'package:wms/user/features/valves/widgets/valve_setting_widgets.dart';

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
          actions: [
            IconButton(
              tooltip: 'Refresh',
              onPressed:
                  state.isLoadingComponents || state.isRefreshingComponents
                  ? null
                  : () async {
                      final error = await ref
                          .read(valveSettingProvider(args))
                          .reloadDeviceComponents();
                      if (error != null && context.mounted) {
                        showValveSettingSnackBar(context, error);
                      }
                    },
              icon: state.isRefreshingComponents
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.accentGreen,
                      ),
                    )
                  : const Icon(
                      Icons.refresh_rounded,
                      color: AppColors.accentGreen,
                    ),
            ),
          ],
        ),
        body: AppPageBody(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (state.isLoadingComponents)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryTeal,
                    ),
                  ),
                )
              else if (state.valves.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.lightGreyText),
                  ),
                  child: const Text(
                    'No data found.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.greyText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              else
                for (var index = 0; index < state.valves.length; index++) ...[
                  ValveSettingValveCard(
                    valve: state.valves[index],
                    canControlValves: access.canControlValves,
                    onToggleExpanded: () => ref
                        .read(valveSettingProvider(args))
                        .toggleExpanded(index),
                    onToggleManual: (value) async {
                      if (!device.isOnline) {
                        showAppSnackBar(
                          context,
                          'Device is offline.',
                          status: AppSnackBarStatus.error,
                        );
                        return;
                      }

                      final notifier = ref.read(valveSettingProvider(args));
                      int? duration;
                      if (value) {
                        final validationError = await notifier
                            .validateManualToggleOn(index);
                        if (!context.mounted) {
                          return;
                        }
                        if (validationError != null) {
                          if (validationError ==
                              'A schedule is already running for the current day and time.') {
                            await showManualScheduleRunningDialog(context);
                          } else {
                            showValveSettingSnackBar(context, validationError);
                          }
                          return;
                        }
                        duration = await showManualDurationDialog(context);
                        if (duration == null || !context.mounted) {
                          return;
                        }
                      } else {
                        final confirmed = await confirmManualActionDialog(
                          context: context,
                          title: 'Turn off valve?',
                          message:
                              'This action will stop the valve immediately.',
                        );
                        if (confirmed != true || !context.mounted) {
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
                      ..._buildSavedScheduleCards(
                        context: context,
                        ref: ref,
                        valveIndex: index,
                        valve: state.valves[index],
                        access: access,
                      ),
                      if (state.valves[index].savedScheduleCount > 0)
                        const SizedBox(height: 12),
                      if (state.valves[index].savedScheduleCount < 3 &&
                          access.canCreateSchedules)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: SizedBox(
                            width: double.infinity,
                            height: 44,
                            child: FilledButton.icon(
                              onPressed: () {
                                final newSchedule =
                                    ScheduleCardModel.createDraft();
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => ValveScheduleEditorScreen(
                                      valveLabel:
                                          state.valves[index].valveLabel,
                                      schedule: newSchedule,
                                      canEditSchedule: true,
                                      canDeleteSchedule: false,
                                      onSave: (updatedSchedule) async {
                                        final notifier = ref.read(
                                          valveSettingProvider(args),
                                        );
                                        final newScheduleIndex = state
                                            .valves[index]
                                            .schedules
                                            .length;
                                        notifier.toggleScheduleExpanded(
                                          index,
                                          newScheduleIndex,
                                        );
                                        await Future.delayed(
                                          const Duration(milliseconds: 100),
                                        );

                                        if (updatedSchedule.fromTime != null) {
                                          notifier.updateScheduleTime(
                                            index,
                                            newScheduleIndex,
                                            isStart: true,
                                            value: updatedSchedule.fromTime!,
                                          );
                                        }
                                        if (updatedSchedule.toTime != null) {
                                          notifier.updateScheduleTime(
                                            index,
                                            newScheduleIndex,
                                            isStart: false,
                                            value: updatedSchedule.toTime!,
                                          );
                                        }

                                        for (var day = 1; day <= 7; day++) {
                                          if (updatedSchedule.selectedDays
                                              .contains(day)) {
                                            notifier.toggleDay(
                                              index,
                                              newScheduleIndex,
                                              day,
                                            );
                                          }
                                        }

                                        final error = await notifier
                                            .submitSchedule(
                                              index,
                                              newScheduleIndex,
                                              addAnotherCard: false,
                                            );
                                        if (error == null && context.mounted) {
                                          showValveSettingSnackBar(
                                            context,
                                            'Schedule saved.',
                                          );
                                          Navigator.of(context).pop();
                                        }
                                        return error;
                                      },
                                      onDelete: null,
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.add_rounded, size: 18),
                              label: const Text('Add Schedule'),
                              style: FilledButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (index < state.valves.length - 1)
                    const SizedBox(height: 12),
                ],
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildSavedScheduleCards({
    required BuildContext context,
    required WidgetRef ref,
    required int valveIndex,
    required ValveComponentModel valve,
    required _ValveSettingAccess access,
  }) {
    final savedSchedules = valve.schedules.where((s) => s.persisted).toList();
    final widgets = <Widget>[];

    for (var i = 0; i < savedSchedules.length; i++) {
      final schedule = savedSchedules[i];
      final scheduleIndex = valve.schedules.indexOf(schedule);

      widgets.add(
        _buildScheduleCard(
          context: context,
          ref: ref,
          valveIndex: valveIndex,
          scheduleIndex: scheduleIndex,
          valve: valve,
          access: access,
        ),
      );

      if (i < savedSchedules.length - 1) {
        widgets.add(const SizedBox(height: 12));
      }
    }

    return widgets;
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
    final canEditSchedule = schedule.persisted
        ? access.canUpdateSchedules
        : access.canCreateSchedules;

    return ValveSettingScheduleCard(
      schedule: schedule,
      scheduleIndex: scheduleIndex,
      canEditSchedule: canEditSchedule,
      canDeleteSchedule: access.canDeleteSchedules && schedule.persisted,
      onOpenEditor: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ValveScheduleEditorScreen(
            valveLabel: valve.valveLabel,
            schedule: schedule,
            canEditSchedule: canEditSchedule,
            canDeleteSchedule: access.canDeleteSchedules,
            onSave: (updatedSchedule) async {
              if (updatedSchedule.fromTime != null &&
                  updatedSchedule.fromTime != schedule.fromTime) {
                notifier.updateScheduleTime(
                  valveIndex,
                  scheduleIndex,
                  isStart: true,
                  value: updatedSchedule.fromTime!,
                );
              }
              if (updatedSchedule.toTime != null &&
                  updatedSchedule.toTime != schedule.toTime) {
                notifier.updateScheduleTime(
                  valveIndex,
                  scheduleIndex,
                  isStart: false,
                  value: updatedSchedule.toTime!,
                );
              }

              final currentDays = schedule.selectedDays;
              final nextDays = updatedSchedule.selectedDays;
              for (var day = 1; day <= 7; day++) {
                final isCurrentlySelected = currentDays.contains(day);
                final shouldBeSelected = nextDays.contains(day);
                if (isCurrentlySelected != shouldBeSelected) {
                  notifier.toggleDay(valveIndex, scheduleIndex, day);
                }
              }

              final error = await notifier.submitSchedule(
                valveIndex,
                scheduleIndex,
                addAnotherCard: !schedule.persisted,
              );
              if (error == null && context.mounted) {
                showValveSettingSnackBar(
                  context,
                  schedule.persisted ? 'Schedule updated.' : 'Schedule saved.',
                );
              }
              return error;
            },
            onDelete: schedule.persisted
                ? () async {
                    if (hasRunningScheduleNow(valve)) {
                      return "This schedule can't be deleted while the valve is running. Please stop the valve and try again.";
                    }
                    final confirmed = await confirmValveScheduleDelete(context);
                    if (confirmed != true || !context.mounted) {
                      return '__cancelled__';
                    }
                    final error = await notifier.deleteSchedule(
                      valveIndex,
                      scheduleIndex,
                    );
                    if (error == null && context.mounted) {
                      showValveSettingSnackBar(context, 'Schedule deleted.');
                    }
                    return error;
                  }
                : null,
          ),
        ),
      ),
      onDelete: () async {
        if (hasRunningScheduleNow(valve)) {
          showValveSettingSnackBar(
            context,
            "This schedule can't be deleted while the valve is running. Please stop the valve and try again.",
          );
          return;
        }
        final confirmed = await confirmValveScheduleDelete(context);
        if (confirmed != true || !context.mounted) {
          return;
        }
        await notifier.deleteSchedule(valveIndex, scheduleIndex);
        if (context.mounted) {
          showValveSettingSnackBar(context, 'Schedule deleted.');
        }
      },
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
