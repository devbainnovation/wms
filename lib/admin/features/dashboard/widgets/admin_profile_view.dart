import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wms/admin/features/dashboard/providers/providers.dart';
import 'package:wms/admin/features/dashboard/widgets/admin_profile_dialogs.dart';
import 'package:wms/admin/features/dashboard/widgets/admin_profile_sections.dart';
import 'package:wms/core/core.dart';
import 'package:wms/shared/shared.dart';

class AdminProfileView extends ConsumerWidget {
  const AdminProfileView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(adminProfileProvider);

    return profileAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primaryTeal),
      ),
      error: (error, _) => ProfileErrorView(
        message: error is ApiException
            ? error.message
            : 'Unable to load profile.',
        onRetry: () => ref.invalidate(adminProfileProvider),
      ),
      data: (profile) => RefreshIndicator(
        color: AppColors.primaryTeal,
        onRefresh: () async => ref.invalidate(adminProfileProvider),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            ProfileHeroCard(profile: profile),
            const SizedBox(height: 18),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                InfoCard(
                  width: 240,
                  icon: Icons.call_rounded,
                  title: 'Phone Number',
                  value: profile.phoneNumber,
                ),
                InfoCard(
                  width: 240,
                  icon: Icons.account_circle_rounded,
                  title: 'Username',
                  value: profile.username,
                ),
                InfoCard(
                  width: 240,
                  icon: Icons.location_on_rounded,
                  title: 'Village',
                  value: profile.village,
                ),
                InfoCard(
                  width: 240,
                  icon: Icons.calendar_today_rounded,
                  title: 'Created',
                  value: profile.createdAt == null
                      ? '-'
                      : AppDateTimeFormatter.formatDateTime(profile.createdAt!),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Account Actions',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.darkText,
              ),
            ),
            const SizedBox(height: 12),
            ActionTile(
              icon: Icons.edit_rounded,
              iconColor: AppColors.primaryTeal,
              title: 'Update Profile',
              subtitle: 'Edit name, email, village, and address details',
              onTap: () => showDialog<void>(
                context: context,
                builder: (_) => EditProfileDialog(profile: profile),
              ),
            ),
            const SizedBox(height: 12),
            ActionTile(
              icon: Icons.lock_rounded,
              iconColor: const Color(0xFF2C6BED),
              title: 'Change Password',
              subtitle: 'Update your password for this admin account',
              onTap: () => showDialog<void>(
                context: context,
                builder: (_) => const ChangePasswordDialog(),
              ),
            ),
            const SizedBox(height: 24),
            AddressSection(profile: profile),
          ],
        ),
      ),
    );
  }
}
