import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wms/admin/features/devices/screens/admin_device_components_screen.dart';
import 'package:wms/admin/features/devices/providers/admin_devices_providers.dart';
import 'package:wms/admin/features/devices/services/admin_device_service.dart';
import 'package:wms/core/core.dart';
import 'package:wms/shared/shared.dart';

class AdminDevicesScreen extends ConsumerWidget {
  const AdminDevicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devicesAsync = ref.watch(adminDevicesListProvider);
    final isMobile = MediaQuery.sizeOf(context).width < 900;

    return Padding(
      padding: EdgeInsets.all(isMobile ? 12 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          isMobile
              ? Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text(
                      'Devices',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppColors.darkText,
                      ),
                    ),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primaryTeal,
                        foregroundColor: AppColors.white,
                      ),
                      onPressed: () async {
                        final created = await showDialog<bool>(
                          context: context,
                          barrierDismissible: false,
                          builder: (_) => const _DeviceUpsertDialog(),
                        );

                        if (!context.mounted || created != true) {
                          return;
                        }

                        ref.invalidate(adminDevicesListProvider);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Device registered successfully.'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Add Devices'),
                    ),
                  ],
                )
              : Row(
                  children: [
                    const Text(
                      'Devices',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppColors.darkText,
                      ),
                    ),
                    const Spacer(),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primaryTeal,
                        foregroundColor: AppColors.white,
                      ),
                      onPressed: () async {
                        final created = await showDialog<bool>(
                          context: context,
                          barrierDismissible: false,
                          builder: (_) => const _DeviceUpsertDialog(),
                        );

                        if (!context.mounted || created != true) {
                          return;
                        }

                        ref.invalidate(adminDevicesListProvider);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Device registered successfully.'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Add Devices'),
                    ),
                  ],
                ),
          SizedBox(height: isMobile ? 12 : 18),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.lightGreyText),
              ),
              child: devicesAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryTeal,
                  ),
                ),
                error: (error, _) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        error is ApiException
                            ? error.message
                            : 'Unable to load devices',
                        style: const TextStyle(
                          color: AppColors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () =>
                            ref.invalidate(adminDevicesListProvider),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
                data: (result) {
                  if (result.items.isEmpty) {
                    return const Center(
                      child: Text(
                        'No devices found.',
                        style: TextStyle(
                          color: AppColors.greyText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: [
                      Expanded(
                        child: ListView.separated(
                          padding: EdgeInsets.all(isMobile ? 10 : 16),
                          itemCount: result.items.length,
                          separatorBuilder: (_, index) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final item = result.items[index];
                            return _DeviceTile(
                              item: item,
                              isMobile: isMobile,
                              onOpenComponents: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => AdminDeviceComponentsScreen(
                                      deviceId: item.id,
                                      deviceName: item.displayName,
                                    ),
                                  ),
                                );
                              },
                              onEdit: () async {
                                final updated = await showDialog<bool>(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (_) =>
                                      _DeviceUpsertDialog(editItem: item),
                                );
                                if (updated == true) {
                                  ref.invalidate(adminDevicesListProvider);
                                  if (!context.mounted) {
                                    return;
                                  }
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Device updated successfully.',
                                      ),
                                    ),
                                  );
                                }
                              },
                              onDelete: () async {
                                final deleted = await showDialog<bool>(
                                  context: context,
                                  builder: (_) => _DeleteDeviceDialog(
                                    id: item.id,
                                    name: item.displayName,
                                  ),
                                );
                                if (deleted == true) {
                                  ref.invalidate(adminDevicesListProvider);
                                  if (!context.mounted) {
                                    return;
                                  }
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Device deleted successfully.',
                                      ),
                                    ),
                                  );
                                }
                              },
                            );
                          },
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
                        child: isMobile
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Page ${result.page + 1} of ${result.totalPages} • Total ${result.totalElements}',
                                    style: const TextStyle(
                                      color: AppColors.greyText,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      OutlinedButton(
                                        onPressed: result.hasPrevious
                                            ? () {
                                                ref
                                                    .read(
                                                      adminDevicesPageProvider
                                                          .notifier,
                                                    )
                                                    .previous();
                                              }
                                            : null,
                                        child: const Text('Previous'),
                                      ),
                                      const SizedBox(width: 8),
                                      FilledButton(
                                        onPressed: result.hasNext
                                            ? () {
                                                ref
                                                    .read(
                                                      adminDevicesPageProvider
                                                          .notifier,
                                                    )
                                                    .next();
                                              }
                                            : null,
                                        child: const Text('Next'),
                                      ),
                                    ],
                                  ),
                                ],
                              )
                            : Row(
                                children: [
                                  Text(
                                    'Page ${result.page + 1} of ${result.totalPages} • Total ${result.totalElements}',
                                    style: const TextStyle(
                                      color: AppColors.greyText,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const Spacer(),
                                  OutlinedButton(
                                    onPressed: result.hasPrevious
                                        ? () {
                                            ref
                                                .read(
                                                  adminDevicesPageProvider
                                                      .notifier,
                                                )
                                                .previous();
                                          }
                                        : null,
                                    child: const Text('Previous'),
                                  ),
                                  const SizedBox(width: 8),
                                  FilledButton(
                                    onPressed: result.hasNext
                                        ? () {
                                            ref
                                                .read(
                                                  adminDevicesPageProvider
                                                      .notifier,
                                                )
                                                .next();
                                          }
                                        : null,
                                    child: const Text('Next'),
                                  ),
                                ],
                              ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeviceTile extends StatelessWidget {
  const _DeviceTile({
    required this.item,
    required this.isMobile,
    required this.onOpenComponents,
    required this.onEdit,
    required this.onDelete,
  });

  final AdminDeviceSummary item;
  final bool isMobile;
  final VoidCallback onOpenComponents;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightGreyText),
      ),
      child: isMobile ? _mobileLayout() : _desktopLayout(),
    );
  }

  Widget _desktopLayout() {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Text(
            item.displayName,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.darkText,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            item.macAddress.isEmpty ? '-' : item.macAddress,
            style: const TextStyle(color: AppColors.darkText),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            item.fwVersion.isEmpty ? '-' : item.fwVersion,
            style: const TextStyle(color: AppColors.darkText),
          ),
        ),
        Expanded(
          flex: 2,
          child: Align(alignment: Alignment.centerLeft, child: _statusChip()),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            OutlinedButton.icon(
              onPressed: onOpenComponents,
              icon: const Icon(
                Icons.settings_input_component_rounded,
                size: 18,
                color: AppColors.primaryTeal,
              ),
              label: const Text('Add Component'),
            ),
            const SizedBox(width: 6),
            IconButton(
              tooltip: 'Edit',
              onPressed: onEdit,
              icon: const Icon(Icons.edit_rounded, color: AppColors.blue),
            ),
            IconButton(
              tooltip: 'Delete',
              onPressed: onDelete,
              icon: const Icon(Icons.delete_rounded, color: AppColors.red),
            ),
          ],
        ),
      ],
    );
  }

  Widget _mobileLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.displayName,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.darkText,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _metaChip(
              'MAC: ${item.macAddress.isEmpty ? '-' : item.macAddress}',
            ),
            _metaChip('FW: ${item.fwVersion.isEmpty ? '-' : item.fwVersion}'),
            _statusChip(),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            OutlinedButton.icon(
              onPressed: onOpenComponents,
              icon: const Icon(
                Icons.settings_input_component_rounded,
                size: 18,
                color: AppColors.primaryTeal,
              ),
              label: const Text('Add Component'),
            ),
            IconButton(
              tooltip: 'Edit',
              onPressed: onEdit,
              icon: const Icon(Icons.edit_rounded, color: AppColors.blue),
            ),
            IconButton(
              tooltip: 'Delete',
              onPressed: onDelete,
              icon: const Icon(Icons.delete_rounded, color: AppColors.red),
            ),
          ],
        ),
      ],
    );
  }

  Widget _metaChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.lightBackground,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.darkText,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _statusChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: item.isActive
            ? AppColors.accentGreen.withValues(alpha: 0.12)
            : AppColors.red.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        item.isActive ? 'Active' : 'Inactive',
        style: TextStyle(
          color: item.isActive ? AppColors.accentGreen : AppColors.red,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _DeviceUpsertDialog extends ConsumerStatefulWidget {
  const _DeviceUpsertDialog({this.editItem});

  final AdminDeviceSummary? editItem;

  @override
  ConsumerState<_DeviceUpsertDialog> createState() =>
      _DeviceUpsertDialogState();
}

class _DeviceUpsertDialogState extends ConsumerState<_DeviceUpsertDialog> {
  final _formKey = GlobalKey<FormState>();
  final _macController = TextEditingController();
  final _nameController = TextEditingController();
  final _fwController = TextEditingController();

  DateTime? _amcExpiry;
  DateTime? _rechargeExpiry;
  bool _isActive = true;

  bool get _isEdit => widget.editItem != null;

  @override
  void initState() {
    super.initState();
    final item = widget.editItem;
    if (item == null) {
      return;
    }
    _macController.text = item.macAddress;
    _nameController.text = item.displayName;
    _fwController.text = item.fwVersion;
    _amcExpiry = item.amcExpiry;
    _rechargeExpiry = item.rechargeExpiry;
    _isActive = item.isActive;
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
                  value: _amcExpiry,
                  onPick: (date) => setState(() => _amcExpiry = date),
                ),
                const SizedBox(height: 12),
                AppDatePickerField(
                  label: 'Recharge Expiry',
                  value: _rechargeExpiry,
                  onPick: (date) => setState(() => _rechargeExpiry = date),
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
                      value: _isActive,
                      activeThumbColor: AppColors.accentGreen,
                      onChanged: (value) => setState(() => _isActive = value),
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
    if (_amcExpiry == null) {
      _showError('AMC expiry date is required.');
      return;
    }
    if (_rechargeExpiry == null) {
      _showError('Recharge expiry date is required.');
      return;
    }

    final request = AdminDeviceRequest(
      macAddress: _macController.text.trim(),
      displayName: _nameController.text.trim(),
      fwVersion: _fwController.text.trim(),
      amcExpiry: _amcExpiry!,
      rechargeExpiry: _rechargeExpiry!,
      isActive: _isActive,
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

class _DeleteDeviceDialog extends ConsumerWidget {
  const _DeleteDeviceDialog({required this.id, required this.name});

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
