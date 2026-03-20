import 'package:flutter/material.dart';
import 'package:wms/shared/theme/theme.dart';

class AppSectionCard extends StatelessWidget {
  const AppSectionCard({
    required this.child,
    this.width,
    this.padding = const EdgeInsets.all(14),
    this.radius = 14,
    this.backgroundColor = AppColors.white,
    super.key,
  });

  final Widget child;
  final double? width;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.lightGreyText),
      ),
      child: child,
    );
  }
}
