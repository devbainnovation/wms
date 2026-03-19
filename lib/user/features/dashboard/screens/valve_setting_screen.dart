import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart' as legacy;
import 'package:wms/core/core.dart';
import 'package:wms/shared/shared.dart';
import 'package:wms/user/features/dashboard/providers/providers.dart';
import 'package:wms/user/features/dashboard/services/customer_devices_service.dart';

class ValveSettingScreen extends ConsumerWidget {
  const ValveSettingScreen({required this.device, super.key});

  final CustomerDeviceSummary device;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final args = _ValveSettingArgs.fromDevice(device);
    return _ValveSettingView(device: device, args: args);
  }
}

class _ValveSettingView extends ConsumerWidget {
  const _ValveSettingView({required this.device, required this.args});

  final CustomerDeviceSummary device;
  final _ValveSettingArgs args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(_valveSettingProvider(args));
    final state = controller.state;

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
              _buildValveCard(
                context: context,
                ref: ref,
                valveIndex: index,
                valve: state.valves[index],
              ),
              if (index < state.valves.length - 1) const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildValveCard({
    required BuildContext context,
    required WidgetRef ref,
    required int valveIndex,
    required _ValveComponentModel valve,
  }) {
    final notifier = ref.read(_valveSettingProvider(args));

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.lightGreyText),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => notifier.toggleExpanded(valveIndex),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          valve.valveLabel,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.darkText,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Active',
                            style: TextStyle(
                              color: AppColors.darkText,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Transform.scale(
                            scale: 0.78,
                            child: Switch(
                              value: valve.isActive,
                              activeThumbColor: AppColors.accentGreen,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              onChanged: (value) =>
                                  notifier.toggleActive(valveIndex, value),
                            ),
                          ),
                          Icon(
                            valve.isExpanded
                                ? Icons.expand_less_rounded
                                : Icons.expand_more_rounded,
                            color: AppColors.greyText,
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (valve.componentName.trim().isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      valve.componentName,
                      style: const TextStyle(
                        color: AppColors.greyText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(
                              Icons.schedule_rounded,
                              size: 14,
                              color: AppColors.greyText,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                AppDateTimeFormatter.formatDateTime(
                                  valve.lastUpdated,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.greyText,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (valve.componentId.trim().isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Manual',
                              style: TextStyle(
                                color: AppColors.darkText,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Transform.scale(
                              scale: 0.78,
                              child: Switch(
                                value: valve.manualActionOn,
                                activeThumbColor: AppColors.accentGreen,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                onChanged: (value) async {
                                  int? duration;
                                  if (value) {
                                    duration = await _showManualDurationDialog(
                                      context,
                                    );
                                    if (duration == null || !context.mounted) {
                                      return;
                                    }
                                  }
                                  final error = await notifier
                                      .setManualToggleAndTrigger(
                                        valveIndex,
                                        value,
                                        duration: duration ?? 0,
                                      );
                                  if (error != null && context.mounted) {
                                    _showSnackBar(context, error);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (valve.isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: 14),
                  if (valve.isLoadingSchedules)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primaryTeal,
                        ),
                      ),
                    )
                  else
                    Column(
                      children: [
                        for (var index = 0; index < valve.schedules.length; index++) ...[
                          _buildScheduleCard(
                            context: context,
                            ref: ref,
                            valveIndex: valveIndex,
                            scheduleIndex: index,
                            valve: valve,
                          ),
                          if (index < valve.schedules.length - 1)
                            const SizedBox(height: 12),
                        ],
                      ],
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildScheduleCard({
    required BuildContext context,
    required WidgetRef ref,
    required int valveIndex,
    required int scheduleIndex,
    required _ValveComponentModel valve,
  }) {
    final notifier = ref.read(_valveSettingProvider(args));
    final schedule = valve.schedules[scheduleIndex];
    final isAllSelected = schedule.selectedDays.length == 7;
    final validationMessage = _scheduleValidationMessage(
      valve: valve,
      scheduleIndex: scheduleIndex,
    );
    final canSave = _canSaveSchedule(valve, scheduleIndex);
    final canAddSchedule = _canAddSchedule(valve, scheduleIndex);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.lightBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.lightGreyText),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F111827),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => notifier.toggleScheduleExpanded(valveIndex, scheduleIndex),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Text(
                    'Schedule ${scheduleIndex + 1}',
                    style: const TextStyle(
                      color: AppColors.darkText,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (schedule.persisted)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.lightGreen,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'Saved',
                        style: TextStyle(
                          color: AppColors.darkTeal,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  const Spacer(),
                  Icon(
                    schedule.isExpanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color: AppColors.greyText,
                  ),
                ],
              ),
            ),
          ),
          if (schedule.isExpanded) ...[
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _dayChip(
                    label: 'All',
                    selected: isAllSelected,
                    onTap: () => notifier.toggleAllDays(valveIndex, scheduleIndex),
                    isAll: true,
                  ),
                  const SizedBox(width: 8),
                  for (var i = 0; i < _dayChips.length; i++) ...[
                    _dayChip(
                      label: _dayChips[i].shortLabel,
                      selected: schedule.selectedDays.contains(_dayChips[i].apiDay),
                      onTap: () => notifier.toggleDay(
                        valveIndex,
                        scheduleIndex,
                        _dayChips[i].apiDay,
                      ),
                    ),
                    if (i < _dayChips.length - 1) const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.lightGreyText),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _timeField(
                          context: context,
                          label: 'From',
                          value: schedule.fromTime,
                          onTap: () async {
                            final picked = await _pickTime(
                              context: context,
                              initial: schedule.fromTime ??
                                  const TimeOfDay(hour: 8, minute: 0),
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
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _timeField(
                          context: context,
                          label: 'To',
                          value: schedule.toTime,
                          onTap: () async {
                            final picked = await _pickTime(
                              context: context,
                              initial: schedule.toTime ??
                                  const TimeOfDay(hour: 9, minute: 0),
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
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.lightBlue,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.timelapse_rounded,
                          size: 18,
                          color: AppColors.primaryTeal,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _durationLabel(schedule),
                          style: const TextStyle(
                            color: AppColors.darkText,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (validationMessage != null) ...[
              const SizedBox(height: 10),
              Text(
                validationMessage,
                style: const TextStyle(
                  color: AppColors.error,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: schedule.persisted
                      ? OutlinedButton.icon(
                          onPressed: schedule.isSubmitting
                              ? null
                              : () async {
                                  final confirmed =
                                      await _confirmScheduleDelete(context);
                                  if (confirmed != true || !context.mounted) {
                                    return;
                                  }
                                  final error = await notifier.deleteSchedule(
                                    valveIndex,
                                    scheduleIndex,
                                  );
                                  if (error != null && context.mounted) {
                                    _showSnackBar(context, error);
                                    return;
                                  }
                                  if (context.mounted) {
                                    _showSnackBar(context, 'Schedule deleted.');
                                  }
                                },
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(46),
                            foregroundColor: AppColors.error,
                            side: const BorderSide(color: AppColors.error),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: schedule.isSubmitting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.delete_outline_rounded),
                          label: const Text('Delete'),
                        )
                      : OutlinedButton.icon(
                          onPressed: canAddSchedule
                              ? () async {
                                  final error = await notifier.submitSchedule(
                                    valveIndex,
                                    scheduleIndex,
                                    addAnotherCard: true,
                                  );
                                  if (error != null && context.mounted) {
                                    _showSnackBar(context, error);
                                    return;
                                  }
                                  if (context.mounted) {
                                    _showSnackBar(
                                      context,
                                      'Schedule added successfully.',
                                    );
                                  }
                                }
                              : null,
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(46),
                            foregroundColor: AppColors.primaryTeal,
                            side: const BorderSide(color: AppColors.primaryTeal),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: schedule.isSubmitting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.add_circle_outline_rounded),
                          label: const Text('Add Schedule'),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: canSave
                        ? () async {
                            final error = await notifier.submitSchedule(
                              valveIndex,
                              scheduleIndex,
                              addAnotherCard: false,
                            );
                            if (error != null && context.mounted) {
                              _showSnackBar(context, error);
                              return;
                            }
                            if (context.mounted) {
                              _showSnackBar(
                                context,
                                schedule.persisted
                                    ? 'Schedule updated.'
                                    : 'Schedule saved.',
                              );
                            }
                          }
                        : null,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(46),
                      backgroundColor: AppColors.primaryTeal,
                      foregroundColor: AppColors.white,
                      disabledBackgroundColor: AppColors.lightGreyText,
                      disabledForegroundColor: AppColors.greyText,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: schedule.isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.white,
                            ),
                          )
                        : Icon(
                            schedule.persisted
                                ? Icons.edit_outlined
                                : Icons.save_outlined,
                          ),
                    label: Text(schedule.persisted ? 'Edit' : 'Save'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _dayChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    bool isAll = false,
  }) {
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: isAll ? 52 : 42,
        height: isAll ? 52 : 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: selected ? AppColors.primaryTeal : AppColors.white,
          border: Border.all(
            color: selected ? AppColors.primaryTeal : AppColors.lightGreyText,
            width: 1.4,
          ),
          boxShadow: selected
              ? const [
                  BoxShadow(
                    color: Color(0x290FA779),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ]
              : const [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.white : AppColors.darkText,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _timeField({
    required BuildContext context,
    required String label,
    required TimeOfDay? value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.lightBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.lightGreyText),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.access_time_rounded,
              size: 18,
              color: AppColors.primaryTeal,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.greyText,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value == null ? 'Select time' : value.format(context),
                    style: TextStyle(
                      color: value == null
                          ? AppColors.greyText
                          : AppColors.darkText,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.greyText,
            ),
          ],
        ),
      ),
    );
  }

  Future<TimeOfDay?> _pickTime({
    required BuildContext context,
    required TimeOfDay initial,
  }) {
    return showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.primaryTeal,
              onPrimary: AppColors.white,
              onSurface: AppColors.darkText,
            ),
          ),
          child: child!,
        );
      },
    );
  }

  Future<bool?> _confirmScheduleDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Schedule'),
          content: const Text(
            'Are you sure you want to delete this schedule?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: AppColors.white,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  String _durationLabel(_ScheduleCardModel schedule) {
    if (schedule.fromTime == null || schedule.toTime == null) {
      return 'Time: --';
    }
    final duration = _durationInMinutes(schedule.fromTime!, schedule.toTime!);
    if (duration <= 0) {
      return 'Time: --';
    }
    return 'Time: $duration min';
  }

  int _durationInMinutes(TimeOfDay from, TimeOfDay to) {
    return _toMinutes(to) - _toMinutes(from);
  }

  int _toMinutes(TimeOfDay value) => value.hour * 60 + value.minute;

  bool _canAddSchedule(_ValveComponentModel valve, int scheduleIndex) {
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

  bool _canSaveSchedule(_ValveComponentModel valve, int scheduleIndex) {
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
    required _ValveComponentModel valve,
    required int scheduleIndex,
  }) {
    final schedule = valve.schedules[scheduleIndex];
    if (schedule.selectedDays.isEmpty) {
      return 'Select at least one day.';
    }
    if (schedule.fromTime == null || schedule.toTime == null) {
      return 'Select both From and To time.';
    }

    final fromMinutes = _toMinutes(schedule.fromTime!);
    final toMinutes = _toMinutes(schedule.toTime!);
    if (fromMinutes >= toMinutes) {
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

      final sharedDays = schedule.selectedDays
          .intersection(other.selectedDays)
          .isNotEmpty;
      if (!sharedDays) {
        continue;
      }

      final otherStart = _toMinutes(other.fromTime!);
      final otherEnd = _toMinutes(other.toTime!);
      final overlaps = fromMinutes < otherEnd && otherStart < toMinutes;
      if (overlaps) {
        return 'Schedule time overlaps another card for the selected day.';
      }
    }

    return null;
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message.replaceFirst('Exception: ', ''))),
    );
  }

  Future<int?> _showManualDurationDialog(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    var durationText = '';

    final result = await showDialog<int>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Manual Duration'),
          content: Form(
            key: formKey,
            child: TextFormField(
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly,
              ],
              onChanged: (value) => durationText = value,
              decoration: const InputDecoration(
                labelText: 'Duration (minutes)',
                hintText: 'Max 300',
              ),
              validator: (value) {
                final trimmed = (value ?? '').trim();
                if (trimmed.isEmpty) {
                  return 'Duration is required';
                }
                final parsed = int.tryParse(trimmed);
                if (parsed == null) {
                  return 'Enter a valid number';
                }
                if (parsed < 1 || parsed > 300) {
                  return 'Enter 1 to 300 minutes';
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final isValid = formKey.currentState?.validate() ?? false;
                if (!isValid) {
                  return;
                }
                Navigator.of(dialogContext).pop(int.parse(durationText.trim()));
              },
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );

    return result;
  }
}

class _ValveSettingArgs {
  const _ValveSettingArgs({
    required this.deviceId,
    required this.displayName,
    required this.espId,
    required this.components,
  });

  final String deviceId;
  final String displayName;
  final String espId;
  final List<CustomerDeviceComponent> components;

  factory _ValveSettingArgs.fromDevice(CustomerDeviceSummary device) {
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

    return _ValveSettingArgs(
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
    if (other is! _ValveSettingArgs || other.deviceId != deviceId) {
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

class _ValveSettingState {
  const _ValveSettingState({
    required this.valves,
    required this.isLeaving,
  });

  final List<_ValveComponentModel> valves;
  final bool isLeaving;

  _ValveSettingState copyWith({
    List<_ValveComponentModel>? valves,
    bool? isLeaving,
  }) {
    return _ValveSettingState(
      valves: valves ?? this.valves,
      isLeaving: isLeaving ?? this.isLeaving,
    );
  }
}

final _valveSettingProvider = legacy.ChangeNotifierProvider.autoDispose
    .family<_ValveSettingController, _ValveSettingArgs>(
      (ref, args) => _ValveSettingController(ref, args),
    );

class _ValveSettingController extends ChangeNotifier {
  _ValveSettingController(this.ref, this.args)
    : _state = _ValveSettingState(
        valves: List<_ValveComponentModel>.generate(args.components.length, (
          index,
        ) {
          final component = args.components[index];
          return _ValveComponentModel(
            valveLabel: component.installedArea.trim().isEmpty
                ? 'Valve ${index + 1}'
                : component.installedArea,
            componentName: component.displayName,
            componentId: component.componentId,
            isActive: true,
            isExpanded: false,
            manualActionOn: false,
            isLoadingSchedules: false,
            hasLoadedSchedules: false,
            schedules: <_ScheduleCardModel>[_ScheduleCardModel.createDraft()],
            lastUpdated: DateTime.now(),
          );
        }),
        isLeaving: false,
      ) {
    debugPrint(
      'VALVE_SETTING init: valves=${args.components.length}, firstValveComponentId='
      '${args.components.isNotEmpty ? args.components.first.componentId : 'n/a'}',
    );
  }

  final Ref ref;
  final _ValveSettingArgs args;
  _ValveSettingState _state;

  _ValveSettingState get state => _state;

  static const List<_DayChipData> _dayChips = <_DayChipData>[
    _DayChipData(apiDay: 1, shortLabel: 'M', fullLabel: 'Monday'),
    _DayChipData(apiDay: 2, shortLabel: 'T', fullLabel: 'Tuesday'),
    _DayChipData(apiDay: 3, shortLabel: 'W', fullLabel: 'Wednesday'),
    _DayChipData(apiDay: 4, shortLabel: 'T', fullLabel: 'Thursday'),
    _DayChipData(apiDay: 5, shortLabel: 'F', fullLabel: 'Friday'),
    _DayChipData(apiDay: 6, shortLabel: 'S', fullLabel: 'Saturday'),
    _DayChipData(apiDay: 7, shortLabel: 'S', fullLabel: 'Sunday'),
  ];

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
      valves: List<_ValveComponentModel>.generate(_state.valves.length, (index) {
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

  void toggleActive(int valveIndex, bool value) {
    final nextValves = List<_ValveComponentModel>.from(_state.valves);
    nextValves[valveIndex] = nextValves[valveIndex].copyWith(isActive: value);
    _state = _state.copyWith(valves: nextValves);
    notifyListeners();
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
        : _dayChips.map((item) => item.apiDay).toSet();
    _updateSchedule(
      valveIndex,
      scheduleIndex,
      (item) => item.copyWith(selectedDays: nextDays),
    );
  }

  void toggleScheduleExpanded(int valveIndex, int scheduleIndex) {
    final valve = _state.valves[valveIndex];
    final nextSchedules = List<_ScheduleCardModel>.generate(
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
            duration: duration,
          );
      return null;
    } catch (error) {
      _updateValve(
        valveIndex,
        (item) => item.copyWith(manualActionOn: !value),
      );
      return error.toString();
    }
  }

  Future<String?> submitSchedule(
    int valveIndex,
    int scheduleIndex, {
    required bool addAnotherCard,
  }) async {
    final valve = _state.valves[valveIndex];
    final schedule = valve.schedules[scheduleIndex];
    final validationError = _scheduleValidationMessage(
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
        startTime: _scheduleTimeFrom(schedule.fromTime!),
        endTime: _scheduleTimeFrom(schedule.toTime!),
        durationMins: _durationInMinutes(schedule.fromTime!, schedule.toTime!),
        enabled: true,
      );

      if (schedule.persisted) {
        await ref.read(customerDevicesServiceProvider).updateSchedule(
          bearerToken: token,
          componentId: componentId,
          scheduleId: schedule.scheduleId,
          request: request,
        );
      } else {
        await ref.read(customerDevicesServiceProvider).createSchedule(
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
            schedules: <_ScheduleCardModel>[
              ...item.schedules,
              _ScheduleCardModel.createDraft(),
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

      await ref.read(customerDevicesServiceProvider).deleteSchedule(
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
          schedules: <_ScheduleCardModel>[_ScheduleCardModel.createDraft()],
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
          .getComponentSchedules(
            bearerToken: token,
            componentId: componentId,
          );
      debugPrint(
        'VALVE_SETTING refreshSchedules: received ${schedules.length} schedules '
        'for valveIndex=$valveIndex, componentId=$componentId',
      );

      final nextCards = schedules
          .take(3)
          .map(_ScheduleCardModel.fromRemote)
          .toList();
      if (nextCards.length < 3) {
        nextCards.add(_ScheduleCardModel.createDraft());
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
              ? <_ScheduleCardModel>[_ScheduleCardModel.createDraft()]
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
      final remembered =
          await ref.read(authLocalStorageProvider).loadLoginData();
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
    _ValveComponentModel Function(_ValveComponentModel item) update,
  ) {
    final nextValves = List<_ValveComponentModel>.from(_state.valves);
    nextValves[index] = update(nextValves[index]);
    _state = _state.copyWith(valves: nextValves);
    notifyListeners();
  }

  void _updateSchedule(
    int valveIndex,
    int scheduleIndex,
    _ScheduleCardModel Function(_ScheduleCardModel item) update,
  ) {
    _updateValve(
      valveIndex,
      (valve) => valve.updateSchedule(scheduleIndex, update),
    );
  }
}

class _DayChipData {
  const _DayChipData({
    required this.apiDay,
    required this.shortLabel,
    required this.fullLabel,
  });

  final int apiDay;
  final String shortLabel;
  final String fullLabel;
}

class _ValveComponentModel {
  const _ValveComponentModel({
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
  final List<_ScheduleCardModel> schedules;
  final DateTime lastUpdated;

  _ValveComponentModel copyWith({
    String? valveLabel,
    String? componentName,
    String? componentId,
    bool? isActive,
    bool? isExpanded,
    bool? manualActionOn,
    bool? isLoadingSchedules,
    bool? hasLoadedSchedules,
    List<_ScheduleCardModel>? schedules,
    DateTime? lastUpdated,
  }) {
    return _ValveComponentModel(
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

  _ValveComponentModel updateSchedule(
    int index,
    _ScheduleCardModel Function(_ScheduleCardModel item) update,
  ) {
    final nextSchedules = List<_ScheduleCardModel>.from(schedules);
    nextSchedules[index] = update(nextSchedules[index]);
    return copyWith(schedules: nextSchedules);
  }
}

class _ScheduleCardModel {
  const _ScheduleCardModel({
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

  factory _ScheduleCardModel.createDraft() {
    return _ScheduleCardModel(
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

  factory _ScheduleCardModel.fromRemote(CustomerComponentSchedule schedule) {
    final from = TimeOfDay(
      hour: schedule.startTime.hour,
      minute: schedule.startTime.minute,
    );
    final to = TimeOfDay(
      hour: schedule.endTime.hour,
      minute: schedule.endTime.minute,
    );
    final days = schedule.days.toSet();
    return _ScheduleCardModel(
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

  _ScheduleCardModel copyWith({
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
    return _ScheduleCardModel(
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

bool _sameTimeOfDay(TimeOfDay? left, TimeOfDay? right) {
  if (left == null || right == null) {
    return left == right;
  }
  return left.hour == right.hour && left.minute == right.minute;
}

bool _sameDaySet(Set<int> left, Set<int> right) {
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

CustomerScheduleTime _scheduleTimeFrom(TimeOfDay value) {
  return CustomerScheduleTime(hour: value.hour, minute: value.minute);
}

int _durationInMinutes(TimeOfDay from, TimeOfDay to) {
  return _toMinutes(to) - _toMinutes(from);
}

int _toMinutes(TimeOfDay value) => value.hour * 60 + value.minute;

String? _scheduleValidationMessage({
  required _ValveComponentModel valve,
  required int scheduleIndex,
}) {
  final schedule = valve.schedules[scheduleIndex];
  if (schedule.selectedDays.isEmpty) {
    return 'Select at least one day.';
  }
  if (schedule.fromTime == null || schedule.toTime == null) {
    return 'Select both From and To time.';
  }

  final fromMinutes = _toMinutes(schedule.fromTime!);
  final toMinutes = _toMinutes(schedule.toTime!);
  if (fromMinutes >= toMinutes) {
    return '"To" time must be greater than "From" time.';
  }

  for (var index = 0; index < valve.schedules.length; index++) {
    if (index == scheduleIndex) {
      continue;
    }
    final other = valve.schedules[index];
    if (other.selectedDays.isEmpty || other.fromTime == null || other.toTime == null) {
      continue;
    }

    final sharedDays = schedule.selectedDays.intersection(other.selectedDays).isNotEmpty;
    if (!sharedDays) {
      continue;
    }

    final otherStart = _toMinutes(other.fromTime!);
    final otherEnd = _toMinutes(other.toTime!);
    final overlaps = fromMinutes < otherEnd && otherStart < toMinutes;
    if (overlaps) {
      return 'Schedule time overlaps another card for the selected day.';
    }
  }

  return null;
}

const List<_DayChipData> _dayChips = <_DayChipData>[
  _DayChipData(apiDay: 1, shortLabel: 'M', fullLabel: 'Monday'),
  _DayChipData(apiDay: 2, shortLabel: 'T', fullLabel: 'Tuesday'),
  _DayChipData(apiDay: 3, shortLabel: 'W', fullLabel: 'Wednesday'),
  _DayChipData(apiDay: 4, shortLabel: 'T', fullLabel: 'Thursday'),
  _DayChipData(apiDay: 5, shortLabel: 'F', fullLabel: 'Friday'),
  _DayChipData(apiDay: 6, shortLabel: 'S', fullLabel: 'Saturday'),
  _DayChipData(apiDay: 7, shortLabel: 'S', fullLabel: 'Sunday'),
];

const Object _marker = Object();
