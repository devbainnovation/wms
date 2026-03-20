import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wms/core/core.dart';
import 'package:wms/shared/shared.dart';
import 'package:wms/user/features/dashboard/screens/user_admin_user_dialogs.dart';
import 'package:wms/user/features/dashboard/screens/user_admin_user_card.dart';
import 'package:wms/user/features/dashboard/providers/user_admin_users_providers.dart';

class UserAdminUsersScreen extends ConsumerWidget {
  const UserAdminUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(userAdminUsersListProvider);

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.darkText,
        elevation: 0,
        title: const Text('View Users'),
        actions: [
          IconButton(
            tooltip: 'Add User',
            icon: const Icon(Icons.person_add_alt_1_rounded),
            onPressed: () async {
              final created = await Navigator.of(context).push<bool>(
                MaterialPageRoute(builder: (_) => const UserAdminAddUserDialog()),
              );

              if (created == true) {
                ref.invalidate(userAdminUsersListProvider);
                if (!context.mounted) {
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('User added successfully.')),
                );
              }
            },
          ),
        ],
      ),
      body: usersAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primaryTeal),
        ),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                error is ApiException
                    ? error.message
                    : 'Unable to fetch users.',
                style: const TextStyle(
                  color: AppColors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref.invalidate(userAdminUsersListProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (users) {
          if (users.isEmpty) {
            return const Center(
              child: Text(
                'No users found.',
                style: TextStyle(
                  color: AppColors.greyText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(userAdminUsersListProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: users.length,
              separatorBuilder: (_, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final user = users[index];
                return UserAdminUserCard(user: user);
              },
            ),
          );
        },
      ),
    );
  }
}
