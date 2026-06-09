import 'package:flutter/material.dart';
import 'package:wms/shared/shared.dart';
import 'package:wms/user/features/valves/models/valve_setting_models.dart';
import 'package:wms/user/features/valves/screens/valve_setting_dialogs.dart';

class ValveScheduleEditorScreen extends StatefulWidget {
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
  State<ValveScheduleEditorScreen> createState() =>
      _ValveScheduleEditorScreenState();
}

class _ValveScheduleEditorScreenState extends State<ValveScheduleEditorScreen> {
  late bool _allMode;
  late Set<int> _selectedDays;
  late TimeOfDay? _fromTime;
  late TimeOfDay? _toTime;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedDays = Set<int>.from(widget.schedule.selectedDays);
    _allMode = _selectedDays.length == 7;
    if (_allMode) {
      _selectedDays = dayChips.map((item) => item.apiDay).toSet();
    }
    _fromTime = widget.schedule.fromTime;
    _toTime = widget.schedule.toTime;
  }

  bool get _hasValidSchedule {
    return _selectedDays.isNotEmpty &&
        _fromTime != null &&
        _toTime != null &&
        durationInMinutes(_fromTime!, _toTime!) > 0;
  }

  Future<void> _pickFromTime() async {
    final picked = await pickValveScheduleTime(
      context: context,
      initial: _fromTime ?? const TimeOfDay(hour: 8, minute: 0),
    );
    if (picked != null && mounted) {
      setState(() {
        _fromTime = picked;
      });
    }
  }

  Future<void> _pickToTime() async {
    final picked = await pickValveScheduleTime(
      context: context,
      initial: _toTime ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked != null && mounted) {
      setState(() {
        _toTime = picked;
      });
    }
  }

  void _selectAllMode() {
    setState(() {
      _allMode = true;
      _selectedDays = dayChips.map((item) => item.apiDay).toSet();
    });
  }

  void _selectAlternateMode() {
    setState(() {
      _allMode = false;
      if (_selectedDays.length == 7) {
        _selectedDays = <int>{};
      }
    });
  }

  void _toggleDay(int apiDay) {
    if (_allMode) {
      return;
    }
    setState(() {
      if (_selectedDays.contains(apiDay)) {
        _selectedDays.remove(apiDay);
      } else {
        _selectedDays.add(apiDay);
      }
    });
  }

  String get _modeLabel => _allMode ? 'All days' : 'Alternate days';

  Future<void> _handleSave() async {
    if (!_hasValidSchedule || !widget.canEditSchedule) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final schedule = widget.schedule.copyWith(
      selectedDays: Set<int>.from(_selectedDays),
      fromTime: _fromTime,
      toTime: _toTime,
    );

    final error = await widget.onSave(schedule);

    if (!mounted) {
      return;
    }

    setState(() {
      _isSubmitting = false;
    });

    if (error != null) {
      showAppSnackBar(context, error, status: AppSnackBarStatus.error);
      return;
    }

    Navigator.of(context).pop();
  }

  Future<void> _handleDelete() async {
    if (widget.onDelete == null) {
      return;
    }
    setState(() {
      _isSubmitting = true;
    });
    final error = await widget.onDelete!();
    if (!mounted) {
      return;
    }
    setState(() {
      _isSubmitting = false;
    });
    if (error != null) {
      if (error == '__cancelled__') {
        return;
      }
      showAppSnackBar(context, error, status: AppSnackBarStatus.error);
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final titleText = widget.valveLabel.trim().isEmpty
        ? 'Valve Schedule'
        : widget.valveLabel;
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
              widget.schedule.persisted ? 'Edit schedule' : 'Create schedule',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.darkText,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Use the toggle below to switch between all days and alternate days.',
              style: const TextStyle(color: AppColors.greyText, fontSize: 13),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: _allMode
                          ? AppColors.primaryTeal
                          : AppColors.lightBackground,
                      foregroundColor: _allMode
                          ? AppColors.white
                          : AppColors.darkText,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: _allMode
                              ? AppColors.primaryTeal
                              : AppColors.lightGreyText,
                        ),
                      ),
                      elevation: 0,
                    ),
                    onPressed: _selectAllMode,
                    child: const Text('All'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: !_allMode
                          ? AppColors.primaryTeal
                          : AppColors.lightBackground,
                      foregroundColor: !_allMode
                          ? AppColors.white
                          : AppColors.darkText,
                      side: BorderSide(
                        color: !_allMode
                            ? AppColors.primaryTeal
                            : AppColors.lightGreyText,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: _selectAlternateMode,
                    child: const Text('Alternate'),
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
                _modeLabel,
                style: const TextStyle(
                  color: AppColors.darkText,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: dayChips.map((item) {
                final selected = _selectedDays.contains(item.apiDay);
                return _SmallDayChip(
                  label: item.shortLabel,
                  selected: selected,
                  enabled: !_allMode && widget.canEditSchedule,
                  onTap: () => _toggleDay(item.apiDay),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            _EditorTimeField(
              label: 'From',
              value: _fromTime,
              onTap: widget.canEditSchedule ? _pickFromTime : null,
            ),
            const SizedBox(height: 14),
            _EditorTimeField(
              label: 'To',
              value: _toTime,
              onTap: widget.canEditSchedule ? _pickToTime : null,
            ),
            const SizedBox(height: 16),
            if (!_hasValidSchedule)
              const Text(
                'Select at least one day and choose a valid from/to time range.',
                style: TextStyle(
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
              if (widget.schedule.persisted && widget.canDeleteSchedule)
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSubmitting ? null : _handleDelete,
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
              if (widget.schedule.persisted && widget.canDeleteSchedule)
                const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed:
                      (!widget.canEditSchedule ||
                          !_hasValidSchedule ||
                          _isSubmitting)
                      ? null
                      : _handleSave,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.white,
                          ),
                        )
                      : Text(widget.schedule.persisted ? 'Update' : 'Add'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
