import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wms/admin/features/devices/providers/admin_devices_providers.dart';
import 'package:wms/admin/features/devices/services/admin_device_service.dart';
import 'package:wms/core/core.dart';
import 'package:wms/shared/shared.dart';

final _deviceUpsertAmcExpiryProvider =
    NotifierProvider.autoDispose<_DeviceUpsertAmcExpiryNotifier, DateTime?>(
      _DeviceUpsertAmcExpiryNotifier.new,
    );
final _deviceUpsertRechargeExpiryProvider =
    NotifierProvider.autoDispose<
      _DeviceUpsertRechargeExpiryNotifier,
      DateTime?
    >(_DeviceUpsertRechargeExpiryNotifier.new);
final _deviceUpsertIsActiveProvider =
    NotifierProvider.autoDispose<_DeviceUpsertIsActiveNotifier, bool>(
      _DeviceUpsertIsActiveNotifier.new,
    );

class _DeviceUpsertAmcExpiryNotifier extends Notifier<DateTime?> {
  @override
  DateTime? build() => null;

  void set(DateTime? value) => state = value;
}

class _DeviceUpsertRechargeExpiryNotifier extends Notifier<DateTime?> {
  @override
  DateTime? build() => null;

  void set(DateTime? value) => state = value;
}

class _DeviceUpsertIsActiveNotifier extends Notifier<bool> {
  @override
  bool build() => true;

  void set(bool value) => state = value;
}

class AdminDeviceUpsertDialog extends ConsumerStatefulWidget {
  const AdminDeviceUpsertDialog({this.editItem, super.key});

  final AdminDeviceSummary? editItem;

  @override
  ConsumerState<AdminDeviceUpsertDialog> createState() =>
      _AdminDeviceUpsertDialogState();
}

class _AdminDeviceUpsertDialogState
    extends ConsumerState<AdminDeviceUpsertDialog> {
  final _formKey = GlobalKey<FormState>();
  final _macController = TextEditingController();
  final _nameController = TextEditingController();
  final _fwController = TextEditingController();

  bool get _isEdit => widget.editItem != null;

  @override
  void initState() {
    super.initState();
    final item = widget.editItem;
    if (item != null) {
      _macController.text = item.macAddress;
      _nameController.text = item.displayName;
      _fwController.text = item.fwVersion;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      ref.read(_deviceUpsertAmcExpiryProvider.notifier).set(item?.amcExpiry);
      ref
          .read(_deviceUpsertRechargeExpiryProvider.notifier)
          .set(item?.rechargeExpiry);
      ref
          .read(_deviceUpsertIsActiveProvider.notifier)
          .set(item?.isActive ?? true);
    });
  }

  @override
  void dispose() {
    _macController.dispose();
    _nameController.dispose();
    _fwController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final registerState = ref.watch(adminRegisterDeviceControllerProvider);
    final updateState = ref.watch(adminUpdateDeviceControllerProvider);
    final amcExpiry = ref.watch(_deviceUpsertAmcExpiryProvider);
    final rechargeExpiry = ref.watch(_deviceUpsertRechargeExpiryProvider);
    final isActive = ref.watch(_deviceUpsertIsActiveProvider);
    final isLoading = registerState.isLoading || updateState.isLoading;

    return AlertDialog(
      backgroundColor: AppColors.lightBackground,
      title: Text(_isEdit ? 'Edit Device' : 'Register Device'),
      content: SizedBox(
        width: 460,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppTextField(
                  controller: _macController,
                  hintText: 'Enter MAC address',
                  labelText: 'MAC Address',
                  onChanged: (value) {
                    final uppercaseValue = value.toUpperCase();
                    if (value == uppercaseValue) {
                      return;
                    }
                    _macController.value = _macController.value.copyWith(
                      text: uppercaseValue,
                      selection: TextSelection.collapsed(
                        offset: uppercaseValue.length,
                      ),
                      composing: TextRange.empty,
                    );
                  },
                  validator: (v) => _required(v, 'MAC address'),
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _nameController,
                  hintText: 'Enter display name',
                  labelText: 'Display Name',
                  validator: (v) => _required(v, 'Display name'),
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _fwController,
                  hintText: 'Enter firmware version',
                  labelText: 'FW Version',
                  validator: (v) => _required(v, 'FW version'),
                ),
                const SizedBox(height: 12),
                AppDatePickerField(
                  label: 'AMC Expiry',
                  value: amcExpiry,
                  onPick: (date) => ref
                      .read(_deviceUpsertAmcExpiryProvider.notifier)
                      .set(date),
                ),
                const SizedBox(height: 12),
                AppDatePickerField(
                  label: 'Recharge Expiry',
                  value: rechargeExpiry,
                  onPick: (date) => ref
                      .read(_deviceUpsertRechargeExpiryProvider.notifier)
                      .set(date),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text(
                      'Is Active',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.darkText,
                      ),
                    ),
                    const Spacer(),
                    Switch(
                      value: isActive,
                      activeThumbColor: AppColors.accentGreen,
                      onChanged: (value) => ref
                          .read(_deviceUpsertIsActiveProvider.notifier)
                          .set(value),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: isLoading ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primaryTeal,
            foregroundColor: AppColors.white,
          ),
          onPressed: isLoading ? null : _submit,
          child: isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.white,
                  ),
                )
              : Text(_isEdit ? 'Update' : 'Register'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) {
      return;
    }
    final amcExpiry = ref.read(_deviceUpsertAmcExpiryProvider);
    final rechargeExpiry = ref.read(_deviceUpsertRechargeExpiryProvider);
    final isActive = ref.read(_deviceUpsertIsActiveProvider);

    if (amcExpiry == null) {
      _showError('AMC expiry date is required.');
      return;
    }
    if (rechargeExpiry == null) {
      _showError('Recharge expiry date is required.');
      return;
    }

    final request = AdminDeviceRequest(
      macAddress: _macController.text.trim().toUpperCase(),
      displayName: _nameController.text.trim(),
      fwVersion: _fwController.text.trim(),
      amcExpiry: amcExpiry,
      rechargeExpiry: rechargeExpiry,
      isActive: isActive,
    );

    try {
      if (_isEdit) {
        await ref
            .read(adminUpdateDeviceControllerProvider.notifier)
            .update(id: widget.editItem!.id, request: request);
      } else {
        await ref
            .read(adminRegisterDeviceControllerProvider.notifier)
            .register(request);
      }
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      final message = error is ApiException
          ? error.message
          : 'Unable to register device.';
      _showError(message);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String? _required(String? value, String label) {
    if ((value ?? '').trim().isEmpty) {
      return '$label is required';
    }
    return null;
  }
}

class AdminDeleteDeviceDialog extends ConsumerWidget {
  const AdminDeleteDeviceDialog({
    required this.id,
    required this.name,
    super.key,
  });

  final String id;
  final String name;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminDeleteDeviceControllerProvider);

    return AlertDialog(
      backgroundColor: AppColors.lightBackground,
      title: const Text('Delete Device'),
      content: Text(
        'Are you sure you want to delete "$name"? This action cannot be undone.',
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
                        .read(adminDeleteDeviceControllerProvider.notifier)
                        .delete(id);
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
                        : 'Unable to delete device.';
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
