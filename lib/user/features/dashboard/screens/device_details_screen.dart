import 'package:flutter/material.dart';
import 'package:wms/shared/shared.dart';
import 'package:wms/user/features/dashboard/screens/motor_setting_screen.dart';
import 'package:wms/user/features/dashboard/services/customer_devices_service.dart';
import 'package:wms/user/features/valves/screens/valve_setting_screen.dart';

class DeviceDetailsScreen extends StatelessWidget {
  const DeviceDetailsScreen({required this.device, super.key});

  final CustomerDeviceSummary device;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        surfaceTintColor: AppColors.white,
        elevation: 2,
        shadowColor: const Color(0x26000000),
        title: Text(device.displayName.isEmpty ? '-' : device.displayName),
      ),
      body: AppPageBody(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            AppSectionCard(
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(14, 14, 14, 8),
                    child: Text(
                      'Settings',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.darkText,
                      ),
                    ),
                  ),
                  _settingsTile(
                    context: context,
                    title: 'Valve',
                    imageAsset: AppAssets.valve,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ValveSettingScreen(device: device),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1, indent: 14, endIndent: 14),
                  _settingsTile(
                    context: context,
                    title: 'Motor',
                    imageAsset: AppAssets.motor,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => MotorSettingScreen(device: device),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            AppSectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Device Details',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _detailRow('ESP ID', device.espId),
                  _detailRow('MAC Address', device.macAddress),
                  _detailRow('FW Version', device.fwVersion),
                  _detailRow(
                    'Last Heartbeat',
                    _formatDateTime(device.lastHeartbeat),
                  ),
                  _detailRow('AMC Expiry', device.amcExpiry),
                  _detailRow('Created At', _formatDateTime(device.createdAt)),
                  _detailRow('Active', device.isActive ? 'Yes' : 'No'),
                  _detailRow('Online', device.isOnline ? 'Yes' : 'No'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            AppSectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Device SIM Details',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _detailRow('Recharge Expiry', device.rechargeExpiry),
                  _detailRow('SIM Card Number', device.simCardNumber),
                  _detailRow('Network Provider', device.networkProvider),
                  _detailRow('Plan Expiry', _formatDateTime(device.planExpiry)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            AppSectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Components',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (device.components.isEmpty)
                    const Text(
                      'No components available',
                      style: TextStyle(color: AppColors.greyText),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final component in device.components)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.lightBlue.withValues(
                                alpha: 0.25,
                              ),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              component,
                              style: const TextStyle(
                                color: AppColors.darkText,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    final normalized = value.trim().isEmpty ? '-' : value.trim();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.greyText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              normalized,
              style: const TextStyle(
                color: AppColors.darkText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(String value) {
    return AppDateTimeFormatter.formatString(value);
  }

  Widget _settingsTile({
    required BuildContext context,
    required String title,
    String? imageAsset,
    IconData? icon,
    VoidCallback? onTap,
  }) {
    final textColor = onTap == null ? AppColors.greyText : AppColors.darkText;
    final iconColor = onTap == null
        ? AppColors.greyText
        : AppColors.primaryTeal;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: imageAsset != null
                    ? Image.asset(
                        imageAsset,
                        color: iconColor,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          icon ?? Icons.settings_rounded,
                          color: iconColor,
                          size: 20,
                        ),
                      )
                    : Icon(
                        icon ?? Icons.settings_rounded,
                        color: iconColor,
                        size: 20,
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: onTap == null
                    ? AppColors.lightGreyText
                    : AppColors.greyText,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
