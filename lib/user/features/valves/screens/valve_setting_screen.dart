import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wms/shared/shared.dart';
import 'package:wms/user/features/dashboard/dashboard.dart';
import 'package:wms/user/features/valves/valves.dart';

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
        appBar: _buildAppBar(context, ref, state),
        body: AppPageBody(
          child: state.isLoadingComponents
              ? const _LoadingView()
              : state.valves.isEmpty
                  ? const _EmptyValvesView()
                  : _ValvesListView(
                      device: device,
                      args: args,
                      state: state,
                      access: access,
                    ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    WidgetRef ref,
    ValveSettingState state,
  ) {
    return AppBar(
      title: const Text('Valve Setting'),
      backgroundColor: AppColors.white,
      surfaceTintColor: AppColors.white,
      elevation: 2,
      shadowColor: const Color(0x26000000),
      actions: [
        IconButton(
          tooltip: 'Refresh',
          onPressed: state.isLoadingComponents || state.isRefreshingComponents
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
              ? const _RefreshingIcon()
              : const Icon(Icons.refresh_rounded, color: AppColors.accentGreen),
        ),
      ],
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: CircularProgressIndicator(color: AppColors.primaryTeal),
      ),
    );
  }
}

class _EmptyValvesView extends StatelessWidget {
  const _EmptyValvesView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.lightGreyText),
            boxShadow: const [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.inbox_rounded, size: 48, color: AppColors.lightGreyText),
              SizedBox(height: 16),
              Text(
                'No valves found for this device.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.greyText,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ValvesListView extends ConsumerWidget {
  const _ValvesListView({
    required this.device,
    required this.args,
    required this.state,
    required this.access,
  });

  final CustomerDeviceSummary device;
  final ValveSettingArgs args;
  final ValveSettingState state;
  final _ValveSettingAccess access;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(userProfileProvider);
    final isAdmin = profileState.maybeWhen(
      data: (profile) => profile.isAdmin,
      orElse: () => false,
    );

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: state.valves.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final valve = state.valves[index];
        return ValveSettingValveCard(
          valve: valve,
          canControlValves: access.canControlValves,
          onToggleExpanded: () =>
              ref.read(valveSettingProvider(args)).toggleExpanded(index),
          onToggleManual: (value) => _handleManualToggle(
            context,
            ref,
            index,
            value,
            valve,
          ),
          onRename: isAdmin
              ? () => _handleRename(context, ref, index, valve.valveLabel)
              : null,
          scheduleChildren: [
            _SavedSchedulesList(
              args: args,
              valveIndex: index,
              valve: valve,
              access: access,
            ),
            if (valve.savedScheduleCount < 3 && access.canCreateSchedules)
              _AddScheduleButton(
                args: args,
                valveIndex: index,
                valve: valve,
              ),
          ],
        );
      },
    );
  }

  Future<void> _handleRename(
    BuildContext context,
    WidgetRef ref,
    int index,
    String currentName,
  ) async {
    final newName = await showRenameComponentDialog(
      context: context,
      currentName: currentName,
    );

    if (newName == null || newName == currentName || !context.mounted) {
      return;
    }

    final error = await ref
        .read(valveSettingProvider(args))
        .renameValve(index, newName);

    if (!context.mounted) return;

    if (error != null) {
      showValveSettingSnackBar(context, error);
    } else {
      showValveSettingSnackBar(context, 'Valve renamed successfully.');
    }
  }

  Future<void> _handleManualToggle(
    BuildContext context,
    WidgetRef ref,
    int index,
    bool value,
    ValveComponentModel valve,
  ) async {
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
      final validationError = await notifier.validateManualToggleOn(index);
      if (!context.mounted) {
        return;
      }
      if (validationError != null) {
        if (validationError ==
            'A schedule is already running for the current day and time.') {
          final startAnyway = await showManualScheduleRunningDialog(context);
          if (startAnyway != true || !context.mounted) {
            return;
          }
        } else {
          showValveSettingSnackBar(context, validationError);
          return;
        }
      }
      duration = await showManualDurationDialog(context);
      if (duration == null || !context.mounted) {
        return;
      }
    } else {
      final confirmed = await confirmManualActionDialog(
        context: context,
        title: 'Turn off valve?',
        message: 'This action will stop the valve immediately.',
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
  }
}

class _SavedSchedulesList extends ConsumerWidget {
  const _SavedSchedulesList({
    required this.args,
    required this.valveIndex,
    required this.valve,
    required this.access,
  });

  final ValveSettingArgs args;
  final int valveIndex;
  final ValveComponentModel valve;
  final _ValveSettingAccess access;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedSchedules = valve.schedules.where((s) => s.persisted).toList();
    if (savedSchedules.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        for (var i = 0; i < savedSchedules.length; i++) ...[
          _ScheduleCardWrapper(
            args: args,
            valveIndex: valveIndex,
            scheduleIndex: valve.schedules.indexOf(savedSchedules[i]),
            valve: valve,
            access: access,
          ),
          if (i < savedSchedules.length - 1) const SizedBox(height: 12),
        ],
        const SizedBox(height: 12),
      ],
    );
  }
}

class _ScheduleCardWrapper extends ConsumerWidget {
  const _ScheduleCardWrapper({
    required this.args,
    required this.valveIndex,
    required this.scheduleIndex,
    required this.valve,
    required this.access,
  });

  final ValveSettingArgs args;
  final int valveIndex;
  final int scheduleIndex;
  final ValveComponentModel valve;
  final _ValveSettingAccess access;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schedule = valve.schedules[scheduleIndex];
    final canEditSchedule = schedule.persisted
        ? access.canUpdateSchedules
        : access.canCreateSchedules;

    return ValveSettingScheduleCard(
      schedule: schedule,
      scheduleIndex: scheduleIndex,
      canEditSchedule: canEditSchedule,
      canDeleteSchedule: access.canDeleteSchedules && schedule.persisted,
      onOpenEditor: () => _openEditor(context, ref, schedule, canEditSchedule),
      onDelete: () => _handleDelete(context, ref),
    );
  }

  void _openEditor(
    BuildContext context,
    WidgetRef ref,
    ScheduleCardModel schedule,
    bool canEdit,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ValveScheduleEditorScreen(
          valveLabel: valve.valveLabel,
          schedule: schedule,
          canEditSchedule: canEdit,
          canDeleteSchedule: access.canDeleteSchedules,
          onSave: (updated) async {
            final error = await ref
                .read(valveSettingProvider(args))
                .saveScheduleFromEditor(
                  valveIndex: valveIndex,
                  scheduleIndex: scheduleIndex,
                  updated: updated,
                );
            if (error == null && context.mounted) {
              showValveSettingSnackBar(context, 'Schedule updated.');
            }
            return error;
          },
          onDelete: schedule.persisted ? () => _handleDelete(context, ref) : null,
        ),
      ),
    );
  }

  Future<String?> _handleDelete(BuildContext context, WidgetRef ref) async {
    if (valve.hasRunningScheduleNow) {
      final msg =
          "This schedule can't be deleted while the valve is running. Please stop the valve and try again.";
      if (context.mounted) showValveSettingSnackBar(context, msg);
      return msg;
    }

    final confirmed = await confirmValveScheduleDelete(context);
    if (confirmed != true) return '__cancelled__';

    final error = await ref
        .read(valveSettingProvider(args))
        .deleteSchedule(valveIndex, scheduleIndex);

    if (error == null && context.mounted) {
      showValveSettingSnackBar(context, 'Schedule deleted.');
    }
    return error;
  }
}

class _AddScheduleButton extends ConsumerWidget {
  const _AddScheduleButton({
    required this.args,
    required this.valveIndex,
    required this.valve,
  });

  final ValveSettingArgs args;
  final int valveIndex;
  final ValveComponentModel valve;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: SizedBox(
        width: double.infinity,
        height: 44,
        child: FilledButton.icon(
          onPressed: () => _openEditor(context, ref),
          icon: const Icon(Icons.add_rounded, size: 22),
          label: const Text('Add Schedule'),
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  void _openEditor(BuildContext context, WidgetRef ref) {
    final newSchedule = ScheduleCardModel.createDraft();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ValveScheduleEditorScreen(
          valveLabel: valve.valveLabel,
          schedule: newSchedule,
          canEditSchedule: true,
          canDeleteSchedule: false,
          onSave: (updated) async {
            final notifier = ref.read(valveSettingProvider(args));
            final currentValves = notifier.state.valves;
            if (valveIndex >= currentValves.length) return 'Valve not found.';
            
            final schedules = currentValves[valveIndex].schedules;
            final draftIndex = schedules.indexWhere((s) => !s.persisted);

            if (draftIndex == -1) {
              return 'Maximum schedules reached or draft slot missing.';
            }

            final error = await notifier.saveScheduleFromEditor(
              valveIndex: valveIndex,
              scheduleIndex: draftIndex,
              updated: updated,
            );

            if (error == null && context.mounted) {
              showValveSettingSnackBar(context, 'Schedule saved.');
            }
            return error;
          },
          onDelete: null,
        ),
      ),
    );
  }
}

class _RefreshingIcon extends StatelessWidget {
  const _RefreshingIcon();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 20,
      height: 20,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: AppColors.accentGreen,
      ),
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
