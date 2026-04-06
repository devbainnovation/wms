import 'package:flutter/material.dart';

const _sessionExpiredMessage = 'Session expired. Please login again.';

bool isSessionExpiredMessage(String message) {
  return message.trim() == _sessionExpiredMessage;
}

void navigateToUserLogin(BuildContext context) {
  // The root route is the app launch gate, which already knows how to switch
  // between login and dashboard based on the current auth session.
  Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst);
}
