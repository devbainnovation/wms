import 'package:flutter/material.dart';
import 'package:wms/shared/shared.dart';
import 'package:wms/user/features/valves/models/valve_setting_models.dart';

class ValveSettingScheduleCard extends StatelessWidget {
  const ValveSettingScheduleCard({
    required this.schedule,
    required this.scheduleIndex,
    required this.canEditSchedule,
    required this.onOpenEditor,
    super.key,
  });

  final ScheduleCardModel schedule;
  final int scheduleIndex;
  final bool canEditSchedule;
  final VoidCallback onOpenEditor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.lightGreyText),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Schedule ${scheduleIndex + 1}',
                  style: const TextStyle(
                    color: AppColors.darkText,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (schedule.persisted)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
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
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.calendar_month_rounded,
                size: 16,
                color: AppColors.greyText,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _scheduleDaysLabel(schedule),
                  style: const TextStyle(
                    color: AppColors.darkText,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.access_time_rounded,
                size: 16,
                color: AppColors.greyText,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  schedule.fromTime == null || schedule.toTime == null
                      ? 'Tap to edit schedule details'
                      : '${schedule.fromTime!.format(context)} - ${schedule.toTime!.format(context)}',
                  style: const TextStyle(
                    color: AppColors.greyText,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: canEditSchedule ? onOpenEditor : null,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(46),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                schedule.persisted ? 'Edit schedule' : 'Add schedule',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _scheduleDaysLabel(ScheduleCardModel schedule) {
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
