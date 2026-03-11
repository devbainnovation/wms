import 'package:flutter/material.dart';
import 'package:wms/shared/theme/theme.dart';

class AppScheduleTimeRange {
  const AppScheduleTimeRange({required this.start, required this.end});

  final TimeOfDay start;
  final TimeOfDay end;
}

class AppScheduleEditorDialog extends StatefulWidget {
  const AppScheduleEditorDialog({
    required this.title,
    this.initialSchedules = const <int, List<AppScheduleTimeRange>>{},
    super.key,
  });

  final String title;
  final Map<int, List<AppScheduleTimeRange>> initialSchedules;
  static const int maxSlotsPerDay = 3;

  static const List<String> dayShortLabels = <String>[
    'S',
    'M',
    'T',
    'W',
    'T',
    'F',
    'S',
  ];

  static const List<String> dayFullLabels = <String>[
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];

  @override
  State<AppScheduleEditorDialog> createState() =>
      _AppScheduleEditorDialogState();
}

class _AppScheduleEditorDialogState extends State<AppScheduleEditorDialog> {
  late Set<int> _selectedDays;
  late Map<int, List<AppScheduleTimeRange>> _daySchedules;

  @override
  void initState() {
    super.initState();
    _selectedDays = widget.initialSchedules.keys.toSet();
    _daySchedules = _cloneSchedules(widget.initialSchedules);
  }

  @override
  Widget build(BuildContext context) {
    final allSelected = _selectedDays.length == 7;

    return AlertDialog(
      backgroundColor: AppColors.white,
      title: Text(
        widget.title,
        style: const TextStyle(
          color: AppColors.darkText,
          fontWeight: FontWeight.w700,
        ),
      ),
      content: SizedBox(
        width: 680,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _dayButton(
                      label: 'All',
                      selected: allSelected,
                      onTap: _toggleAllDays,
                      isAll: true,
                    ),
                    const SizedBox(width: 8),
                    for (var day = 0; day < 7; day++) ...[
                      _dayButton(
                        label: AppScheduleEditorDialog.dayShortLabels[day],
                        selected: _selectedDays.contains(day),
                        onTap: () => _toggleDay(day),
                      ),
                      if (day < 6) const SizedBox(width: 8),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),
              if (_selectedDays.isEmpty)
                const Text(
                  'Select days to create schedules.',
                  style: TextStyle(
                    color: AppColors.greyText,
                    fontWeight: FontWeight.w600,
                  ),
                )
              else
                Column(
                  children: [
                    for (final day in _selectedDays.toList()..sort()) ...[
                      _dayScheduleView(context, day),
                      const SizedBox(height: 10),
                    ],
                  ],
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(
            context,
          ).pop<Map<int, List<AppScheduleTimeRange>>>(null),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primaryTeal,
            foregroundColor: AppColors.white,
          ),
          onPressed: _submit,
          child: const Text('Save'),
        ),
      ],
    );
  }

  Widget _dayButton({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    bool isAll = false,
  }) {
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: Container(
        width: isAll ? 44 : 38,
        height: isAll ? 44 : 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: selected
              ? AppColors.primaryTeal.withValues(alpha: 0.18)
              : AppColors.white,
          border: Border.all(
            color: selected ? AppColors.primaryTeal : AppColors.lightGreyText,
            width: 1.4,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.primaryTeal : AppColors.darkText,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _dayScheduleView(BuildContext context, int day) {
    final ranges = _daySchedules[day] ?? const <AppScheduleTimeRange>[];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.lightBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  AppScheduleEditorDialog.dayFullLabels[day],
                  style: const TextStyle(
                    color: AppColors.darkText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () => _editDayRanges(day),
                icon: const Icon(Icons.schedule_rounded),
                label: Text(ranges.isEmpty ? 'Add Time' : 'Edit Time'),
              ),
            ],
          ),
          if (ranges.isEmpty)
            const Text(
              'No time slots',
              style: TextStyle(color: AppColors.greyText, fontSize: 13),
            )
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final range in ranges)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.lightBlue.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${range.start.format(context)} - ${range.end.format(context)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.darkText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  void _toggleAllDays() {
    setState(() {
      if (_selectedDays.length == 7) {
        _selectedDays = <int>{};
        _daySchedules = <int, List<AppScheduleTimeRange>>{};
      } else {
        _selectedDays = Set<int>.from(List<int>.generate(7, (i) => i));
      }
    });
  }

  void _toggleDay(int day) {
    setState(() {
      if (_selectedDays.contains(day)) {
        _selectedDays.remove(day);
        _daySchedules.remove(day);
      } else {
        _selectedDays.add(day);
      }
    });
  }

  Future<void> _editDayRanges(int day) async {
    final updated = await showDialog<List<AppScheduleTimeRange>>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _DayTimeDialog(
        dayLabel: AppScheduleEditorDialog.dayFullLabels[day],
        initialRanges: List<AppScheduleTimeRange>.from(
          _daySchedules[day] ?? const <AppScheduleTimeRange>[],
        ),
        maxSlots: AppScheduleEditorDialog.maxSlotsPerDay,
      ),
    );

    if (updated == null) {
      return;
    }

    setState(() {
      if (updated.isEmpty) {
        _daySchedules.remove(day);
        _selectedDays.remove(day);
      } else {
        _selectedDays.add(day);
        _daySchedules[day] = updated;
      }
    });
  }

  void _submit() {
    if (_selectedDays.length == 7) {
      for (var day = 0; day < 7; day++) {
        final ranges = _daySchedules[day] ?? const <AppScheduleTimeRange>[];
        if (ranges.isEmpty) {
          _showError(
            'If all days are selected, every day must have at least one timer.',
          );
          return;
        }
      }
    }

    for (final day in _selectedDays) {
      final ranges = _daySchedules[day] ?? const <AppScheduleTimeRange>[];
      final validationError = validateTimeRanges(
        ranges,
        dayLabel: AppScheduleEditorDialog.dayFullLabels[day],
        requireAtLeastOne: true,
      );
      if (validationError != null) {
        _showError(validationError);
        return;
      }
    }

    Navigator.of(
      context,
    ).pop<Map<int, List<AppScheduleTimeRange>>>(_cloneSchedules(_daySchedules));
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _DayTimeDialog extends StatefulWidget {
  const _DayTimeDialog({
    required this.dayLabel,
    required this.initialRanges,
    required this.maxSlots,
  });

  final String dayLabel;
  final List<AppScheduleTimeRange> initialRanges;
  final int maxSlots;

  @override
  State<_DayTimeDialog> createState() => _DayTimeDialogState();
}

class _DayTimeDialogState extends State<_DayTimeDialog> {
  late List<AppScheduleTimeRange> _ranges;

  @override
  void initState() {
    super.initState();
    _ranges = List<AppScheduleTimeRange>.from(widget.initialRanges);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.white,
      title: Text(
        '${widget.dayLabel} Timers',
        style: const TextStyle(
          color: AppColors.darkText,
          fontWeight: FontWeight.w700,
        ),
      ),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    for (var i = 0; i < _ranges.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: _slotButton(
                                label: _ranges[i].start.format(context),
                                onTap: () => _pickAndSetTime(i, true),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              '-',
                              style: TextStyle(color: AppColors.darkText),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _slotButton(
                                label: _ranges[i].end.format(context),
                                onTap: () => _pickAndSetTime(i, false),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Delete slot',
                              onPressed: () {
                                setState(() {
                                  _ranges.removeAt(i);
                                });
                              },
                              icon: const Icon(
                                Icons.delete_rounded,
                                color: AppColors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _ranges.length >= widget.maxSlots
                    ? null
                    : () {
                        setState(() {
                          _ranges = [
                            ..._ranges,
                            const AppScheduleTimeRange(
                              start: TimeOfDay(hour: 8, minute: 0),
                              end: TimeOfDay(hour: 9, minute: 0),
                            ),
                          ];
                        });
                      },
                icon: const Icon(Icons.add_rounded),
                label: Text(
                  _ranges.length >= widget.maxSlots
                      ? 'Max ${widget.maxSlots} Slots'
                      : 'Add Time',
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () =>
              Navigator.of(context).pop<List<AppScheduleTimeRange>>(null),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primaryTeal,
            foregroundColor: AppColors.white,
          ),
          onPressed: () {
            final validationError = validateTimeRanges(
              _ranges,
              requireAtLeastOne: true,
            );
            if (validationError != null) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(validationError)));
              return;
            }
            if (_ranges.length > widget.maxSlots) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Maximum ${widget.maxSlots} time slots allowed per day.',
                  ),
                ),
              );
              return;
            }
            Navigator.of(context).pop<List<AppScheduleTimeRange>>(
              List<AppScheduleTimeRange>.from(_ranges),
            );
          },
          child: const Text('Save'),
        ),
      ],
    );
  }

  Widget _slotButton({required String label, required VoidCallback onTap}) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.darkText,
        side: const BorderSide(color: AppColors.lightGreyText),
        minimumSize: const Size(120, 46),
      ),
      child: Text(
        label,
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.fade,
      ),
    );
  }

  Future<void> _pickAndSetTime(int index, bool isStart) async {
    final initial = isStart ? _ranges[index].start : _ranges[index].end;
    final picked = await showTimePicker(
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
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
            child: child!,
          ),
        );
      },
    );

    if (picked == null) {
      return;
    }

    setState(() {
      final current = _ranges[index];
      _ranges[index] = isStart
          ? AppScheduleTimeRange(start: picked, end: current.end)
          : AppScheduleTimeRange(start: current.start, end: picked);
    });
  }
}

Map<int, List<AppScheduleTimeRange>> _cloneSchedules(
  Map<int, List<AppScheduleTimeRange>> source,
) {
  return {
    for (final entry in source.entries)
      entry.key: List<AppScheduleTimeRange>.from(entry.value),
  };
}

String? validateTimeRanges(
  List<AppScheduleTimeRange> ranges, {
  String? dayLabel,
  required bool requireAtLeastOne,
}) {
  String withPrefix(String message) {
    if (dayLabel == null) {
      return message;
    }
    return '$dayLabel: $message';
  }

  if (requireAtLeastOne && ranges.isEmpty) {
    return dayLabel == null
        ? 'Please add at least one timer range before saving.'
        : '$dayLabel must have at least one timer.';
  }

  if (ranges.length > AppScheduleEditorDialog.maxSlotsPerDay) {
    return withPrefix(
      'Maximum ${AppScheduleEditorDialog.maxSlotsPerDay} time slots allowed.',
    );
  }

  for (final range in ranges) {
    final fromMinutes = _toMinutes(range.start);
    final toMinutes = _toMinutes(range.end);
    if (fromMinutes >= toMinutes) {
      return withPrefix('"To" time must be greater than "From" time.');
    }
  }

  final seenStarts = <int>{};
  for (final range in ranges) {
    final startMinutes = _toMinutes(range.start);
    if (!seenStarts.add(startMinutes)) {
      return withPrefix('Same start time is not allowed in multiple slots.');
    }
  }

  final sorted = List<AppScheduleTimeRange>.from(ranges)
    ..sort((a, b) => _toMinutes(a.start).compareTo(_toMinutes(b.start)));
  for (var i = 1; i < sorted.length; i++) {
    final previous = sorted[i - 1];
    final current = sorted[i];
    if (_toMinutes(current.start) < _toMinutes(previous.end)) {
      return withPrefix('Overlapping time ranges are not allowed.');
    }
  }

  return null;
}

int _toMinutes(TimeOfDay value) => value.hour * 60 + value.minute;
