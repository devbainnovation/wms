import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wms/admin/features/dashboard/providers/providers.dart';
import 'package:wms/admin/features/dashboard/services/services.dart';
import 'package:wms/admin/features/auth/screens/admin_login_screen.dart';
import 'package:wms/admin/features/customers/screens/admin_customers_screen.dart';
import 'package:wms/admin/features/devices/screens/admin_devices_screen.dart';
import 'package:wms/core/core.dart';
import 'package:wms/shared/shared.dart';

final adminSelectedMenuProvider =
    NotifierProvider<AdminSelectedMenuNotifier, int>(
      AdminSelectedMenuNotifier.new,
    );

class AdminSelectedMenuNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void set(int menu) => state = menu;
}

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  static const _menuItems = <({String label, IconData icon})>[
    (label: 'Dashboard', icon: Icons.dashboard_rounded),
    (label: 'Customers', icon: Icons.groups_rounded),
    (label: 'Devices', icon: Icons.memory_rounded),
    (label: 'Schedules', icon: Icons.calendar_month_rounded),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMenu = ref.watch(adminSelectedMenuProvider);
    final logoutState = ref.watch(authLogoutControllerProvider);
    final isMobile = MediaQuery.sizeOf(context).width < 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF7FBFC),
      appBar: isMobile
          ? AppBar(
              backgroundColor: AppColors.white,
              elevation: 0.5,
              title: Text(_menuItems[selectedMenu].label),
            )
          : null,
      drawer: isMobile
          ? Drawer(
              child: _AdminSidebar(
                selectedMenu: selectedMenu,
                onMenuTap: (index) {
                  ref.read(adminSelectedMenuProvider.notifier).set(index);
                  Navigator.of(context).pop();
                },
                onLogout: () => _logout(context, ref),
                isLogoutLoading: logoutState.isLoading,
              ),
            )
          : null,
      body: isMobile
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: _contentPanel(
                  isMobile: true,
                  selectedMenu: selectedMenu,
                  ref: ref,
                ),
              ),
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 260,
                  child: _AdminSidebar(
                    selectedMenu: selectedMenu,
                    onMenuTap: (index) =>
                        ref.read(adminSelectedMenuProvider.notifier).set(index),
                    onLogout: () => _logout(context, ref),
                    isLogoutLoading: logoutState.isLoading,
                  ),
                ),
                Expanded(
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: _contentPanel(
                        isMobile: false,
                        selectedMenu: selectedMenu,
                        ref: ref,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _contentPanel({
    required bool isMobile,
    required int selectedMenu,
    required WidgetRef ref,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(isMobile ? 12 : 18),
        border: Border.all(
          color: AppColors.lightGreyText.withValues(alpha: 0.8),
        ),
        boxShadow: isMobile
            ? null
            : const [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 14,
                  offset: Offset(0, 5),
                ),
              ],
      ),
      child: _AdminContentPanel(
        selectedMenu: selectedMenu,
        onMenuTap: (menuIndex) =>
            ref.read(adminSelectedMenuProvider.notifier).set(menuIndex),
      ),
    );
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final navigator = Navigator.of(context);
    final sessionId = ref.read(currentAuthSessionProvider)?.sessionId;
    await ref
        .read(authLogoutControllerProvider.notifier)
        .logout(sessionId: sessionId);

    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
      (route) => false,
    );
  }
}

class _AdminSidebar extends StatelessWidget {
  const _AdminSidebar({
    required this.selectedMenu,
    required this.onMenuTap,
    required this.onLogout,
    required this.isLogoutLoading,
  });

  final int selectedMenu;
  final ValueChanged<int> onMenuTap;
  final Future<void> Function() onLogout;
  final bool isLogoutLoading;

  static const _menuItems = <({String label, IconData icon})>[
    (label: 'Dashboard', icon: Icons.dashboard_rounded),
    (label: 'Customers', icon: Icons.groups_rounded),
    (label: 'Devices', icon: Icons.memory_rounded),
    (label: 'Schedules', icon: Icons.calendar_month_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
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
                    errorBuilder: (context, error, stackTrace) => const Icon(
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
                _SidebarMenuTile(
                  icon: indexed.$2.icon,
                  label: indexed.$2.label,
                  selected: selectedMenu == indexed.$1,
                  onTap: () => onMenuTap(indexed.$1),
                ),
              ],
              const Spacer(),
              AppButton(
                text: 'Logout',
                isLoading: isLogoutLoading,
                onPressed: onLogout,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarMenuTile extends StatelessWidget {
  const _SidebarMenuTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
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

class _AdminContentPanel extends ConsumerWidget {
  const _AdminContentPanel({
    required this.selectedMenu,
    required this.onMenuTap,
  });

  final int selectedMenu;
  final ValueChanged<int> onMenuTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (selectedMenu == 1) {
      return const AdminCustomersScreen();
    }

    if (selectedMenu == 2) {
      return const AdminDevicesScreen();
    }

    if (selectedMenu == 0) {
      final summaryState = ref.watch(adminDashboardSummaryProvider);
      return summaryState.when(
        data: (summary) =>
            _AdminDashboardOverview(summary: summary, onMenuTap: onMenuTap),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: AppColors.red, size: 48),
                const SizedBox(height: 10),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.darkText),
                ),
                const SizedBox(height: 12),
                AppButton(
                  text: 'Retry',
                  onPressed: () =>
                      ref.invalidate(adminDashboardSummaryProvider),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final contentByIndex =
        <int, ({String title, String subtitle, IconData icon})>{
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

    final content = contentByIndex[selectedMenu] ?? contentByIndex[1]!;
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

class _AdminDashboardOverview extends StatelessWidget {
  const _AdminDashboardOverview({
    required this.summary,
    required this.onMenuTap,
  });

  final AdminDashboardSummary summary;
  final ValueChanged<int> onMenuTap;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final crossAxisCount = width < 700
        ? 2
        : width < 1200
        ? 3
        : 4;
    final cardHeight = width < 700 ? 128.0 : 140.0;

    final cards = <_DashboardMetricCardData>[
      _DashboardMetricCardData(
        label: 'Total Devices',
        value: summary.totalDevices,
        targetMenu: 2,
        colors: const [Color(0xFF0093E9), Color(0xFF80D0C7)],
        icon: Icons.memory_rounded,
      ),
      _DashboardMetricCardData(
        label: 'Total Customers',
        value: summary.totalCustomers,
        targetMenu: 1,
        colors: const [Color(0xFF43CEA2), Color(0xFF185A9D)],
        icon: Icons.groups_rounded,
      ),
      _DashboardMetricCardData(
        label: 'Active Devices',
        value: summary.totalActiveDevices,
        targetMenu: 2,
        colors: const [Color(0xFF00B09B), Color(0xFF96C93D)],
        icon: Icons.check_circle_rounded,
      ),
      _DashboardMetricCardData(
        label: 'Inactive Devices',
        value: summary.totalInactiveDevices,
        targetMenu: 2,
        colors: const [Color(0xFFF2994A), Color(0xFFF2C94C)],
        icon: Icons.pause_circle_rounded,
      ),
      _DashboardMetricCardData(
        label: 'Unassigned Devices',
        value: summary.totalUnassignedDevices,
        targetMenu: 2,
        colors: const [Color(0xFF7F7FD5), Color(0xFF86A8E7)],
        icon: Icons.link_off_rounded,
      ),
      _DashboardMetricCardData(
        label: 'Active Customers',
        value: summary.totalActiveCustomers,
        targetMenu: 1,
        colors: const [Color(0xFF56AB2F), Color(0xFFA8E063)],
        icon: Icons.person_rounded,
      ),
      _DashboardMetricCardData(
        label: 'Inactive Customers',
        value: summary.totalInactiveCustomers,
        targetMenu: 1,
        colors: const [Color(0xFFB24592), Color(0xFFF15F79)],
        icon: Icons.person_off_rounded,
      ),
      _DashboardMetricCardData(
        label: 'Unassigned Customers',
        value: summary.totalUnassignedCustomers,
        targetMenu: 1,
        colors: const [Color(0xFF355C7D), Color(0xFF6C5B7B)],
        icon: Icons.group_remove_rounded,
      ),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dashboard Overview',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.darkText,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Tap a card to navigate to the related screen.',
            style: TextStyle(color: AppColors.greyText),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            itemCount: cards.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              mainAxisExtent: cardHeight,
            ),
            itemBuilder: (context, index) {
              final card = cards[index];
              return _DashboardMetricCard(
                data: card,
                onTap: () => onMenuTap(card.targetMenu),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DashboardMetricCardData {
  const _DashboardMetricCardData({
    required this.label,
    required this.value,
    required this.targetMenu,
    required this.colors,
    required this.icon,
  });

  final String label;
  final int value;
  final int targetMenu;
  final List<Color> colors;
  final IconData icon;
}

class _DashboardMetricCard extends StatelessWidget {
  const _DashboardMetricCard({required this.data, required this.onTap});

  final _DashboardMetricCardData data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: data.colors,
            ),
            boxShadow: const [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: Icon(
                    data.icon,
                    color: AppColors.white.withValues(alpha: 0.9),
                    size: 22,
                  ),
                ),
                const Spacer(),
                Text(
                  '${data.value}',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  data.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.white.withValues(alpha: 0.95),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
