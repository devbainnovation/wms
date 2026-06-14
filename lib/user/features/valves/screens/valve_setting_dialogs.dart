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
        child: MediaQuery(
          data: MediaQuery.of(context).copyWith(
            alwaysUse24HourFormat: true,
          ),
          child: child!,
        ),
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

Future<bool?> confirmManualActionDialog({
  required BuildContext context,
  required String title,
  required String message,
  String confirmLabel = 'Yes, Continue',
}) {
  return showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(confirmLabel),
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

Future<bool?> showManualScheduleRunningDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Schedule Active'),
        content: const Text(
          'A schedule is currently scheduled to run for this valve. '
          'Would you like to start it manually anyway?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Start Manually'),
          ),
        ],
      );
    },
  );
}

Future<String?> showRenameComponentDialog({
  required BuildContext context,
  required String currentName,
}) async {
  final formKey = GlobalKey<FormState>();
  final controller = TextEditingController(text: currentName);

  final result = await showDialog<String>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Rename Valve'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Valve Name',
              hintText: 'Enter new name',
            ),
            validator: (value) {
              final trimmed = (value ?? '').trim();
              if (trimmed.isEmpty) {
                return 'Name is required';
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
              if (formKey.currentState?.validate() ?? false) {
                Navigator.of(dialogContext).pop(controller.text.trim());
              }
            },
            child: const Text('Save'),
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
