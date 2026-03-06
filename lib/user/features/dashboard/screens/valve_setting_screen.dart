import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wms/shared/shared.dart';
import 'package:wms/user/features/dashboard/services/customer_devices_service.dart';

class ValveSettingScreen extends ConsumerWidget {
  const ValveSettingScreen({required this.device, super.key});

  final CustomerDeviceSummary device;

  static const List<String> _dayShortLabels = <String>[
    'S',
    'M',
    'T',
    'W',
    'T',
    'F',
    'S',
  ];

  static const List<String> _dayFullLabels = <String>[
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final args = _ValveSettingArgs.fromDevice(device);
    final state = ref.watch(_valveSettingProvider(args));
    final notifier = ref.read(_valveSettingProvider(args).notifier);

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text('Valve Setting'),
        backgroundColor: AppColors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _headerCard(device: device),
          const SizedBox(height: 14),
          for (var i = 0; i < state.valves.length; i++) ...[
            _buildValveCard(
              context: context,
              valve: state.valves[i],
              onExpandToggle: () => notifier.toggleExpanded(i),
              onActiveToggle: (value) => notifier.toggleActive(i, value),
              onAllDaysTap: () => notifier.toggleAllDays(i),
              onDayTap: (day) async {
                final currentState = ref.read(_valveSettingProvider(args));
                final existing =
                    currentState.valves[i].daySchedules[day] ??
                    const <_TimeRange>[];
                final updatedRanges = await _openDayTimeDialog(
                  context: context,
                  dayLabel: _dayFullLabels[day],
                  initialRanges: existing,
                );
                if (updatedRanges == null) {
                  return;
                }
                notifier.setDayRanges(i, day, updatedRanges);
              },
            ),
            if (i < state.valves.length - 1) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  Widget _headerCard({required CustomerDeviceSummary device}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.lightGreyText),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            device.displayName.isEmpty ? '-' : device.displayName,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.darkText,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'ESP ID: ${device.espId.isEmpty ? '-' : device.espId}',
            style: const TextStyle(
              color: AppColors.greyText,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValveCard({
    required BuildContext context,
    required _ValveCardModel valve,
    required VoidCallback onExpandToggle,
    required ValueChanged<bool> onActiveToggle,
    required VoidCallback onAllDaysTap,
    required ValueChanged<int> onDayTap,
  }) {
    final allSelected = valve.selectedDays.length == 7;

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
            onTap: onExpandToggle,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          valve.valveLabel,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.darkText,
                          ),
                        ),
                        if (valve.componentName.trim().isNotEmpty)
                          Text(
                            valve.componentName,
                            style: const TextStyle(
                              color: AppColors.greyText,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
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
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      onChanged: onActiveToggle,
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
            ),
          ),
          if (valve.isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Column(
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _dayButton(
                          label: 'All',
                          selected: allSelected,
                          onTap: onAllDaysTap,
                          isAll: true,
                        ),
                        const SizedBox(width: 8),
                        for (var day = 0; day < 7; day++) ...[
                          _dayButton(
                            label: _dayShortLabels[day],
                            selected: valve.selectedDays.contains(day),
                            onTap: () => onDayTap(day),
                          ),
                          if (day < 6) const SizedBox(width: 8),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  for (var day = 0; day < 7; day++)
                    if (valve.selectedDays.contains(day)) ...[
                      _dayScheduleView(
                        context,
                        _dayFullLabels[day],
                        valve.daySchedules[day] ?? const <_TimeRange>[],
                      ),
                      const SizedBox(height: 6),
                    ],
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Last update: ${_formatDateTime(valve.lastUpdated)}',
                      style: const TextStyle(
                        color: AppColors.greyText,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
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

  Widget _dayScheduleView(
    BuildContext context,
    String dayLabel,
    List<_TimeRange> ranges,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 86,
          child: Text(
            dayLabel,
            style: const TextStyle(
              color: AppColors.darkText,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
        Expanded(
          child: ranges.isEmpty
              ? const Text(
                  'No time slots',
                  style: TextStyle(color: AppColors.greyText, fontSize: 13),
                )
              : Wrap(
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
        ),
      ],
    );
  }

  Future<List<_TimeRange>?> _openDayTimeDialog({
    required BuildContext context,
    required String dayLabel,
    required List<_TimeRange> initialRanges,
  }) {
    return showDialog<List<_TimeRange>>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _DayTimeDialog(
        dayLabel: dayLabel,
        initialRanges: List<_TimeRange>.from(initialRanges),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final local = dateTime.toLocal();
    final hour24 = local.hour;
    final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
    final period = hour24 >= 12 ? 'PM' : 'AM';
    final minute = local.minute.toString().padLeft(2, '0');
    final second = local.second.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year.toString();
    return '$hour12:$minute:$second $period $day/$month/$year';
  }
}

class _ValveSettingArgs {
  const _ValveSettingArgs({required this.deviceId, required this.components});

  final String deviceId;
  final List<String> components;

  factory _ValveSettingArgs.fromDevice(CustomerDeviceSummary device) {
    return _ValveSettingArgs(
      deviceId: device.espId,
      components: List<String>.from(device.components),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is _ValveSettingArgs &&
        other.deviceId == deviceId &&
        listEquals(other.components, components);
  }

  @override
  int get hashCode => Object.hash(deviceId, Object.hashAll(components));
}

class _ValveSettingState {
  const _ValveSettingState({required this.valves});

  final List<_ValveCardModel> valves;

  _ValveSettingState copyWith({List<_ValveCardModel>? valves}) {
    return _ValveSettingState(valves: valves ?? this.valves);
  }
}

class _ValveCardModel {
  const _ValveCardModel({
    required this.valveLabel,
    required this.componentName,
    required this.isActive,
    required this.selectedDays,
    required this.daySchedules,
    required this.lastUpdated,
    required this.isExpanded,
  });

  final String valveLabel;
  final String componentName;
  final bool isActive;
  final Set<int> selectedDays;
  final Map<int, List<_TimeRange>> daySchedules;
  final DateTime lastUpdated;
  final bool isExpanded;

  _ValveCardModel copyWith({
    String? valveLabel,
    String? componentName,
    bool? isActive,
    Set<int>? selectedDays,
    Map<int, List<_TimeRange>>? daySchedules,
    DateTime? lastUpdated,
    bool? isExpanded,
  }) {
    return _ValveCardModel(
      valveLabel: valveLabel ?? this.valveLabel,
      componentName: componentName ?? this.componentName,
      isActive: isActive ?? this.isActive,
      selectedDays: selectedDays ?? this.selectedDays,
      daySchedules: daySchedules ?? this.daySchedules,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isExpanded: isExpanded ?? this.isExpanded,
    );
  }
}

class _TimeRange {
  const _TimeRange({required this.start, required this.end});

  final TimeOfDay start;
  final TimeOfDay end;
}

final _valveSettingProvider = NotifierProvider.autoDispose
    .family<_ValveSettingNotifier, _ValveSettingState, _ValveSettingArgs>(
      _ValveSettingNotifier.new,
    );

class _ValveSettingNotifier extends Notifier<_ValveSettingState> {
  _ValveSettingNotifier(this.args);

  final _ValveSettingArgs args;

  @override
  _ValveSettingState build() {
    final componentCount = args.components.isEmpty ? 1 : args.components.length;
    final valves = List<_ValveCardModel>.generate(componentCount, (index) {
      final componentName = index < args.components.length
          ? args.components[index]
          : '';
      return _ValveCardModel(
        valveLabel: 'Valve ${index + 1}',
        componentName: componentName,
        isActive: true,
        selectedDays: <int>{},
        daySchedules: <int, List<_TimeRange>>{},
        lastUpdated: DateTime.now(),
        isExpanded: index == 0,
      );
    });
    return _ValveSettingState(valves: valves);
  }

  void toggleExpanded(int index) {
    final valves = List<_ValveCardModel>.from(state.valves);
    final valve = valves[index];
    valves[index] = valve.copyWith(isExpanded: !valve.isExpanded);
    state = state.copyWith(valves: valves);
  }

  void toggleActive(int index, bool value) {
    final valves = List<_ValveCardModel>.from(state.valves);
    final valve = valves[index];
    valves[index] = valve.copyWith(
      isActive: value,
      lastUpdated: DateTime.now(),
    );
    state = state.copyWith(valves: valves);
  }

  void toggleAllDays(int index) {
    final valves = List<_ValveCardModel>.from(state.valves);
    final valve = valves[index];
    final allSelected = valve.selectedDays.length == 7;
    final nextSelected = allSelected
        ? <int>{}
        : Set<int>.from(List<int>.generate(7, (i) => i));
    final nextSchedules = Map<int, List<_TimeRange>>.from(valve.daySchedules);
    if (allSelected) {
      nextSchedules.clear();
    }
    valves[index] = valve.copyWith(
      selectedDays: nextSelected,
      daySchedules: nextSchedules,
      lastUpdated: DateTime.now(),
    );
    state = state.copyWith(valves: valves);
  }

  void setDayRanges(int index, int day, List<_TimeRange> ranges) {
    final valves = List<_ValveCardModel>.from(state.valves);
    final valve = valves[index];

    final nextSelected = Set<int>.from(valve.selectedDays);
    final nextSchedules = Map<int, List<_TimeRange>>.from(valve.daySchedules);

    if (ranges.isEmpty) {
      nextSelected.remove(day);
      nextSchedules.remove(day);
    } else {
      nextSelected.add(day);
      nextSchedules[day] = List<_TimeRange>.from(ranges);
    }

    valves[index] = valve.copyWith(
      selectedDays: nextSelected,
      daySchedules: nextSchedules,
      lastUpdated: DateTime.now(),
    );
    state = state.copyWith(valves: valves);
  }
}

final _dayTimeDialogProvider = NotifierProvider.autoDispose
    .family<_DayTimeDialogNotifier, List<_TimeRange>, List<_TimeRange>>(
      _DayTimeDialogNotifier.new,
    );

class _DayTimeDialogNotifier extends Notifier<List<_TimeRange>> {
  _DayTimeDialogNotifier(this.initialRanges);

  final List<_TimeRange> initialRanges;

  @override
  List<_TimeRange> build() {
    return List<_TimeRange>.from(initialRanges);
  }

  void addRange() {
    state = [
      ...state,
      const _TimeRange(
        start: TimeOfDay(hour: 8, minute: 0),
        end: TimeOfDay(hour: 9, minute: 0),
      ),
    ];
  }

  void removeAt(int index) {
    final next = List<_TimeRange>.from(state)..removeAt(index);
    state = next;
  }

  void updateTime(int index, bool isStart, TimeOfDay value) {
    final next = List<_TimeRange>.from(state);
    final current = next[index];
    next[index] = isStart
        ? _TimeRange(start: value, end: current.end)
        : _TimeRange(start: current.start, end: value);
    state = next;
  }
}

class _DayTimeDialog extends ConsumerWidget {
  const _DayTimeDialog({required this.dayLabel, required this.initialRanges});

  final String dayLabel;
  final List<_TimeRange> initialRanges;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ranges = ref.watch(_dayTimeDialogProvider(initialRanges));
    final notifier = ref.read(_dayTimeDialogProvider(initialRanges).notifier);

    return Theme(
      data: theme.copyWith(
        colorScheme: theme.colorScheme.copyWith(
          primary: AppColors.primaryTeal,
          onPrimary: AppColors.white,
          surface: AppColors.white,
          onSurface: AppColors.darkText,
        ),
        textTheme: theme.textTheme.apply(
          bodyColor: AppColors.darkText,
          displayColor: AppColors.darkText,
        ),
        dialogTheme: const DialogThemeData(backgroundColor: AppColors.white),
      ),
      child: AlertDialog(
        backgroundColor: AppColors.white,
        title: Text(
          '$dayLabel Timers',
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
                      for (var i = 0; i < ranges.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: _slotButton(
                                  label: ranges[i].start.format(context),
                                  onTap: () async {
                                    final picked = await _pickTime(
                                      context: context,
                                      initial: ranges[i].start,
                                    );
                                    if (picked != null) {
                                      notifier.updateTime(i, true, picked);
                                    }
                                  },
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
                                  label: ranges[i].end.format(context),
                                  onTap: () async {
                                    final picked = await _pickTime(
                                      context: context,
                                      initial: ranges[i].end,
                                    );
                                    if (picked != null) {
                                      notifier.updateTime(i, false, picked);
                                    }
                                  },
                                ),
                              ),
                              IconButton(
                                tooltip: 'Delete slot',
                                onPressed: () => notifier.removeAt(i),
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
                  onPressed: notifier.addRange,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add Time'),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop<List<_TimeRange>>(null),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryTeal,
              foregroundColor: AppColors.white,
            ),
            onPressed: () => Navigator.of(
              context,
            ).pop<List<_TimeRange>>(List<_TimeRange>.from(ranges)),
            child: const Text('Save'),
          ),
        ],
      ),
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
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
            child: child!,
          ),
        );
      },
    );
  }
}
