import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wms/core/core.dart';
import 'package:wms/shared/shared.dart';
import 'package:wms/user/features/dashboard/providers/providers.dart';
import 'package:wms/user/features/dashboard/widgets/profile_tab_screens.dart';
import 'package:wms/user/features/dashboard/widgets/profile_tab_sections.dart';

class ProfileTabView extends ConsumerWidget {
  const ProfileTabView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    final logoutState = ref.watch(authLogoutControllerProvider);

    return profileAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primaryTeal),
      ),
      error: (error, _) => ProfileErrorView(
        message: error is ApiException
            ? error.message
            : 'Unable to load profile.',
        onRetry: () => ref.invalidate(userProfileProvider),
      ),
      data: (profile) {
        return RefreshIndicator(
          color: AppColors.primaryTeal,
          onRefresh: () async => ref.invalidate(userProfileProvider),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
            children: [
              ProfileHeroCard(
                profile: profile,
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => EditProfileScreen(profile: profile),
                    ),
                  );
                },
              ),
              const SizedBox(height: 18),
              QuickInfoRow(profile: profile),
              const SizedBox(height: 22),
              const Text(
                'Account',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.darkText,
                ),
              ),
              const SizedBox(height: 12),
              ActionTile(
                icon: Icons.lock_rounded,
                iconColor: const Color(0xFF2C6BED),
                title: 'Change Password',
                subtitle: 'Protect your account with a new password',
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ChangePasswordScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              ActionTile(
                icon: Icons.logout_rounded,
                iconColor: AppColors.red,
                title: 'Logout',
                subtitle: 'Sign out from this device',
                trailing: logoutState.isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.red,
                        ),
                      )
                    : null,
                onTap: logoutState.isLoading
                    ? null
                    : () async {
                        final shouldLogout = await showDialog<bool>(
                          context: context,
                          builder: (_) => const LogoutConfirmDialog(),
                        );
                        if (shouldLogout != true) {
                          return;
                        }
                        final sessionId = ref
                            .read(currentAuthSessionProvider)
                            ?.sessionId;
                        await ref
                            .read(authLogoutControllerProvider.notifier)
                            .logout(sessionId: sessionId);
                      },
              ),
            ],
          ),
        );
      },
    );
  }
}
