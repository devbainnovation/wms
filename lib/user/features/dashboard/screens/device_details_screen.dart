import 'package:flutter/material.dart';
import 'package:wms/shared/shared.dart';
import 'package:wms/user/features/dashboard/screens/valve_setting_screen.dart';
import 'package:wms/user/features/dashboard/services/customer_devices_service.dart';

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
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ValveSettingScreen(device: device),
                  ),
                );
              },
              icon: const Icon(
                Icons.tune_rounded,
                color: AppColors.primaryTeal,
              ),
              label: const Text(
                'Valve Setting',
                style: TextStyle(color: AppColors.primaryTeal),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppSectionCard(
            child: Column(
              children: [
                _detailRow('Display Name', device.displayName),
                _detailRow('ESP ID', device.espId),
                _detailRow('MAC Address', device.macAddress),
                _detailRow('FW Version', device.fwVersion),
                _detailRow(
                  'Last Heartbeat',
                  _formatDateTime(device.lastHeartbeat),
                ),
                _detailRow('AMC Expiry', device.amcExpiry),
                _detailRow('Recharge Expiry', device.rechargeExpiry),
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
                            color: AppColors.lightBlue.withValues(alpha: 0.25),
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
}
