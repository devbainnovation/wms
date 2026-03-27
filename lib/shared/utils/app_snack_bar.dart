import 'package:flutter/material.dart';
import 'package:wms/shared/theme/app_colors.dart';

enum AppSnackBarStatus { success, error, info }

void showAppSnackBar(
  BuildContext context,
  String message, {
  AppSnackBarStatus status = AppSnackBarStatus.info,
}) {
  final normalizedMessage = message.replaceFirst('Exception: ', '');
  final backgroundColor = switch (status) {
    AppSnackBarStatus.error => AppColors.error,
    AppSnackBarStatus.success => AppColors.success,
    AppSnackBarStatus.info => AppColors.orange,
  };

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      backgroundColor: backgroundColor,
      content: Text(
        normalizedMessage,
        style: const TextStyle(
          color: AppColors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}
