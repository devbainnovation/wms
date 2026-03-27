import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wms/core/core.dart';
import 'package:wms/shared/shared.dart';
import 'package:wms/user/features/auth/screens/session_expiry_navigation.dart';
import 'package:wms/user/features/dashboard/providers/providers.dart';
import 'package:wms/user/features/dashboard/screens/device_details_screen.dart';
import 'package:wms/user/features/dashboard/services/customer_devices_service.dart';
import 'package:wms/user/features/dashboard/services/weather_service.dart';
import 'package:wms/user/features/valves/screens/valve_setting_dialogs.dart';

class DashboardTabView extends ConsumerWidget {
  const DashboardTabView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weatherAsync = ref.watch(currentWeatherProvider);
    final devicesAsync = ref.watch(customerDevicesListProvider);
    final searchQuery = ref.watch(dashboardSearchQueryProvider).toLowerCase();

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          color: AppColors.white,
          child: weatherAsync.when(
            data: (weather) => _WeatherCard(weather: weather),
            loading: () => const _WeatherLoadingCard(),
            error: (error, _) {
              final message = error is ApiException
                  ? error.message
                  : 'Unable to load weather data';
              final isSessionExpired = isSessionExpiredMessage(message);
              return _WeatherErrorCard(
                message: message,
                actionLabel: isSessionExpired ? 'Login' : 'Retry',
                onRetry: () => isSessionExpired
                    ? navigateToUserLogin(context)
                    : unawaited(ref.refresh(currentWeatherProvider.future)),
              );
            },
          ),
        ),
        Expanded(
          child: Container(
            color: AppColors.white,
            child: ListView(
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
                const _AlertMarquee(
                  message:
                      'Recharge expires in 15 days   •   AMC expires in 10 days',
                ),
                const SizedBox(height: 14),
                devicesAsync.when(
                  data: (devices) {
                    final filteredDevices = devices.where((device) {
                      if (searchQuery.isEmpty) {
                        return true;
                      }
                      final displayName = device.displayName.toLowerCase();
                      final espId = device.espId.toLowerCase();
                      return displayName.contains(searchQuery) ||
                          espId.contains(searchQuery);
                    }).toList();

                    if (filteredDevices.isEmpty) {
                      return const _DeviceEmptyCard();
                    }
                    return Column(
                      children: [
                        for (var i = 0; i < filteredDevices.length; i++) ...[
                          _statusCard(
                            context: context,
                            device: filteredDevices[i],
                          ),
                          if (i < filteredDevices.length - 1)
                            const SizedBox(height: 12),
                        ],
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
                              ref.refresh(customerDevicesListProvider.future),
                            ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _statusCard({
    required BuildContext context,
    required CustomerDeviceSummary device,
  }) {
    final displayName = device.displayName.isEmpty
        ? (device.espId.isEmpty ? 'Device' : device.espId)
        : device.displayName;
    final lastUpdated = _formatFullDateTime(device.lastHeartbeat, device.createdAt);
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
              _MotorSection(device: device),
              const SizedBox(height: 12),
              _ValvesSection(device: device),
            ],
          ),
        ),
      ),
    );
  }

  String _formatFullDateTime(String primary, String fallback) {
    final source = primary.isNotEmpty ? primary : fallback;
    return AppDateTimeFormatter.formatString(source);
  }
}

class _MotorSection extends ConsumerWidget {
  const _MotorSection({required this.device});

  final CustomerDeviceSummary device;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final motor = device.motor;
    final isOn = motor?.isOn ?? false;
    final motorName = motor?.name.trim().isNotEmpty == true ? motor!.name : 'Motor';
    final motorKey = motor?.componentId.trim().isNotEmpty == true
        ? motor!.componentId
        : (device.espId.isNotEmpty ? device.espId : device.displayName);
    final submitting =
        ref.watch(dashboardMotorSubmittingProvider)[motorKey] ?? false;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.lightBlue.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isOn
                  ? AppColors.accentGreen.withValues(alpha: 0.16)
                  : AppColors.red.withValues(alpha: 0.10),
            ),
            child: Center(
              child: Image.asset(
                AppAssets.devicePower,
                width: 22,
                height: 22,
                color: isOn ? AppColors.accentGreen : AppColors.red,
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.power_settings_new_rounded,
                  size: 24,
                  color: isOn ? AppColors.accentGreen : AppColors.red,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Motor',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isOn ? '$motorName is On' : 'Motor is Off',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkText,
                  ),
                ),
                if (isOn && motor != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Started: ${_formatTimeOnly(motor.startedAt)}  •  Off at: ${_formatTimeOnly(motor.estimatedOffAt)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.greyText,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch(
            value: isOn,
            activeThumbColor: AppColors.primaryTeal,
            onChanged: submitting || motor?.componentId.trim().isEmpty != false
                ? null
                : (value) => _handleToggle(context, ref, motor!, value, motorKey),
          ),
        ],
      ),
    );
  }

  Future<void> _handleToggle(
    BuildContext context,
    WidgetRef ref,
    CustomerMotorSummary motor,
    bool value,
    String motorKey,
  ) async {
    int duration = 0;
    if (value) {
      final selectedDuration = await showManualDurationDialog(context);
      if (selectedDuration == null || !context.mounted) {
        return;
      }
      duration = selectedDuration;
    }

    ref
        .read(dashboardMotorSubmittingProvider.notifier)
        .setSubmitting(motorKey, true);
    try {
      await ref
          .read(customerManualTriggerControllerProvider.notifier)
          .trigger(
            componentId: motor.componentId,
            action: value ? 'ON' : 'OFF',
            duration: duration,
          );
      if (!context.mounted) {
        return;
      }
      ref.invalidate(customerDevicesListProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(value ? 'Motor turned on.' : 'Motor turned off.'),
        ),
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      ref
          .read(dashboardMotorSubmittingProvider.notifier)
          .setSubmitting(motorKey, false);
    }
  }
}

class _ValvesSection extends ConsumerWidget {
  const _ValvesSection({required this.device});

  final CustomerDeviceSummary device;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final valves = device.valves;
    final activeValveCount = valves.where((valve) => valve.isOn).length;
    final showAllValvesOff = device.allValvesOff;
    final expandKey = device.espId.isNotEmpty ? device.espId : device.displayName;
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
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
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
                              : '$activeValveCount valve${activeValveCount == 1 ? '' : 's'} on',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.greyText,
                            fontWeight: FontWeight.w500,
                          ),
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
                      color: AppColors.lightBlue.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '$activeValveCount',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryTeal,
                      ),
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
          if (showAllValvesOff || valves.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Text(
                'All valves are off.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.greyText,
                ),
              ),
            )
          else if (expanded) ...[
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
    final title = valve.name.trim().isEmpty ? 'Valve' : valve.name;

    return Theme(
      data: Theme.of(context),
      child: Row(
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
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkText,
                  ),
                ),
                const SizedBox(height: 6),
                _DetailLine(label: 'Location', value: valve.installedArea),
                const SizedBox(height: 6),
                _DetailLine(
                  label: 'ON Time',
                  value: _formatTimeOnly(valve.startedAt),
                ),
                const SizedBox(height: 6),
                _DetailLine(
                  label: 'OFF Time',
                  value: _formatTimeOnly(valve.estimatedOffAt),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final normalized = value.trim().isEmpty ? '-' : value.trim();

    return Row(
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.greyText,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            normalized,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.darkText,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

String _formatTimeOnly(String raw) {
  final value = raw.trim();
  if (value.isEmpty) {
    return '-';
  }
  final parsed = DateTime.tryParse(value);
  if (parsed == null) {
    return value;
  }
  final local = parsed.toLocal();
  final hour24 = local.hour;
  final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  final period = hour24 >= 12 ? 'PM' : 'AM';
  return '${hour12.toString().padLeft(2, '0')}:$minute $period';
}

class _DeviceEmptyCard extends StatelessWidget {
  const _DeviceEmptyCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.lightGreyText),
      ),
      child: const Text(
        'No devices found.',
        style: TextStyle(
          color: AppColors.greyText,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _DeviceErrorCard extends StatelessWidget {
  const _DeviceErrorCard({
    required this.message,
    required this.onRetry,
    this.actionLabel = 'Retry',
  });

  final String message;
  final VoidCallback onRetry;
  final String actionLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.lightGreyText),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: const TextStyle(
              color: AppColors.red,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          TextButton(onPressed: onRetry, child: Text(actionLabel)),
        ],
      ),
    );
  }
}

class _WeatherCard extends StatelessWidget {
  const _WeatherCard({required this.weather});

  final WeatherData weather;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      weather.city,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.greyText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${weather.temperatureCelsius}°C',
                  style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    color: AppColors.darkText,
                  ),
                ),
                Text(
                  weather.condition,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.greyText,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                _weatherIcon(weather.iconCode),
                size: 46,
                color: AppColors.orange,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.air_rounded,
                    size: 16,
                    color: AppColors.primaryTeal,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${weather.windSpeedKmh} km/h',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkText,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

IconData _weatherIcon(String iconCode) {
  switch (iconCode) {
    case 'sunny':
      return Icons.wb_sunny_rounded;
    case 'rain':
      return Icons.umbrella_rounded;
    case 'cloud':
      return Icons.cloud_rounded;
    case 'night':
      return Icons.nights_stay_rounded;
    case 'partly_cloudy':
    default:
      return Icons.wb_cloudy_rounded;
  }
}

class _AlertMarquee extends StatefulWidget {
  const _AlertMarquee({required this.message});

  final String message;

  @override
  State<_AlertMarquee> createState() => _AlertMarqueeState();
}

class _AlertMarqueeState extends State<_AlertMarquee> {
  final ScrollController _scrollController = ScrollController();
  bool _active = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runMarquee();
    });
  }

  Future<void> _runMarquee() async {
    while (mounted && _active) {
      if (!_scrollController.hasClients) {
        await Future<void>.delayed(const Duration(milliseconds: 200));
        continue;
      }

      final maxExtent = _scrollController.position.maxScrollExtent;
      if (maxExtent <= 0) {
        await Future<void>.delayed(const Duration(milliseconds: 600));
        continue;
      }

      await _scrollController.animateTo(
        maxExtent,
        duration: const Duration(seconds: 8),
        curve: Curves.linear,
      );

      if (!mounted || !_active) {
        break;
      }
      await Future<void>.delayed(const Duration(milliseconds: 500));
      _scrollController.jumpTo(0);
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
  }

  @override
  void dispose() {
    _active = false;
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFECEC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFF4A7A7)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: AppColors.red,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              child: Text(
                widget.message,
                style: const TextStyle(
                  color: AppColors.red,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeatherLoadingCard extends StatelessWidget {
  const _WeatherLoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}

class _WeatherErrorCard extends StatelessWidget {
  const _WeatherErrorCard({
    required this.onRetry,
    this.message = 'Unable to load weather data',
    this.actionLabel = 'Retry',
  });

  final VoidCallback onRetry;
  final String message;
  final String actionLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.darkText,
              ),
            ),
          ),
          TextButton(onPressed: onRetry, child: Text(actionLabel)),
        ],
      ),
    );
  }
}
