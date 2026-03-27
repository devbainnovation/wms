import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wms/shared/shared.dart';
import 'package:wms/user/features/dashboard/providers/user_admin_users_providers.dart';
import 'package:wms/user/features/dashboard/screens/user_admin_user_details_screen.dart';
import 'package:wms/user/features/dashboard/screens/user_admin_user_dialogs.dart';
import 'package:wms/user/features/dashboard/services/user_admin_users_service.dart';

class UserAdminUserCard extends ConsumerWidget {
  const UserAdminUserCard({required this.user, super.key});

  final UserAdminUserSummary user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => UserAdminUserDetailsScreen(seedUser: user),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.lightGreyText),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      user.fullName.isEmpty ? user.username : user.fullName,
                      style: const TextStyle(
                        color: AppColors.darkText,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Delete User',
                    onPressed: () async {
                      final deleted = await showDialog<bool>(
                        context: context,
                        builder: (_) => UserAdminDeleteUserDialog(user: user),
                      );

                      if (deleted == true) {
                        ref.invalidate(userAdminUsersListProvider);
                        if (!context.mounted) {
                          return;
                        }
                        showAppSnackBar(
                          context,
                          'User deleted successfully.',
                          status: AppSnackBarStatus.success,
                        );
                      }
                    },
                    icon: const Icon(
                      Icons.delete_rounded,
                      color: AppColors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                user.phoneNumber.isEmpty ? '-' : user.phoneNumber,
                style: const TextStyle(
                  color: AppColors.greyText,
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
