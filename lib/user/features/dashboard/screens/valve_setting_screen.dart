import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wms/shared/shared.dart';
import 'package:wms/user/features/dashboard/providers/providers.dart';
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

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) {
          return;
        }
        final allowPop = await _onScreenLeave(context, ref, args);
        if (allowPop && context.mounted) {
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
            _headerCard(device: device),
            const SizedBox(height: 14),
            for (var i = 0; i < state.valves.length; i++) ...[
              _buildValveCard(
                context: context,
                valve: state.valves[i],
                onExpandToggle: () =>
                    _onExpandToggleRequested(context, ref, args, i),
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
                onSave: () => _saveValveIfValid(context, ref, args, i),
                onManualToggle: (value) => _onManualToggleChanged(
                  context,
                  ref,
                  args,
                  i,
                  value,
                ),
              ),
              if (i < state.valves.length - 1) const SizedBox(height: 12),
            ],
          ],
        ),
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
    required Future<void> Function() onSave,
    required Future<void> Function(bool value) onManualToggle,
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
                                _lastUpdateLabel(valve.lastUpdated),
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
                                onChanged: onManualToggle,
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
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      onPressed: valve.hasUnsavedChanges ? onSave : null,
                      icon: const Icon(Icons.save_rounded, size: 18),
                      label: const Text('Save'),
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

  Future<void> _onExpandToggleRequested(
    BuildContext context,
    WidgetRef ref,
    _ValveSettingArgs args,
    int tappedIndex,
  ) async {
    final state = ref.read(_valveSettingProvider(args));
    final notifier = ref.read(_valveSettingProvider(args).notifier);
    final tappedValve = state.valves[tappedIndex];

    // If currently open card with unsaved changes is being collapsed/switched,
    // ask whether to save or discard before continuing.
    final unsavedOpenIndex = state.valves.indexWhere(
      (item) => item.isExpanded && item.hasUnsavedChanges,
    );

    if (unsavedOpenIndex != -1 &&
        (unsavedOpenIndex != tappedIndex || tappedValve.isExpanded)) {
      final shouldContinue = await _confirmSaveOrDiscard(
        context: context,
        ref: ref,
        args: args,
        index: unsavedOpenIndex,
      );
      if (!shouldContinue) {
        return;
      }
    }

    notifier.toggleExpanded(tappedIndex);
  }

  Future<bool> _onScreenLeave(
    BuildContext context,
    WidgetRef ref,
    _ValveSettingArgs args,
  ) async {
    final state = ref.read(_valveSettingProvider(args));
    final unsavedIndices = <int>[
      for (var i = 0; i < state.valves.length; i++)
        if (state.valves[i].hasUnsavedChanges) i,
    ];
    if (unsavedIndices.isEmpty) {
      return true;
    }

    final shouldContinue = await _confirmSaveOrDiscard(
      context: context,
      ref: ref,
      args: args,
      index: unsavedIndices.first,
      applyToAllUnsaved: true,
    );
    return shouldContinue;
  }

  Future<void> _saveValveIfValid(
    BuildContext context,
    WidgetRef ref,
    _ValveSettingArgs args,
    int index,
  ) async {
    final state = ref.read(_valveSettingProvider(args));
    final valve = state.valves[index];
    final validationError = _validateValveForSave(valve);
    if (validationError != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(validationError)));
      return;
    }

    ref.read(_valveSettingProvider(args).notifier).saveValve(index);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Timer settings saved.')));
  }

  Future<bool> _confirmSaveOrDiscard({
    required BuildContext context,
    required WidgetRef ref,
    required _ValveSettingArgs args,
    required int index,
    bool applyToAllUnsaved = false,
  }) async {
    final decision = await showDialog<_UnsavedAction>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Unsaved Changes'),
        content: Text(
          applyToAllUnsaved
              ? 'You have unsaved timer records. Do you want to save before leaving?'
              : 'You have unsaved timer record. Do you want to save it?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(_UnsavedAction.cancel),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(context).pop(_UnsavedAction.discard),
            child: const Text('Don\'t Save'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(_UnsavedAction.save),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (decision == null || decision == _UnsavedAction.cancel) {
      return false;
    }
    if (!context.mounted) {
      return false;
    }

    final notifier = ref.read(_valveSettingProvider(args).notifier);
    if (decision == _UnsavedAction.discard) {
      if (applyToAllUnsaved) {
        final current = ref.read(_valveSettingProvider(args));
        for (var i = 0; i < current.valves.length; i++) {
          if (current.valves[i].hasUnsavedChanges) {
            notifier.discardValveChanges(i);
          }
        }
      } else {
        notifier.discardValveChanges(index);
      }
      return true;
    }

    if (applyToAllUnsaved) {
      final current = ref.read(_valveSettingProvider(args));
      for (var i = 0; i < current.valves.length; i++) {
        if (!current.valves[i].hasUnsavedChanges) {
          continue;
        }
        final validationError = _validateValveForSave(current.valves[i]);
        if (validationError != null) {
          if (!context.mounted) {
            return false;
          }
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(validationError)));
          return false;
        }
      }
      for (var i = 0; i < current.valves.length; i++) {
        if (current.valves[i].hasUnsavedChanges) {
          notifier.saveValve(i);
        }
      }
      return true;
    }

    final currentValve = ref.read(_valveSettingProvider(args)).valves[index];
    final validationError = _validateValveForSave(currentValve);
    if (validationError != null) {
      if (!context.mounted) {
        return false;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(validationError)));
      return false;
    }
    notifier.saveValve(index);
    return true;
  }

  String? _validateValveForSave(_ValveCardModel valve) {
    if (valve.selectedDays.length == 7) {
      for (var day = 0; day < 7; day++) {
        final ranges = valve.daySchedules[day] ?? const <_TimeRange>[];
        if (ranges.isEmpty) {
          return 'If all days are selected, every day must have at least one timer.';
        }
      }
    }

    for (final day in valve.selectedDays) {
      final ranges = valve.daySchedules[day] ?? const <_TimeRange>[];
      final validationError = _validateTimeRanges(
        ranges,
        dayLabel: _dayFullLabels[day],
        requireAtLeastOne: true,
      );
      if (validationError != null) {
        return validationError;
      }
    }

    return null;
  }

  String _lastUpdateLabel(DateTime value) {
    return AppDateTimeFormatter.formatDateTime(value);
  }

  Future<void> _triggerManualAction(
    BuildContext context,
    WidgetRef ref,
    String componentId,
    String action,
  ) async {
    final normalizedComponentId = componentId.trim();
    if (normalizedComponentId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Component ID missing for this valve.')),
      );
      return;
    }

    try {
      final response = await ref
          .read(customerManualTriggerControllerProvider.notifier)
          .trigger(componentId: normalizedComponentId, action: action);

      debugPrint(
        'MANUAL_TRIGGER action=$action componentId=$normalizedComponentId status=${response.statusCode} body=${response.data}',
      );
    } catch (error) {
      if (!context.mounted) {
        rethrow;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
      rethrow;
    }
  }

  Future<void> _onManualToggleChanged(
    BuildContext context,
    WidgetRef ref,
    _ValveSettingArgs args,
    int index,
    bool value,
  ) async {
    final notifier = ref.read(_valveSettingProvider(args).notifier);
    notifier.setManualToggle(index, value);
    final action = value ? 'ON' : 'OFF';
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('You select $action')));
    }
    try {
      await _triggerManualAction(
        context,
        ref,
        ref.read(_valveSettingProvider(args)).valves[index].componentId,
        action,
      );
    } catch (_) {
      // If API fails, revert local toggle state.
      notifier.setManualToggle(index, !value);
    }
  }
}

enum _UnsavedAction { save, discard, cancel }

class _ValveSettingArgs {
  const _ValveSettingArgs({required this.deviceId, required this.components});

  final String deviceId;
  final List<CustomerDeviceComponent> components;

  factory _ValveSettingArgs.fromDevice(CustomerDeviceSummary device) {
    final details = device.componentDetails.isNotEmpty
        ? List<CustomerDeviceComponent>.from(device.componentDetails)
        : device.components
              .map(
                (name) => CustomerDeviceComponent(
                  componentId: '',
                  displayName: name,
                ),
              )
              .toList();
    return _ValveSettingArgs(
      deviceId: device.espId,
      components: details,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! _ValveSettingArgs) {
      return false;
    }
    final sameComponents =
        components.length == other.components.length &&
        components.asMap().entries.every((entry) {
          final idx = entry.key;
          final left = entry.value;
          final right = other.components[idx];
          return left.componentId == right.componentId &&
              left.displayName == right.displayName;
        });
    return other.deviceId == deviceId && sameComponents;
  }

  @override
  int get hashCode => Object.hash(
    deviceId,
    Object.hashAll(
      components.map((item) => '${item.componentId}|${item.displayName}'),
    ),
  );
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
    required this.componentId,
    required this.isActive,
    required this.savedIsActive,
    required this.selectedDays,
    required this.savedSelectedDays,
    required this.daySchedules,
    required this.savedDaySchedules,
    required this.lastUpdated,
    required this.isExpanded,
    required this.hasUnsavedChanges,
    required this.manualActionOn,
  });

  final String valveLabel;
  final String componentName;
  final String componentId;
  final bool isActive;
  final bool savedIsActive;
  final Set<int> selectedDays;
  final Set<int> savedSelectedDays;
  final Map<int, List<_TimeRange>> daySchedules;
  final Map<int, List<_TimeRange>> savedDaySchedules;
  final DateTime lastUpdated;
  final bool isExpanded;
  final bool hasUnsavedChanges;
  final bool manualActionOn;

  _ValveCardModel copyWith({
    String? valveLabel,
    String? componentName,
    String? componentId,
    bool? isActive,
    bool? savedIsActive,
    Set<int>? selectedDays,
    Set<int>? savedSelectedDays,
    Map<int, List<_TimeRange>>? daySchedules,
    Map<int, List<_TimeRange>>? savedDaySchedules,
    DateTime? lastUpdated,
    bool? isExpanded,
    bool? hasUnsavedChanges,
    bool? manualActionOn,
  }) {
    return _ValveCardModel(
      valveLabel: valveLabel ?? this.valveLabel,
      componentName: componentName ?? this.componentName,
      componentId: componentId ?? this.componentId,
      isActive: isActive ?? this.isActive,
      savedIsActive: savedIsActive ?? this.savedIsActive,
      selectedDays: selectedDays ?? this.selectedDays,
      savedSelectedDays: savedSelectedDays ?? this.savedSelectedDays,
      daySchedules: daySchedules ?? this.daySchedules,
      savedDaySchedules: savedDaySchedules ?? this.savedDaySchedules,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isExpanded: isExpanded ?? this.isExpanded,
      hasUnsavedChanges: hasUnsavedChanges ?? this.hasUnsavedChanges,
      manualActionOn: manualActionOn ?? this.manualActionOn,
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
          ? args.components[index].displayName
          : '';
      final componentId = index < args.components.length
          ? args.components[index].componentId
          : '';
      return _ValveCardModel(
        valveLabel: 'Valve ${index + 1}',
        componentName: componentName,
        componentId: componentId,
        isActive: true,
        savedIsActive: true,
        selectedDays: <int>{},
        savedSelectedDays: <int>{},
        daySchedules: <int, List<_TimeRange>>{},
        savedDaySchedules: <int, List<_TimeRange>>{},
        lastUpdated: DateTime.now(),
        isExpanded: index == 0,
        hasUnsavedChanges: false,
        manualActionOn: false,
      );
    });
    return _ValveSettingState(valves: valves);
  }

  void toggleExpanded(int index) {
    final valves = List<_ValveCardModel>.from(state.valves);
    final nextExpanded = !valves[index].isExpanded;
    for (var i = 0; i < valves.length; i++) {
      valves[i] = valves[i].copyWith(isExpanded: i == index && nextExpanded);
    }
    state = state.copyWith(valves: valves);
  }

  void toggleActive(int index, bool value) {
    final valves = List<_ValveCardModel>.from(state.valves);
    final valve = valves[index];
    final next = valve.copyWith(isActive: value);
    valves[index] = next.copyWith(hasUnsavedChanges: _isDirty(next));
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
    final next = valve.copyWith(
      selectedDays: nextSelected,
      daySchedules: nextSchedules,
    );
    valves[index] = next.copyWith(hasUnsavedChanges: _isDirty(next));
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

    final next = valve.copyWith(
      selectedDays: nextSelected,
      daySchedules: nextSchedules,
    );
    valves[index] = next.copyWith(hasUnsavedChanges: _isDirty(next));
    state = state.copyWith(valves: valves);
  }

  void saveValve(int index) {
    final valves = List<_ValveCardModel>.from(state.valves);
    final valve = valves[index];
    valves[index] = valve.copyWith(
      savedIsActive: valve.isActive,
      savedSelectedDays: Set<int>.from(valve.selectedDays),
      savedDaySchedules: _cloneSchedules(valve.daySchedules),
      lastUpdated: DateTime.now(),
      hasUnsavedChanges: false,
    );
    state = state.copyWith(valves: valves);
  }

  void discardValveChanges(int index) {
    final valves = List<_ValveCardModel>.from(state.valves);
    final valve = valves[index];
    valves[index] = valve.copyWith(
      isActive: valve.savedIsActive,
      selectedDays: Set<int>.from(valve.savedSelectedDays),
      daySchedules: _cloneSchedules(valve.savedDaySchedules),
      hasUnsavedChanges: false,
    );
    state = state.copyWith(valves: valves);
  }

  bool _isDirty(_ValveCardModel valve) {
    if (valve.isActive != valve.savedIsActive) {
      return true;
    }
    if (!setEquals(valve.selectedDays, valve.savedSelectedDays)) {
      return true;
    }
    return !_areSchedulesEqual(valve.daySchedules, valve.savedDaySchedules);
  }

  void setManualToggle(int index, bool value) {
    final valves = List<_ValveCardModel>.from(state.valves);
    final valve = valves[index];
    valves[index] = valve.copyWith(manualActionOn: value);
    state = state.copyWith(valves: valves);
  }
}

Map<int, List<_TimeRange>> _cloneSchedules(Map<int, List<_TimeRange>> source) {
  return {
    for (final entry in source.entries)
      entry.key: List<_TimeRange>.from(entry.value),
  };
}

bool _areSchedulesEqual(
  Map<int, List<_TimeRange>> a,
  Map<int, List<_TimeRange>> b,
) {
  if (a.length != b.length) {
    return false;
  }
  for (final entry in a.entries) {
    final right = b[entry.key];
    if (right == null || right.length != entry.value.length) {
      return false;
    }
    for (var i = 0; i < entry.value.length; i++) {
      if (!_sameTime(entry.value[i].start, right[i].start) ||
          !_sameTime(entry.value[i].end, right[i].end)) {
        return false;
      }
    }
  }
  return true;
}

bool _sameTime(TimeOfDay a, TimeOfDay b) {
  return a.hour == b.hour && a.minute == b.minute;
}

String? _validateTimeRanges(
  List<_TimeRange> ranges, {
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

  final sorted = List<_TimeRange>.from(ranges)
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
            onPressed: () {
              final validationError = _validationMessage(ranges);
              if (validationError != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(validationError)),
                );
                return;
              }
              Navigator.of(
                context,
              ).pop<List<_TimeRange>>(List<_TimeRange>.from(ranges));
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  String? _validationMessage(List<_TimeRange> ranges) {
    return _validateTimeRanges(ranges, requireAtLeastOne: true);
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
