part of 'dashboard_tab_view.dart';

class _MotorSection extends ConsumerWidget {
  const _MotorSection({required this.device});

  final CustomerDeviceSummary device;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final motor = device.motor;
    final isOn = motor?.isOn ?? false;
    final motorLocation = motor?.installedArea.trim() ?? '';
    final motorTitle = motorLocation.isEmpty
        ? 'Motor'
        : 'Motor - $motorLocation';
    final mode = motor?.mode.trim().toUpperCase() ?? '';
    final timeValue = isOn
        ? _formatTimeOnly(motor?.startedAt ?? '')
        : _formatTimeOnly(motor?.lastOffAt ?? '');
    final subtitle = _buildMotorStatusText(
      isOn: isOn,
      timeValue: timeValue,
      mode: mode,
    );
    final motorKey = motor?.componentId.trim().isNotEmpty == true
        ? motor!.componentId
        : (device.espId.isNotEmpty ? device.espId : device.displayName);
    final submitting =
        ref.watch(dashboardMotorSubmittingProvider)[motorKey] ?? false;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.lightBlue.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isOn
                  ? AppColors.accentGreen.withValues(alpha: 0.16)
                  : AppColors.red.withValues(alpha: 0.10),
            ),
            child: Center(
              child: Image.asset(
                AppAssets.motor,
                width: 22,
                height: 22,
                color: isOn ? AppColors.accentGreen : AppColors.red,
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.power_settings_new_rounded,
                  size: 24,
                  color: isOn ? AppColors.accentGreen : AppColors.red,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  motorTitle,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkText,
                  ),
                ),
                const SizedBox(height: 4),
                if (motor != null) ...[
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: isOn ? AppColors.accentGreen : AppColors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch(
            value: isOn,
            activeThumbColor: AppColors.primaryTeal,
            onChanged: submitting || motor?.componentId.trim().isEmpty != false
                ? null
                : (value) => _handleToggle(
                    context,
                    ref,
                    device,
                    motor!,
                    value,
                    motorKey,
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleToggle(
    BuildContext context,
    WidgetRef ref,
    CustomerDeviceSummary device,
    CustomerMotorSummary motor,
    bool value,
    String motorKey,
  ) async {
    if (!device.isOnline) {
      showAppSnackBar(
        context,
        'Device is offline.',
        status: AppSnackBarStatus.error,
      );
      return;
    }

    final confirmed = await confirmManualActionDialog(
      context: context,
      title: value ? 'Turn on motor?' : 'Turn off motor?',
      message: value
          ? 'This action will start the motor immediately.'
          : 'This action will stop the motor immediately.',
    );
    if (confirmed != true || !context.mounted) {
      return;
    }

    ref
        .read(dashboardMotorSubmittingProvider.notifier)
        .setSubmitting(motorKey, true);
    try {
      await ref
          .read(customerManualTriggerControllerProvider.notifier)
          .trigger(
            componentId: motor.componentId,
            action: value ? 'ON' : 'OFF',
            duration: null,
          );
      if (!context.mounted) {
        return;
      }
      ref.invalidate(customerDevicesListProvider);
      showAppSnackBar(
        context,
        value ? 'Motor turned on.' : 'Motor turned off.',
        status: AppSnackBarStatus.success,
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      showAppSnackBar(
        context,
        error.toString(),
        status: AppSnackBarStatus.error,
      );
    } finally {
      ref
          .read(dashboardMotorSubmittingProvider.notifier)
          .setSubmitting(motorKey, false);
    }
  }
}

String _buildMotorStatusText({
  required bool isOn,
  required String timeValue,
  required String mode,
}) {
  final normalizedMode = mode.trim();
  final normalizedTime = timeValue.trim();
  final timePart =
      normalizedTime.isEmpty ||
          normalizedTime == '-' ||
          normalizedTime.toLowerCase() == 'null'
      ? null
      : normalizedTime;
  final modePart = normalizedMode.isEmpty ? null : normalizedMode;

  final suffixParts = [timePart, modePart == null ? null : '($modePart)'];

  if (suffixParts.every((part) => part == null)) {
    return isOn ? 'ON' : 'OFF';
  }

  final suffix = suffixParts.whereType<String>().join(' ');
  return suffix.isEmpty
      ? (isOn ? 'ON' : 'OFF')
      : '${isOn ? 'ON' : 'OFF'} $suffix';
}
