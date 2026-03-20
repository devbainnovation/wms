import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wms/admin/features/devices/providers/admin_device_components_providers.dart';
import 'package:wms/admin/features/devices/services/admin_device_component_service.dart';
import 'package:wms/core/core.dart';
import 'package:wms/shared/shared.dart';

final _componentUpsertTypeProvider =
    NotifierProvider.autoDispose<
      _ComponentUpsertTypeNotifier,
      AdminComponentType
    >(
      _ComponentUpsertTypeNotifier.new,
    );
final _componentUpsertIsActiveProvider =
    NotifierProvider.autoDispose<_ComponentUpsertIsActiveNotifier, bool>(
      _ComponentUpsertIsActiveNotifier.new,
    );

class _ComponentUpsertTypeNotifier extends Notifier<AdminComponentType> {
  @override
  AdminComponentType build() => AdminComponentType.valve;

  void set(AdminComponentType value) => state = value;
}

class _ComponentUpsertIsActiveNotifier extends Notifier<bool> {
  @override
  bool build() => true;

  void set(bool value) => state = value;
}

class AdminDeviceComponentUpsertDialog extends ConsumerStatefulWidget {
  const AdminDeviceComponentUpsertDialog({
    required this.deviceId,
    this.editItem,
    super.key,
  });

  final String deviceId;
  final AdminDeviceComponent? editItem;

  @override
  ConsumerState<AdminDeviceComponentUpsertDialog> createState() =>
      _AdminDeviceComponentUpsertDialogState();
}

class _AdminDeviceComponentUpsertDialogState
    extends ConsumerState<AdminDeviceComponentUpsertDialog> {
  final _formKey = GlobalKey<FormState>();
  final _gpioController = TextEditingController();
  final _nameController = TextEditingController();
  final _installedAreaController = TextEditingController();

  bool get _isEdit => widget.editItem != null;

  @override
  void initState() {
    super.initState();
    final item = widget.editItem;
    _gpioController.text = item == null ? '' : item.gpioPin.toString();
    _nameController.text = item?.name ?? '';
    _installedAreaController.text = item?.installedArea ?? '';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      ref
          .read(_componentUpsertTypeProvider.notifier)
          .set(item?.type ?? AdminComponentType.valve);
      ref
          .read(_componentUpsertIsActiveProvider.notifier)
          .set(item?.active ?? true);
    });
  }

  @override
  void dispose() {
    _gpioController.dispose();
    _nameController.dispose();
    _installedAreaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final createState = ref.watch(adminCreateComponentControllerProvider);
    final updateState = ref.watch(adminUpdateComponentControllerProvider);
    final selectedType = ref.watch(_componentUpsertTypeProvider);
    final isActive = ref.watch(_componentUpsertIsActiveProvider);
    final isLoading = createState.isLoading || updateState.isLoading;

    return AlertDialog(
      backgroundColor: AppColors.lightBackground,
      title: Text(_isEdit ? 'Edit Component' : 'Add Component'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<AdminComponentType>(
                  initialValue: selectedType,
                  decoration: InputDecoration(
                    labelText: 'Type',
                    filled: true,
                    fillColor: AppColors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: AppColors.lightGreyText,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: AppColors.lightGreyText,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: AppColors.primaryTeal,
                        width: 1.4,
                      ),
                    ),
                  ),
                  items: AdminComponentType.values
                      .map(
                        (type) => DropdownMenuItem<AdminComponentType>(
                          value: type,
                          child: Text(type.label),
                        ),
                      )
                      .toList(),
                  onChanged: isLoading
                      ? null
                      : (value) {
                          if (value == null) {
                            return;
                          }
                          ref
                              .read(_componentUpsertTypeProvider.notifier)
                              .set(value);
                        },
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _gpioController,
                  hintText: 'GPIO Pin',
                  labelText: 'GPIO Pin',
                  keyboardType: TextInputType.number,
                  validator: _validatePin,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _nameController,
                  hintText: 'Name',
                  labelText: 'Name',
                  validator: (value) => _required(value, 'name'),
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _installedAreaController,
                  hintText: 'Area Location',
                  labelText: 'Area Location',
                  textCapitalization: TextCapitalization.sentences,
                  validator: (value) => _required(value, 'installedArea'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text(
                      'isActive',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.darkText,
                      ),
                    ),
                    const Spacer(),
                    Switch(
                      value: isActive,
                      activeThumbColor: AppColors.accentGreen,
                      onChanged: isLoading
                          ? null
                          : (value) => ref
                              .read(_componentUpsertIsActiveProvider.notifier)
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
              : Text(_isEdit ? 'Update' : 'Create'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) {
      return;
    }

    final request = AdminDeviceComponentRequest(
      type: ref.read(_componentUpsertTypeProvider),
      gpioPin: int.parse(_gpioController.text.trim()),
      name: _nameController.text.trim(),
      installedArea: _normalizeInstalledArea(_installedAreaController.text),
      active: ref.read(_componentUpsertIsActiveProvider),
    );

    try {
      if (_isEdit) {
        await ref
            .read(adminUpdateComponentControllerProvider.notifier)
            .update(
              deviceId: widget.deviceId,
              compId: widget.editItem!.id,
              request: request,
            );
      } else {
        await ref
            .read(adminCreateComponentControllerProvider.notifier)
            .create(deviceId: widget.deviceId, request: request);
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
          : 'Unable to save component.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  String? _required(String? value, String field) {
    if ((value ?? '').trim().isEmpty) {
      return '$field is required';
    }
    return null;
  }

  String? _validatePin(String? value) {
    final requiredResult = _required(value, 'gpioPin');
    if (requiredResult != null) {
      return requiredResult;
    }

    final parsed = int.tryParse(value!.trim());
    if (parsed == null) {
      return 'gpioPin must be a number';
    }
    return null;
  }

  String _normalizeInstalledArea(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return trimmed;
    }

    return '${trimmed[0].toUpperCase()}${trimmed.substring(1)}';
  }
}

class AdminDeleteComponentDialog extends ConsumerWidget {
  const AdminDeleteComponentDialog({
    required this.deviceId,
    required this.compId,
    required this.name,
    super.key,
  });

  final String deviceId;
  final String compId;
  final String name;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminDeleteComponentControllerProvider);

    return AlertDialog(
      backgroundColor: AppColors.lightBackground,
      title: const Text('Delete Component'),
      content: Text(
        'Are you sure you want to delete "${name.isEmpty ? 'this component' : name}"?',
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
                        .read(adminDeleteComponentControllerProvider.notifier)
                        .delete(deviceId: deviceId, compId: compId);
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
                        : 'Unable to delete component.';
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
