part of 'dashboard_tab_view.dart';

class _DashboardDeviceCard extends StatelessWidget {
  const _DashboardDeviceCard({required this.device});

  final CustomerDeviceSummary device;

  @override
  Widget build(BuildContext context) {
    final displayName = device.displayName.isEmpty
        ? (device.espId.isEmpty ? 'Device' : device.espId)
        : device.displayName;
    final lastUpdated = _formatFullDateTime(
      device.lastHeartbeat,
      device.createdAt,
    );
    final modeLabel = device.isOnline ? 'Online' : 'Offline';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => DeviceDetailsScreen(device: device),
            ),
          );
        },
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.lightGreyText),
            boxShadow: const [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.darkText,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.timer_outlined,
                              size: 14,
                              color: AppColors.greyText,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                lastUpdated,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.greyText,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: device.isOnline
                          ? AppColors.accentGreen.withValues(alpha: 0.12)
                          : AppColors.lightGreyText.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      modeLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: device.isOnline
                            ? AppColors.accentGreen
                            : AppColors.greyText,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Divider(height: 1),
              const SizedBox(height: 14),
              InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => MotorSettingScreen(device: device),
                    ),
                  );
                },
                child: _MotorSection(device: device),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ValveSettingScreen(device: device),
                    ),
                  );
                },
                child: _ValvesSection(device: device),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatFullDateTime(String primary, String fallback) {
  final source = primary.isNotEmpty ? primary : fallback;
  return AppDateTimeFormatter.formatString(source);
}
