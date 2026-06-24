part of 'dashboard_tab_view.dart';

class _ValvesSection extends ConsumerWidget {
  const _ValvesSection({required this.device});

  final CustomerDeviceSummary device;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final valves = device.valves;
    final activeValves = valves.where((v) => v.isOn).toList();
    final activeValveCount = activeValves.length;
    final valveNames = activeValves.map((v) => v.name).join(', ');

    final showAllValvesOff = device.allValvesOff;
    final expandKey = device.espId.isNotEmpty
        ? device.espId
        : device.displayName;
    final expanded =
        ref.watch(dashboardValvesExpandedProvider)[expandKey] ?? false;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.lightGreyText),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: showAllValvesOff || valves.isEmpty
                ? null
                : () {
                    ref
                        .read(dashboardValvesExpandedProvider.notifier)
                        .toggle(expandKey);
                  },
            child: Opacity(
              opacity: (showAllValvesOff || valves.isEmpty) ? 0.7 : 1.0,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Valves',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.darkText,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            showAllValvesOff
                                ? 'All valves are off'
                                : '$valveNames valve${activeValveCount == 1 ? '' : 's'} on',
                            style: TextStyle(
                              fontSize: 13,
                              color: showAllValvesOff
                                  ? AppColors.red
                                  : AppColors.accentGreen,
                              fontWeight: showAllValvesOff
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!showAllValvesOff && valves.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Icon(
                        expanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: AppColors.greyText,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          if (!showAllValvesOff && valves.isNotEmpty && expanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Column(
                children: [
                  for (var i = 0; i < valves.length; i++) ...[
                    _ValveRow(valve: valves[i]),
                    if (i < valves.length - 1)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Divider(height: 1),
                      ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ValveRow extends StatelessWidget {
  const _ValveRow({required this.valve});

  final CustomerValveSummary valve;

  @override
  Widget build(BuildContext context) {
    final valveName = valve.name.trim().isEmpty ? 'Valve' : valve.name;
    final valveMode = valve.mode.trim();
    final normalizedMode = valveMode.trim();
    final title = normalizedMode.isEmpty
        ? valveName
        : '$valveName ($normalizedMode)';

    return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accentGreen.withValues(alpha: 0.12),
            ),
            child: Center(
              child: Image.asset(
                AppAssets.valve,
                width: 20,
                height: 20,
                color: AppColors.accentGreen,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.tune_rounded,
                  size: 20,
                  color: AppColors.accentGreen,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.darkText,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _ValveRemainingClock(
                      onTime: valve.onTime,
                      offTime: valve.offTime,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                _DetailLine(
                  iconData: Icons.location_on_rounded,
                  value: valve.installedArea,
                ),
                const SizedBox(height: 6),
                _DetailLine(
                  iconData: Icons.schedule_sharp,
                  value: _formatDateTimeRange(valve.onTime, valve.offTime),
                ),
              ],
            ),
          ),
        ],
      );
  }
}

class _ValveRemainingClock extends ConsumerWidget {
  const _ValveRemainingClock({required this.onTime, required this.offTime});

  final String onTime;
  final String offTime;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nowAsync = ref.watch(currentTimeProvider);
    final now = nowAsync.value ?? DateTime.now();
    final remaining = _remainingValveTime(
      onTime: onTime,
      offTime: offTime,
      now: now,
    );
    if (remaining == null) {
      return const SizedBox.shrink();
    }

    return Container(
      constraints: const BoxConstraints(minWidth: 80),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.red.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.schedule_rounded, size: 14, color: AppColors.red),
          const SizedBox(width: 4),
          Text(
            _formatDurationClock(remaining),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.red,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.iconData, required this.value});

  final IconData iconData;
  final String value;

  @override
  Widget build(BuildContext context) {
    final normalized = value.trim().isEmpty ? '-' : value.trim();

    return Row(
      children: [
        Icon(
          iconData,
          size: 20,
          color: AppColors.greyText.withValues(alpha: 0.6),
        ),
        const SizedBox(width: 8),
        Text(
          normalized,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.darkText,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
