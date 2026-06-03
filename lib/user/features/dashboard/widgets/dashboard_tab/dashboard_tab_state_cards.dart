part of 'dashboard_tab_view.dart';

class _DeviceEmptyCard extends StatelessWidget {
  const _DeviceEmptyCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.lightGreyText),
      ),
      child: const Text(
        'No devices found.',
        style: TextStyle(
          color: AppColors.greyText,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _DeviceErrorCard extends StatelessWidget {
  const _DeviceErrorCard({
    required this.message,
    required this.onRetry,
    this.actionLabel = 'Retry',
  });

  final String message;
  final VoidCallback onRetry;
  final String actionLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.lightGreyText),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: const TextStyle(
              color: AppColors.red,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          TextButton(onPressed: onRetry, child: Text(actionLabel)),
        ],
      ),
    );
  }
}
