import 'package:flutter/material.dart';
import 'package:wms/shared/theme/theme.dart';

class AppStatusChip extends StatelessWidget {
  const AppStatusChip({
    required this.label,
    required this.active,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    super.key,
  });

  final String label;
  final bool active;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.accentGreen : AppColors.red;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}
