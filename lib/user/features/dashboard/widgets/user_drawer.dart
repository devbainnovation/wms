import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wms/core/core.dart';
import 'package:wms/shared/shared.dart';
import 'package:wms/user/features/dashboard/providers/providers.dart';
import 'package:wms/user/features/dashboard/screens/user_admin_users_screen.dart';

class UserDrawer extends ConsumerWidget {
  const UserDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(currentAuthSessionProvider);
    final profileAsync = ref.watch(userProfileProvider);
    final isAdmin = session?.role.toUpperCase() == 'ADMIN';

    return Drawer(
      backgroundColor: AppColors.white,
      child: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
              child: profileAsync.when(
                loading: () => const _DrawerProfileSkeleton(),
                error: (_, _) => _DrawerProfileCard(
                  title: 'Profile',
                  initials: _initials(session?.role ?? 'User'),
                  badge: session?.role ?? 'User',
                  onTap: () {
                    ref.read(userDashboardTabProvider.notifier).setTab(2);
                    Navigator.of(context).pop();
                  },
                ),
                data: (profile) => _DrawerProfileCard(
                  title: profile.fullName.isEmpty
                      ? profile.username
                      : profile.fullName,
                  initials: _initials(
                    profile.fullName.isEmpty
                        ? profile.username
                        : profile.fullName,
                  ),
                  badge: profile.role.isEmpty ? null : profile.role,
                  onTap: () {
                    ref.read(userDashboardTabProvider.notifier).setTab(2);
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard_rounded),
            title: const Text(
              'Dashboard',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            onTap: () {
              ref.read(userDashboardTabProvider.notifier).setTab(0);
              Navigator.of(context).pop();
            },
          ),
          if (isAdmin)
            ListTile(
              leading: const Icon(Icons.groups_rounded),
              title: const Text(
                'View Users',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const UserAdminUsersScreen(),
                  ),
                );
              },
            ),
          ListTile(
            leading: const Icon(Icons.logout_rounded),
            title: const Text(
              'Logout',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            onTap: () async {
              final shouldLogout = await showDialog<bool>(
                context: context,
                builder: (_) => const _DrawerLogoutConfirmDialog(),
              );
              if (shouldLogout != true) {
                return;
              }
              final sessionId = ref.read(currentAuthSessionProvider)?.sessionId;
              await ref
                  .read(authLogoutControllerProvider.notifier)
                  .logout(sessionId: sessionId);
            },
          ),
        ],
      ),
    );
  }

  static String _initials(String value) {
    final parts = value
        .split(' ')
        .where((part) => part.trim().isNotEmpty)
        .take(2)
        .toList();
    if (parts.isEmpty) {
      return 'U';
    }
    return parts.map((part) => part.trim()[0].toUpperCase()).join();
  }
}

class _DrawerProfileCard extends StatelessWidget {
  const _DrawerProfileCard({
    required this.title,
    required this.initials,
    required this.onTap,
    this.badge,
  });

  final String title;
  final String initials;
  final String? badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF4FBF8),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFD8E9E1)),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F4EC),
                  borderRadius: BorderRadius.circular(18),
                ),
                alignment: Alignment.center,
                child: Text(
                  initials,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryTeal,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.darkText,
                      ),
                    ),
                    if ((badge ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF6F0),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: const Color(0xFFD2E8DE)),
                        ),
                        child: Text(
                          badge!,
                          style: const TextStyle(
                            color: AppColors.primaryTeal,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: AppColors.greyText,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DrawerProfileSkeleton extends StatelessWidget {
  const _DrawerProfileSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 96,
      decoration: BoxDecoration(
        color: const Color(0xFFF4FBF8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFD8E9E1)),
      ),
    );
  }
}

class _DrawerLogoutConfirmDialog extends StatelessWidget {
  const _DrawerLogoutConfirmDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Text('Logout'),
      content: const Text('Are you sure you want to logout from this device?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.red,
            foregroundColor: AppColors.white,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Logout'),
        ),
      ],
    );
  }
}
