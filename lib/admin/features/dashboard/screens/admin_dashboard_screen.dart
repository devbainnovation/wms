import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wms/admin/features/auth/screens/admin_login_screen.dart';
import 'package:wms/admin/features/devices/screens/admin_devices_screen.dart';
import 'package:wms/core/core.dart';
import 'package:wms/shared/shared.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  int _selectedMenu = 0;

  static const _menuItems = <({String label, IconData icon})>[
    (label: 'Dashboard', icon: Icons.dashboard_rounded),
    (label: 'Customers', icon: Icons.groups_rounded),
    (label: 'Devices', icon: Icons.memory_rounded),
    (label: 'Schedules', icon: Icons.calendar_month_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final logoutState = ref.watch(authLogoutControllerProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF7FBFC),
      body: Row(
        children: [
          Container(
            width: 260,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.lightBlue, AppColors.lightGreen],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Image.asset(
                          AppAssets.logo,
                          height: 44,
                          width: 44,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                                Icons.water_drop_rounded,
                                color: AppColors.primaryTeal,
                                size: 30,
                              ),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Admin Panel',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.darkText,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    for (final indexed in _menuItems.indexed) ...[
                      _menuTile(
                        icon: indexed.$2.icon,
                        label: indexed.$2.label,
                        selected: _selectedMenu == indexed.$1,
                        onTap: () => setState(() => _selectedMenu = indexed.$1),
                      ),
                    ],
                    const Spacer(),
                    AppButton(
                      text: 'Logout',
                      isLoading: logoutState.isLoading,
                      onPressed: () async {
                        final navigator = Navigator.of(context);
                        final sessionId = ref
                            .read(currentAuthSessionProvider)
                            ?.sessionId;
                        await ref
                            .read(authLogoutControllerProvider.notifier)
                            .logout(sessionId: sessionId);

                        if (!mounted) {
                          return;
                        }

                        navigator.pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (_) => const AdminLoginScreen(),
                          ),
                          (route) => false,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: AppColors.lightGreyText.withValues(alpha: 0.8),
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.shadow,
                        blurRadius: 14,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: _AdminContentPanel(selectedMenu: _selectedMenu),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuTile({
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.white.withValues(alpha: 0.65)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColors.darkText),
              const SizedBox(width: 10),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.darkText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminContentPanel extends StatelessWidget {
  const _AdminContentPanel({required this.selectedMenu});

  final int selectedMenu;

  @override
  Widget build(BuildContext context) {
    if (selectedMenu == 2) {
      return const AdminDevicesScreen();
    }

    final contentByIndex =
        <int, ({String title, String subtitle, IconData icon})>{
          0: (
            title: 'Dashboard',
            subtitle: 'Overview cards and analytics will be integrated here.',
            icon: Icons.dashboard_rounded,
          ),
          1: (
            title: 'Customers',
            subtitle:
                'Customer list and management module will be integrated here.',
            icon: Icons.groups_rounded,
          ),
          2: (
            title: 'Devices',
            subtitle:
                'Device inventory and assignment module will be integrated here.',
            icon: Icons.memory_rounded,
          ),
          3: (
            title: 'Schedules',
            subtitle:
                'Scheduling and automation controls will be integrated here.',
            icon: Icons.calendar_month_rounded,
          ),
        };

    final content = contentByIndex[selectedMenu] ?? contentByIndex[0]!;
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(content.icon, size: 62, color: AppColors.primaryTeal),
          const SizedBox(height: 14),
          Text(
            content.title,
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              color: AppColors.darkText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content.subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.greyText,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
