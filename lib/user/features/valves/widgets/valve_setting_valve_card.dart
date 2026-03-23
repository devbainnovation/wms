import 'package:flutter/material.dart';
import 'package:wms/shared/shared.dart';
import 'package:wms/user/features/valves/models/valve_setting_models.dart';

class ValveSettingValveCard extends StatelessWidget {
  const ValveSettingValveCard({
    required this.valve,
    required this.canControlValves,
    required this.onToggleExpanded,
    required this.onToggleActive,
    required this.onToggleManual,
    required this.scheduleChildren,
    super.key,
  });

  final ValveComponentModel valve;
  final bool canControlValves;
  final VoidCallback onToggleExpanded;
  final ValueChanged<bool> onToggleActive;
  final ValueChanged<bool> onToggleManual;
  final List<Widget> scheduleChildren;

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
                              onChanged: canControlValves ? onToggleActive : null,
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
                                AppDateTimeFormatter.formatDateTime(
                                  valve.lastUpdated,
                                ),
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
                                onChanged: canControlValves ? onToggleManual : null,
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
