import 'package:flutter/material.dart';
import 'package:wms/user/features/auth/screens/user_login_screen.dart';

const _sessionExpiredMessage = 'Session expired. Please login again.';

bool isSessionExpiredMessage(String message) {
  return message.trim() == _sessionExpiredMessage;
}

void navigateToUserLogin(BuildContext context) {
  Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
    MaterialPageRoute<void>(builder: (_) => const UserLoginScreen()),
    (route) => false,
  );
}
