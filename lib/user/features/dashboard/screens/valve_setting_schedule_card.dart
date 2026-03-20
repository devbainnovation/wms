import 'package:flutter/material.dart';
import 'package:wms/shared/shared.dart';
import 'package:wms/user/features/dashboard/screens/valve_setting_models.dart';

class ValveSettingScheduleCard extends StatelessWidget {
  const ValveSettingScheduleCard({
    required this.contextForTimeFormat,
    required this.schedule,
    required this.scheduleIndex,
    required this.isAllSelected,
    required this.validationMessage,
    required this.canSave,
    required this.canAddSchedule,
    required this.onToggleExpanded,
    required this.onToggleAllDays,
    required this.onToggleDay,
    required this.onPickFromTime,
    required this.onPickToTime,
    required this.onDelete,
    required this.onAddSchedule,
    required this.onSave,
    super.key,
  });

  final BuildContext contextForTimeFormat;
  final ScheduleCardModel schedule;
  final int scheduleIndex;
  final bool isAllSelected;
  final String? validationMessage;
  final bool canSave;
  final bool canAddSchedule;
  final VoidCallback onToggleExpanded;
  final VoidCallback onToggleAllDays;
  final ValueChanged<int> onToggleDay;
  final VoidCallback onPickFromTime;
  final VoidCallback onPickToTime;
  final VoidCallback onDelete;
  final VoidCallback onAddSchedule;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
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
            onTap: onToggleExpanded,
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
                  _DayChip(
                    label: 'All',
                    selected: isAllSelected,
                    onTap: onToggleAllDays,
                    isAll: true,
                  ),
                  const SizedBox(width: 8),
                  for (var i = 0; i < dayChips.length; i++) ...[
                    _DayChip(
                      label: dayChips[i].shortLabel,
                      selected: schedule.selectedDays.contains(dayChips[i].apiDay),
                      onTap: () => onToggleDay(dayChips[i].apiDay),
                    ),
                    if (i < dayChips.length - 1) const SizedBox(width: 8),
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
                        child: _TimeField(
                          contextForTimeFormat: contextForTimeFormat,
                          label: 'From',
                          value: schedule.fromTime,
                          onTap: onPickFromTime,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _TimeField(
                          contextForTimeFormat: contextForTimeFormat,
                          label: 'To',
                          value: schedule.toTime,
                          onTap: onPickToTime,
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
                          durationLabel(schedule),
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
                validationMessage!,
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
                          onPressed: schedule.isSubmitting ? null : onDelete,
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
                          onPressed: canAddSchedule ? onAddSchedule : null,
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
                    onPressed: canSave ? onSave : null,
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
}

String durationLabel(ScheduleCardModel schedule) {
  if (schedule.fromTime == null || schedule.toTime == null) {
    return 'Time: --';
  }
  final duration = durationInMinutes(schedule.fromTime!, schedule.toTime!);
  if (duration <= 0) {
    return 'Time: --';
  }
  return 'Time: $duration min';
}

class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.isAll = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool isAll;

  @override
  Widget build(BuildContext context) {
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
}

class _TimeField extends StatelessWidget {
  const _TimeField({
    required this.contextForTimeFormat,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final BuildContext contextForTimeFormat;
  final String label;
  final TimeOfDay? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
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
                    value == null ? 'Select time' : value!.format(contextForTimeFormat),
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
}
