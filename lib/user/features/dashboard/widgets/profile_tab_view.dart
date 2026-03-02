import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wms/core/core.dart';
import 'package:wms/shared/shared.dart';
import 'package:wms/user/features/auth/screens/user_login_screen.dart';

class ProfileTabView extends ConsumerWidget {
  const ProfileTabView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logoutState = ref.watch(authLogoutControllerProvider);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Profile Screen',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.darkText,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: 180,
            child: AppButton(
              text: 'Logout',
              isLoading: logoutState.isLoading,
              onPressed: () async {
                final sessionId = ref
                    .read(currentAuthSessionProvider)
                    ?.sessionId;
                await ref
                    .read(authLogoutControllerProvider.notifier)
                    .logout(sessionId: sessionId);
                if (!context.mounted) {
                  return;
                }
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const UserLoginScreen()),
                  (route) => false,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
