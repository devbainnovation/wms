import 'package:flutter/material.dart';
import 'package:wms/shared/shared.dart';
import 'package:wms/user/features/valves/models/valve_setting_models.dart';

class ValveSettingScheduleCard extends StatelessWidget {
  const ValveSettingScheduleCard({
    required this.schedule,
    required this.scheduleIndex,
    required this.canEditSchedule,
    required this.canDeleteSchedule,
    required this.onOpenEditor,
    required this.onDelete,
    super.key,
  });

  final ScheduleCardModel schedule;
  final int scheduleIndex;
  final bool canEditSchedule;
  final bool canDeleteSchedule;
  final VoidCallback onOpenEditor;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.lightBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.lightGreyText),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Schedule ${scheduleIndex + 1}${schedule.isExpired ? ' (Expired)' : ''}',
            style: TextStyle(
              color: schedule.isExpired ? AppColors.error : AppColors.darkText,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Icon(
                            Icons.calendar_month_rounded,
                            size: 14,
                            color: AppColors.greyText,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _scheduleDaysLabel(schedule),
                            style: const TextStyle(
                              color: AppColors.darkText,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          size: 14,
                          color: AppColors.greyText,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            schedule.fromTime == null || schedule.toTime == null
                                ? 'Not set'
                                : '${schedule.fromTime!.format(context)} - ${schedule.toTime!.format(context)}',
                            style: const TextStyle(
                              color: AppColors.darkText,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (canEditSchedule)
                    IconButton(
                      icon: const Icon(Icons.edit_rounded, size: 22),
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      padding: EdgeInsets.zero,
                      splashRadius: 16,
                      color: AppColors.primaryTeal,
                      onPressed: onOpenEditor,
                    ),
                  if (canDeleteSchedule)
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 22),
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      padding: EdgeInsets.zero,
                      splashRadius: 16,
                      color: AppColors.error,
                      onPressed: onDelete,
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String _scheduleDaysLabel(ScheduleCardModel schedule) {
  if (schedule.alternateMode) {
    final start = schedule.alternateStartDate != null
        ? _formatDate(schedule.alternateStartDate!)
        : 'Start';
    final end = schedule.alternateEndDate != null
        ? _formatDate(schedule.alternateEndDate!)
        : 'End';
    
    String label = 'Every ${schedule.alternateInterval} day(s) This Week';
    if (schedule.selectedDays.isNotEmpty) {
      final daysPart = schedule.selectedDays.length == 7
          ? 'All days'
          : dayChips
              .where((item) => schedule.selectedDays.contains(item.apiDay))
              .map((item) => item.shortLabel)
              .join(', ');
      label += ': $daysPart';
    }
    
    return '$label\n($start to $end)';
  }

  if (schedule.selectedDays.length == 7) {
    return 'All days';
  }
  if (schedule.selectedDays.isEmpty) {
    return 'No days selected';
  }

  return dayChips
      .where((item) => schedule.selectedDays.contains(item.apiDay))
      .map((item) => item.shortLabel)
      .join(', ');
}

String _formatDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}
