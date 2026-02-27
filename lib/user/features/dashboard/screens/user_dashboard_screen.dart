import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wms/shared/shared.dart';
import 'package:wms/user/features/auth/screens/user_login_screen.dart';
import 'package:wms/user/features/dashboard/providers/providers.dart';
import 'package:wms/user/features/dashboard/services/weather_service.dart';

class UserDashboardScreen extends ConsumerWidget {
  const UserDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTab = ref.watch(userDashboardTabProvider);

    final pages = <Widget>[
      const _DashboardTabView(),
      const _TankTabView(),
      const _ProfileTabView(),
    ];

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.lightBlue, AppColors.lightGreen],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        drawer: const _UserDrawer(),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: AppColors.darkText,
          titleSpacing: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _greetingText(),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkText,
                ),
              ),
              const Text(
                'John Doe',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.darkText,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              onPressed: () {},
              icon: const Icon(
                Icons.notifications_rounded,
                color: AppColors.darkText,
                size: 30,
              ),
            ),
          ],
        ),
        extendBodyBehindAppBar: false,
        body: SafeArea(top: false, child: pages[selectedTab]),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: selectedTab,
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.lightBlue,
          selectedItemColor: AppColors.accentGreen,
          unselectedItemColor: AppColors.greyText,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          showUnselectedLabels: true,
          onTap: (value) {
            ref.read(userDashboardTabProvider.notifier).setTab(value);
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_rounded),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.water_drop_sharp),
              label: 'Tank',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  String _greetingText() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    }
    if (hour < 17) {
      return 'Good Afternoon';
    }
    return 'Good Evening';
  }
}

class _UserDrawer extends ConsumerWidget {
  const _UserDrawer();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Drawer(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.lightBlue, AppColors.lightGreen],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: const Padding(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: AppColors.white,
                      child: Icon(
                        Icons.person,
                        size: 34,
                        color: AppColors.primaryTeal,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'John Doe',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.darkText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard_rounded),
            title: const Text('Dashboard'),
            onTap: () {
              ref.read(userDashboardTabProvider.notifier).setTab(0);
              Navigator.of(context).pop();
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout_rounded),
            title: const Text('Logout'),
            onTap: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const UserLoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DashboardTabView extends ConsumerWidget {
  const _DashboardTabView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weatherAsync = ref.watch(currentWeatherProvider);

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.lightBlue, AppColors.lightGreen],
            ),
          ),
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.lightGreyText),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.shadow,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const TextField(
                    decoration: InputDecoration(
                      icon: Icon(
                        Icons.search_rounded,
                        color: AppColors.blue,
                        size: 30,
                      ),
                      hintText: 'Search location',
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const _AlertMarquee(
                  message:
                      'Recharge expires in 15 days   •   AMC expires in 10 days',
                ),
                const SizedBox(height: 14),
                _statusCard(
                  title: 'Jangar OHT',
                  deviceLabel: 'Device 1',
                  isOn: true,
                  motorTime: 'ON - 3:00 PM Today',
                  valveName: 'bapasitara',
                  mode: 'Real Time Mode',
                  valvesOn: '1 Valves ON',
                  updatedAt: '3:27:52 PM 26/02/2026',
                ),
                const SizedBox(height: 12),
                _statusCard(
                  title: 'Jangar SMT',
                  deviceLabel: 'Device 2',
                  isOn: false,
                  motorTime: 'OFF - 3:00 PM Today',
                  valveName: 'HIGHSCOOL',
                  mode: 'Real Time Mode',
                  valvesOn: '1 Valves ON',
                  updatedAt: '3:28:15 PM 26/02/2026',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _statusCard({
    required String title,
    required String deviceLabel,
    required bool isOn,
    required String motorTime,
    required String valveName,
    required String mode,
    required String valvesOn,
    required String updatedAt,
  }) {
    return Container(
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
                    title,
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
                    color: isOn
                        ? AppColors.accentGreen.withValues(alpha: 0.12)
                        : AppColors.red.withValues(alpha: 0.12),
                  ),
                  child: Center(
                    child: Image.asset(
                      AppAssets.devicePower,
                      width: 24,
                      height: 24,
                      color: isOn ? AppColors.accentGreen : AppColors.red,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.power_settings_new_rounded,
                        size: 28,
                        color: isOn ? AppColors.accentGreen : AppColors.red,
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
                        children: [TextSpan(text: deviceLabel)],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      motorTime,
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
                    color: isOn
                        ? AppColors.accentGreen.withValues(alpha: 0.12)
                        : AppColors.red.withValues(alpha: 0.12),
                  ),
                  child: Center(
                    child: Image.asset(
                      AppAssets.valve,
                      width: 24,
                      height: 24,
                      color: isOn ? AppColors.accentGreen : AppColors.red,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.tune_rounded,
                        size: 24,
                        color: isOn ? AppColors.accentGreen : AppColors.red,
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
                          TextSpan(text: valveName),
                          TextSpan(
                            text: ' ($mode)',
                            style: const TextStyle(
                              color: AppColors.greyText,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      valvesOn,
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
                updatedAt,
                style: const TextStyle(fontSize: 13, color: AppColors.greyText),
              ),
            ],
          ),
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

class _TankTabView extends StatelessWidget {
  const _TankTabView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Tank Screen',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: AppColors.darkText,
        ),
      ),
    );
  }
}

class _ProfileTabView extends StatelessWidget {
  const _ProfileTabView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Profile Screen',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: AppColors.darkText,
        ),
      ),
    );
  }
}
