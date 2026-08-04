import 'package:flutter/material.dart';
import 'package:wms/shared/theme/theme.dart';

class AppButton extends StatelessWidget {
  const AppButton({
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.height = 52,
    this.width = double.infinity,
    this.backgroundColor,
    this.icon,
    super.key,
  });

  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double height;
  final double width;
  final Color? backgroundColor;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          foregroundColor: AppColors.white,
          backgroundColor: backgroundColor ?? AppColors.primaryTeal,
          disabledBackgroundColor: AppColors.lightGreyText,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    text,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
