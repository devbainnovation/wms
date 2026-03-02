import 'package:flutter/material.dart';
import 'package:wms/shared/theme/theme.dart';

class AppDatePickerField extends StatelessWidget {
  const AppDatePickerField({
    required this.label,
    required this.value,
    required this.onPick,
    this.firstDate,
    this.lastDate,
    this.hintText = 'Select date',
    super.key,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onPick;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final start = firstDate ?? DateTime(now.year - 1);
    final end = lastDate ?? DateTime(now.year + 20);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          firstDate: start,
          lastDate: end,
          initialDate: value ?? now,
          builder: (context, child) {
            final base = Theme.of(context);
            return Theme(
              data: base.copyWith(
                colorScheme: base.colorScheme.copyWith(
                  primary: AppColors.primaryTeal,
                  onPrimary: AppColors.white,
                  surface: AppColors.lightBackground,
                  onSurface: AppColors.darkText,
                  secondary: AppColors.accentGreen,
                ),
                datePickerTheme: const DatePickerThemeData(
                  backgroundColor: AppColors.lightBackground,
                  headerBackgroundColor: AppColors.lightBlue,
                  headerForegroundColor: AppColors.darkText,
                ),
                textButtonTheme: TextButtonThemeData(
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primaryTeal,
                    textStyle: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              child: child ?? const SizedBox.shrink(),
            );
          },
        );

        if (picked != null) {
          onPick(picked);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          suffixIcon: const Icon(Icons.calendar_today_rounded),
        ),
        child: Text(
          value == null ? hintText : _formatDate(value!),
          style: TextStyle(
            color: value == null ? AppColors.greyText : AppColors.darkText,
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$d/$m/$y';
  }
}
