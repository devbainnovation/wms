import 'package:flutter/material.dart';
import 'package:wms/shared/theme/theme.dart';

class AppMetaChip extends StatelessWidget {
  const AppMetaChip({
    required this.label,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    super.key,
  });

  final String label;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.lightBackground,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.darkText,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
