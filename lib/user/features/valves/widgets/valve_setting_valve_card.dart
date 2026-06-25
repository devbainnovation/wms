import 'package:flutter/material.dart';
import 'package:wms/shared/shared.dart';
import 'package:wms/user/features/valves/models/models.dart';

class ValveSettingValveCard extends StatelessWidget {
  const ValveSettingValveCard({
    required this.valve,
    required this.canControlValves,
    required this.onToggleExpanded,
    required this.onToggleManual,
    required this.scheduleChildren,
    this.onRename,
    super.key,
  });

  final ValveComponentModel valve;
  final bool canControlValves;
  final VoidCallback onToggleExpanded;
  final ValueChanged<bool> onToggleManual;
  final List<Widget> scheduleChildren;
  final VoidCallback? onRename;

  @override
  Widget build(BuildContext context) {
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
            onTap: onToggleExpanded,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ValveHeader(
                    valve: valve,
                    onRename: onRename,
                  ),
                  if (valve.componentName.trim().isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            valve.componentName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.greyText,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _ScheduleSummaryBadge(valve: valve),
                      ],
                    ),
                  ],
                  const SizedBox(height: 4),
                  _ValveActionRow(
                    valve: valve,
                    canControlValves: canControlValves,
                    onToggleManual: onToggleManual,
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
                    Column(children: scheduleChildren),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ValveHeader extends StatelessWidget {
  const _ValveHeader({
    required this.valve,
    this.onRename,
  });

  final ValveComponentModel valve;
  final VoidCallback? onRename;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Row(
            children: [
              Flexible(
                child: Text(
                  valve.valveLabel,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkText,
                  ),
                ),
              ),
              if (onRename != null) ...[
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: onRename,
                  child: const Icon(
                    Icons.edit_rounded,
                    size: 16,
                    color: AppColors.primaryTeal,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 8),
        Icon(
          valve.isExpanded
              ? Icons.expand_less_rounded
              : Icons.expand_more_rounded,
          color: AppColors.greyText,
        ),
      ],
    );
  }
}

class _ValveActionRow extends StatelessWidget {
  const _ValveActionRow({
    required this.valve,
    required this.canControlValves,
    required this.onToggleManual,
  });

  final ValveComponentModel valve;
  final bool canControlValves;
  final ValueChanged<bool> onToggleManual;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: _ValveInfoRow(
            icon: Icons.access_time_rounded,
            text: AppDateTimeFormatter.formatDateTime(valve.lastUpdated),
            iconSize: 18,
            fontSize: 12,
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
                scale: 0.85, // Increased slightly from 0.78 for better UX
                child: Switch(
                  value: valve.manualActionOn,
                  activeThumbColor: AppColors.accentGreen,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onChanged: canControlValves ? onToggleManual : null,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _ValveInfoRow extends StatelessWidget {
  const _ValveInfoRow({
    required this.icon,
    required this.text,
    this.iconSize = 16,
    this.fontSize = 13,
    this.color = AppColors.greyText,
  });

  final IconData icon;
  final String text;
  final double iconSize;
  final double fontSize;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: iconSize, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: fontSize,
            ),
          ),
        ),
      ],
    );
  }
}

class _ScheduleSummaryBadge extends StatelessWidget {
  const _ScheduleSummaryBadge({required this.valve});

  final ValveComponentModel valve;

  @override
  Widget build(BuildContext context) {
    if (valve.isLoadingSchedules && !valve.hasLoadedSchedules) {
      return const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppColors.primaryTeal,
        ),
      );
    }

    final savedScheduleCount = valve.savedScheduleCount;
    if (!valve.hasLoadedSchedules && savedScheduleCount == 0) {
      return const SizedBox.shrink();
    }

    if (savedScheduleCount == 0) {
      return const Text(
        'No schedule',
        style: TextStyle(
          color: AppColors.greyText,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.lightGreen,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.schedule_rounded,
            size: 14,
            color: AppColors.accentGreen,
          ),
          const SizedBox(width: 4),
          Text(
            '$savedScheduleCount schedule${savedScheduleCount == 1 ? '' : 's'}',
            style: const TextStyle(
              color: AppColors.darkTeal,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
