part of 'admin_customers_screen.dart';

class _DeleteCustomerDialog extends ConsumerWidget {
  const _DeleteCustomerDialog({
    required this.customerId,
    required this.customerName,
    required this.username,
  });

  final String customerId;
  final String customerName;
  final String username;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminDeleteCustomerControllerProvider);
    final displayName = customerName.trim().isNotEmpty
        ? customerName.trim()
        : username.trim().isNotEmpty
        ? username.trim()
        : customerId;

    return AlertDialog(
      backgroundColor: AppColors.lightBackground,
      title: const Text('Delete User'),
      content: Text(
        'Are you sure you want to delete "$displayName"? This action cannot be undone.',
      ),
      actions: [
        TextButton(
          onPressed: state.isLoading
              ? null
              : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.red),
          onPressed: state.isLoading
              ? null
              : () async {
                  try {
                    await ref
                        .read(adminDeleteCustomerControllerProvider.notifier)
                        .delete(customerId);
                    if (!context.mounted) {
                      return;
                    }
                    Navigator.of(context).pop(true);
                  } catch (error) {
                    if (!context.mounted) {
                      return;
                    }
                    final message = error is ApiException
                        ? error.message
                        : 'Unable to delete user.';
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(message)));
                  }
                },
          child: state.isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Delete'),
        ),
      ],
    );
  }
}

class _CountryDialCode {
  const _CountryDialCode({
    required this.isoCode,
    required this.name,
    required this.dialCode,
  });

  final String isoCode;
  final String name;
  final String dialCode;
}
