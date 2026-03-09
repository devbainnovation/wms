import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wms/core/core.dart';
import 'package:wms/shared/shared.dart';
import 'package:wms/user/features/dashboard/providers/providers.dart';
import 'package:wms/user/features/dashboard/screens/device_details_screen.dart';
import 'package:wms/user/features/dashboard/services/customer_devices_service.dart';
import 'package:wms/user/features/dashboard/services/weather_service.dart';

class DashboardTabView extends ConsumerWidget {
  const DashboardTabView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weatherAsync = ref.watch(currentWeatherProvider);
    final devicesAsync = ref.watch(customerDevicesListProvider);

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          color: AppColors.white,
          child: weatherAsync.when(
            data: (weather) => _WeatherCard(
              weather: weather,
              onRefresh: () => ref.invalidate(currentWeatherProvider),
            ),
            loading: () => const _WeatherLoadingCard(),
            error: (error, _) => _WeatherErrorCard(
              onRetry: () => ref.invalidate(currentWeatherProvider),
            ),
          ),
        ),
        Expanded(
          child: Container(
            color: AppColors.white,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search location',
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
                    if (devices.isEmpty) {
                      return const _DeviceEmptyCard();
                    }
                    return Column(
                      children: [
                        for (var i = 0; i < devices.length; i++) ...[
                          _statusCard(context: context, device: devices[i]),
                          if (i < devices.length - 1)
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
                  error: (error, _) => _DeviceErrorCard(
                    message: error is ApiException
                        ? error.message
                        : 'Unable to load devices',
                    onRetry: () => ref.invalidate(customerDevicesListProvider),
                  ),
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
    final lastUpdated = _formatDateTime(device.lastHeartbeat, device.createdAt);
    final modeLabel = device.isOnline ? 'Online' : 'Offline';
    final fwText = device.fwVersion.isEmpty ? '-' : device.fwVersion;

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
                children: [
                  Expanded(
                    child: Center(
                      child: Text(
                        displayName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.signal_cellular_alt_rounded,
                    color: AppColors.blue,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Divider(height: 1),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: device.isActive
                            ? AppColors.accentGreen.withValues(alpha: 0.12)
                            : AppColors.red.withValues(alpha: 0.12),
                      ),
                      child: Center(
                        child: Image.asset(
                          AppAssets.devicePower,
                          width: 24,
                          height: 24,
                          color: device.isActive
                              ? AppColors.accentGreen
                              : AppColors.red,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.power_settings_new_rounded,
                            size: 28,
                            color: device.isActive
                                ? AppColors.accentGreen
                                : AppColors.red,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black,
                            ),
                            children: [TextSpan(text: displayName)],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          device.isActive ? 'ON' : 'OFF',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ],
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: device.isActive
                            ? AppColors.accentGreen.withValues(alpha: 0.12)
                            : AppColors.red.withValues(alpha: 0.12),
                      ),
                      child: Center(
                        child: Image.asset(
                          AppAssets.valve,
                          width: 24,
                          height: 24,
                          color: device.isActive
                              ? AppColors.accentGreen
                              : AppColors.red,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.tune_rounded,
                            size: 24,
                            color: device.isActive
                                ? AppColors.accentGreen
                                : AppColors.red,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black,
                            ),
                            children: [
                              TextSpan(
                                text: device.espId.isEmpty ? '-' : device.espId,
                              ),
                              TextSpan(
                                text: ' ($modeLabel)',
                                style: const TextStyle(
                                  color: AppColors.greyText,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          'FW: $fwText',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.sync_rounded, color: AppColors.blue),
                  const SizedBox(width: 10),
                  Text(
                    lastUpdated,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.greyText,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateTime(String primary, String fallback) {
    final source = primary.isNotEmpty ? primary : fallback;
    return AppDateTimeFormatter.formatString(source);
  }
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
  const _DeviceErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

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
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _WeatherCard extends StatelessWidget {
  const _WeatherCard({required this.weather, required this.onRefresh});

  final WeatherData weather;
  final VoidCallback onRefresh;

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
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: onRefresh,
                      borderRadius: BorderRadius.circular(10),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.refresh_rounded, size: 18),
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
          Column(
            children: [
              Icon(
                _weatherIcon(weather.iconCode),
                size: 46,
                color: AppColors.orange,
              ),
              const SizedBox(height: 8),
              const Icon(
                Icons.water_drop_rounded,
                size: 44,
                color: AppColors.blue,
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _weatherIcon(String iconCode) {
    switch (iconCode) {
      case 'sunny':
        return Icons.wb_sunny_rounded;
      case 'rain':
        return Icons.umbrella_rounded;
      case 'cloud':
        return Icons.cloud_rounded;
      case 'partly_cloudy':
      default:
        return Icons.wb_cloudy_rounded;
    }
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
  const _WeatherErrorCard({required this.onRetry});

  final VoidCallback onRetry;

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
          const Expanded(
            child: Text(
              'Unable to load weather data',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.darkText,
              ),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
