import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wms/shared/shared.dart';

Future<TimeOfDay?> pickValveScheduleTime({
  required BuildContext context,
  required TimeOfDay initial,
}) {
  return showTimePicker(
    context: context,
    initialTime: initial,
    builder: (context, child) {
      return Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
            primary: AppColors.primaryTeal,
            onPrimary: AppColors.white,
            onSurface: AppColors.darkText,
          ),
        ),
        child: child!,
      );
    },
  );
}

Future<bool?> confirmValveScheduleDelete(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Delete Schedule'),
        content: const Text('Are you sure you want to delete this schedule?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.white,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      );
    },
  );
}

Future<int?> showManualDurationDialog(BuildContext context) async {
  final formKey = GlobalKey<FormState>();
  var durationText = '';

  final result = await showDialog<int>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Manual Duration'),
        content: Form(
          key: formKey,
          child: TextFormField(
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.digitsOnly,
            ],
            onChanged: (value) => durationText = value,
            decoration: const InputDecoration(
              labelText: 'Duration (minutes)',
              hintText: 'Max 300',
            ),
            validator: (value) {
              final trimmed = (value ?? '').trim();
              if (trimmed.isEmpty) {
                return 'Duration is required';
              }
              final parsed = int.tryParse(trimmed);
              if (parsed == null) {
                return 'Enter a valid number';
              }
              if (parsed < 1 || parsed > 300) {
                return 'Enter 1 to 300 minutes';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final isValid = formKey.currentState?.validate() ?? false;
              if (!isValid) {
                return;
              }
              Navigator.of(dialogContext).pop(int.parse(durationText.trim()));
            },
            child: const Text('Continue'),
          ),
        ],
      );
    },
  );

  return result;
}

void showValveSettingSnackBar(BuildContext context, String message) {
  final normalized = message.replaceFirst('Exception: ', '');
  final status = normalized.toLowerCase().contains('success') ||
          normalized.toLowerCase().contains('saved') ||
          normalized.toLowerCase().contains('added') ||
          normalized.toLowerCase().contains('updated') ||
          normalized.toLowerCase().contains('deleted')
      ? AppSnackBarStatus.success
      : AppSnackBarStatus.error;
  showAppSnackBar(
    context,
    normalized,
    status: status,
  );
}
