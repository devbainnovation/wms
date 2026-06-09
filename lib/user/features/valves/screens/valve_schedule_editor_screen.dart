import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wms/shared/shared.dart';
import 'package:wms/user/features/valves/models/valve_setting_models.dart';
import 'package:wms/user/features/valves/providers/valve_schedule_editor_controller.dart';
import 'package:wms/user/features/valves/screens/valve_setting_dialogs.dart';

class ValveScheduleEditorScreen extends ConsumerWidget {
  const ValveScheduleEditorScreen({
    required this.valveLabel,
    required this.schedule,
    required this.canEditSchedule,
    required this.canDeleteSchedule,
    required this.onSave,
    this.onDelete,
    super.key,
  });

  final String valveLabel;
  final ScheduleCardModel schedule;
  final bool canEditSchedule;
  final bool canDeleteSchedule;
  final Future<String?> Function(ScheduleCardModel schedule) onSave;
  final Future<String?> Function()? onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final titleText = valveLabel.trim().isEmpty ? 'Valve Schedule' : valveLabel;

    final editorController = ref.watch(valveScheduleEditorProvider(schedule));
    final timeDurationText =
        editorController.state.timeTouchEnabled &&
            editorController.state.fromTime != null &&
            editorController.state.toTime != null
        ? () {
            final duration = durationInMinutes(
              editorController.state.fromTime!,
              editorController.state.toTime!,
            );
            return duration > 0
                ? 'Time: $duration min'
                : 'Time: invalid time range';
          }()
        : null;
    final timeDurationIsValid =
        editorController.state.timeTouchEnabled &&
        editorController.state.fromTime != null &&
        editorController.state.toTime != null &&
        durationInMinutes(
              editorController.state.fromTime!,
              editorController.state.toTime!,
            ) >
            0;
    final intervalDateErrorText =
        !editorController.state.allMode &&
            editorController.state.alternateStartDate != null &&
            editorController.state.alternateEndDate != null
        ? () {
            final start = editorController.state.alternateStartDate!;
            final end = editorController.state.alternateEndDate!;
            final delta = end.difference(start).inDays;
            if (end.isBefore(start)) {
              return 'End date must be after start date';
            }
            if (delta < editorController.state.alternateInterval) {
              return 'End date must be at least ${editorController.state.alternateInterval} day(s) after start date';
            }
            return null;
          }()
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(titleText),
        backgroundColor: AppColors.white,
        surfaceTintColor: AppColors.white,
        elevation: 2,
        shadowColor: const Color(0x26000000),
      ),
      backgroundColor: AppColors.white,
      body: AppPageBody(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              schedule.persisted ? 'Edit schedule' : 'Create schedule',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.darkText,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Use the toggle below to switch between weekly and interval mode.',
              style: const TextStyle(color: AppColors.greyText, fontSize: 13),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: editorController.state.allMode
                          ? AppColors.primaryTeal
                          : AppColors.lightBackground,
                      foregroundColor: editorController.state.allMode
                          ? AppColors.white
                          : AppColors.darkText,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: editorController.state.allMode
                              ? AppColors.primaryTeal
                              : AppColors.lightGreyText,
                        ),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () => editorController.selectAllMode(),
                    child: const Text('WEEKLY'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: !editorController.state.allMode
                          ? AppColors.primaryTeal
                          : AppColors.lightBackground,
                      foregroundColor: !editorController.state.allMode
                          ? AppColors.white
                          : AppColors.darkText,
                      side: BorderSide(
                        color: !editorController.state.allMode
                            ? AppColors.primaryTeal
                            : AppColors.lightGreyText,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () => editorController.selectAlternateMode(),
                    child: const Text('INTERVAL'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Repeat mode',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.darkText,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.lightBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.lightGreyText),
              ),
              child: Text(
                editorController.modeLabel,
                style: const TextStyle(
                  color: AppColors.darkText,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (editorController.state.allMode)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children:
                      <DayChipData>[
                        const DayChipData(
                          apiDay: 0,
                          shortLabel: 'All',
                          fullLabel: 'All',
                        ),
                        ...dayChips,
                      ].map((item) {
                        final selected = item.apiDay == 0
                            ? editorController.state.selectedDays.length == 7
                            : editorController.state.selectedDays.contains(
                                item.apiDay,
                              );
                        return Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: _SmallDayChip(
                            label: item.shortLabel,
                            selected: selected,
                            enabled: canEditSchedule,
                            onTap: () =>
                                editorController.toggleDay(item.apiDay),
                          ),
                        );
                      }).toList(),
                ),
              )
            else ...[
              Text(
                'Select alternate interval',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkText,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: List<Widget>.generate(6, (index) {
                  final value = index + 1;
                  final isSelected =
                      editorController.state.alternateInterval == value;
                  return SizedBox(
                    width: 50,
                    height: 50,
                    child: InkWell(
                      onTap: canEditSchedule
                          ? () => editorController.setAlternateInterval(value)
                          : null,
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? AppColors.primaryTeal
                              : AppColors.white,
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primaryTeal
                                : AppColors.lightGreyText,
                            width: 1.4,
                          ),
                        ),
                        child: Text(
                          '$value',
                          style: TextStyle(
                            color: isSelected
                                ? AppColors.white
                                : AppColors.darkText,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _EditorDateField(
                      label: 'Start',
                      value: editorController.state.alternateStartDate,
                      onTap: canEditSchedule
                          ? () => _pickAlternateStartDate(
                              context,
                              editorController,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _EditorDateField(
                      label: 'End',
                      value: editorController.state.alternateEndDate,
                      onTap: canEditSchedule
                          ? () =>
                                _pickAlternateEndDate(context, editorController)
                          : null,
                    ),
                  ),
                ],
              ),
              if (intervalDateErrorText != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_month_rounded,
                      size: 18,
                      color: AppColors.error,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      intervalDateErrorText,
                      style: const TextStyle(
                        color: AppColors.error,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _EditorTimeField(
                    label: 'From',
                    value: editorController.state.fromTime,
                    onTap: canEditSchedule
                        ? () => _pickFromTime(context, ref, editorController)
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _EditorTimeField(
                    label: 'To',
                    value: editorController.state.toTime,
                    onTap: canEditSchedule
                        ? () => _pickToTime(context, ref, editorController)
                        : null,
                  ),
                ),
              ],
            ),
            if (timeDurationText != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: timeDurationIsValid
                        ? AppColors.greenSecondary
                        : AppColors.error,
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.timelapse,
                      size: 18,
                      color: AppColors.greenSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      timeDurationText,
                      style: TextStyle(
                        color: timeDurationIsValid
                            ? AppColors.greyText
                            : AppColors.error,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            if (!editorController.hasValidSchedule)
              Text(
                editorController.state.allMode
                    ? 'Select at least one day and choose a valid from/to time range.'
                    : 'Select a date range, alternate interval, and choose valid from/to times.',
                style: const TextStyle(
                  color: AppColors.error,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            const SizedBox(height: 60),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Row(
            children: [
              if (schedule.persisted && canDeleteSchedule)
                Expanded(
                  child: OutlinedButton(
                    onPressed: editorController.state.isSubmitting
                        ? null
                        : () => _handleDelete(context, ref, editorController),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      side: const BorderSide(color: AppColors.error),
                      foregroundColor: AppColors.error,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Delete'),
                  ),
                ),
              if (schedule.persisted && canDeleteSchedule)
                const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed:
                      (!canEditSchedule ||
                          !editorController.hasValidSchedule ||
                          editorController.state.isSubmitting)
                      ? null
                      : () => _handleSave(context, ref, editorController),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: editorController.state.isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.white,
                          ),
                        )
                      : Text(schedule.persisted ? 'Update' : 'Add'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickFromTime(
    BuildContext context,
    WidgetRef ref,
    ValveScheduleEditorController controller,
  ) async {
    final picked = await pickValveScheduleTime(
      context: context,
      initial: controller.state.fromTime ?? const TimeOfDay(hour: 8, minute: 0),
    );
    if (picked != null) {
      controller.setFromTime(picked);
    }
  }

  Future<void> _pickToTime(
    BuildContext context,
    WidgetRef ref,
    ValveScheduleEditorController controller,
  ) async {
    final picked = await pickValveScheduleTime(
      context: context,
      initial: controller.state.toTime ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked != null) {
      controller.setToTime(picked);
    }
  }

  Future<void> _pickAlternateStartDate(
    BuildContext context,
    ValveScheduleEditorController controller,
  ) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: controller.state.alternateStartDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      controller.setAlternateStartDate(picked);
    }
  }

  Future<void> _pickAlternateEndDate(
    BuildContext context,
    ValveScheduleEditorController controller,
  ) async {
    final picked = await showDatePicker(
      context: context,
      initialDate:
          controller.state.alternateEndDate ??
          controller.state.alternateStartDate ??
          DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      controller.setAlternateEndDate(picked);
    }
  }

  Future<void> _handleSave(
    BuildContext context,
    WidgetRef ref,
    ValveScheduleEditorController controller,
  ) async {
    if (!controller.hasValidSchedule || !canEditSchedule) {
      return;
    }

    controller.setIsSubmitting(true);

    final updatedSchedule = controller.buildSchedule(schedule);
    final error = await onSave(updatedSchedule);

    if (!context.mounted) {
      return;
    }

    controller.setIsSubmitting(false);

    if (error != null) {
      showAppSnackBar(context, error, status: AppSnackBarStatus.error);
      return;
    }

    Navigator.of(context).pop();
  }

  Future<void> _handleDelete(
    BuildContext context,
    WidgetRef ref,
    ValveScheduleEditorController controller,
  ) async {
    if (onDelete == null) {
      return;
    }
    controller.setIsSubmitting(true);
    final error = await onDelete!();
    if (!context.mounted) {
      return;
    }
    controller.setIsSubmitting(false);
    if (error != null) {
      if (error == '__cancelled__') {
        return;
      }
      showAppSnackBar(context, error, status: AppSnackBarStatus.error);
      return;
    }
    Navigator.of(context).pop();
  }
}

class _SmallDayChip extends StatelessWidget {
  const _SmallDayChip({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 42,
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: selected ? AppColors.primaryTeal : AppColors.white,
          border: Border.all(
            color: selected ? AppColors.primaryTeal : AppColors.lightGreyText,
            width: 1.4,
          ),
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
}

class _EditorTimeField extends StatelessWidget {
  const _EditorTimeField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final TimeOfDay? value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.lightBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.lightGreyText),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.greyText,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    value == null ? 'Select time' : value!.format(context),
                    style: TextStyle(
                      color: value == null
                          ? AppColors.greyText
                          : AppColors.darkText,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.access_time_rounded, color: AppColors.primaryTeal),
          ],
        ),
      ),
    );
  }
}

class _EditorDateField extends StatelessWidget {
  const _EditorDateField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final DateTime? value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.lightBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.lightGreyText),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.greyText,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    value == null ? 'Select date' : _formatDate(value!),
                    style: TextStyle(
                      color: value == null
                          ? AppColors.greyText
                          : AppColors.darkText,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.calendar_month_rounded,
              color: AppColors.primaryTeal,
            ),
          ],
        ),
      ),
    );
  }
}

String _formatDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}
