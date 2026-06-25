import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wms/core/core.dart';
import 'package:wms/shared/shared.dart';
import 'package:wms/user/features/auth/screens/session_expiry_navigation.dart';
import 'package:wms/user/features/dashboard/dashboard.dart';
import 'package:wms/user/features/valves/screens/valve_setting_dialogs.dart';

import '../../../valves/screens/valve_setting_screen.dart';
import '../../screens/motor_setting_screen.dart';

part 'dashboard_tab_alerts.dart';
part 'dashboard_tab_device_card.dart';
part 'dashboard_tab_helpers.dart';
part 'dashboard_tab_motor_section.dart';
part 'dashboard_tab_state_cards.dart';
part 'dashboard_tab_valves_section.dart';
part 'dashboard_tab_weather.dart';

class DashboardTabView extends ConsumerWidget {
  const DashboardTabView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devicesAsync = ref.watch(customerDashboardDevicesProvider);
    final searchQuery = ref.watch(dashboardSearchQueryProvider).toLowerCase();

    return Column(
      children: [
        // Weather widget is temporarily hidden. We will use this feature again
        // once the dashboard header design is finalized.
        Expanded(
          child: Container(
            color: AppColors.white,
            child: RefreshIndicator(
              onRefresh: () async {
                await ref
                    .read(dashboardRefreshControllerProvider.notifier)
                    .refreshDashboard();
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                children: [
                  TextField(
                    onChanged: (value) {
                      ref
                          .read(dashboardSearchQueryProvider.notifier)
                          .setQuery(value);
                    },
                    decoration: InputDecoration(
                      hintText: 'Search Device',
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: AppColors.blue,
                        size: 28,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 16,
                      ),
                      fillColor: AppColors.white,
                      filled: true,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: AppColors.lightGreyText,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: AppColors.primaryTeal,
                          width: 1.4,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  devicesAsync.when(
                    data: (devices) {
                      final expiryMessage = _buildExpiryAlertMessage(devices);
                      final filteredDevices = devices.where((device) {
                        if (searchQuery.isEmpty) {
                          return true;
                        }
                        final displayName = device.displayName.toLowerCase();
                        final espId = device.espId.toLowerCase();
                        return displayName.contains(searchQuery) ||
                            espId.contains(searchQuery);
                      }).toList();

                      final deviceSection = filteredDevices.isEmpty
                          ? const [_DeviceEmptyCard()]
                          : <Widget>[
                              for (
                                var i = 0;
                                i < filteredDevices.length;
                                i++
                              ) ...[
                                _DashboardDeviceCard(
                                  device: filteredDevices[i],
                                ),
                                if (i < filteredDevices.length - 1)
                                  const SizedBox(height: 12),
                              ],
                            ];

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (expiryMessage != null) ...[
                            _AlertMarquee(message: expiryMessage),
                            const SizedBox(height: 14),
                          ],
                          ...deviceSection,
                        ],
                      );
                    },
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: CircularProgressIndicator(
                          color: AppColors.primaryTeal,
                        ),
                      ),
                    ),
                    error: (error, _) {
                      final message = error is ApiException
                          ? error.message
                          : 'Unable to load devices';
                      final isSessionExpired = isSessionExpiredMessage(message);
                      return _DeviceErrorCard(
                        message: message,
                        actionLabel: isSessionExpired ? 'Login' : 'Retry',
                        onRetry: () => isSessionExpired
                            ? navigateToUserLogin(context)
                            : unawaited(
                                ref.refresh(
                                  customerDashboardDevicesProvider.future,
                                ),
                              ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
