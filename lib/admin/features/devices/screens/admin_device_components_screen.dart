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

class AdminDeviceComponentsScreen extends ConsumerWidget {
  const AdminDeviceComponentsScreen({
    required this.deviceId,
    required this.deviceName,
    super.key,
  });

  final String deviceId;
  final String deviceName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final componentsAsync = ref.watch(adminDeviceComponentsProvider(deviceId));

    return Scaffold(
      backgroundColor: const Color(0xFFF7FBFC),
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0.5,
        title: Text('Components • $deviceName'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.lightGreyText),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Components',
                      style: TextStyle(
                        fontSize: 24,
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
                          builder: (_) =>
                              _ComponentUpsertDialog(deviceId: deviceId),
                        );

                        if (created != true || !context.mounted) {
                          return;
                        }

                        ref.invalidate(adminDeviceComponentsProvider(deviceId));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Component created successfully.'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Add Component'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: componentsAsync.when(
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
                                : 'Unable to load components.',
                            style: const TextStyle(
                              color: AppColors.red,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () => ref.invalidate(
                              adminDeviceComponentsProvider(deviceId),
                            ),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                    data: (items) {
                      if (items.isEmpty) {
                        return const Center(
                          child: Text(
                            'No components found.',
                            style: TextStyle(
                              color: AppColors.greyText,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }

                      return ListView.separated(
                        itemCount: items.length,
                        separatorBuilder: (_, index) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.lightGreyText,
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    item.name.isEmpty ? '-' : item.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.darkText,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    item.type.label,
                                    style: const TextStyle(
                                      color: AppColors.darkText,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    'GPIO ${item.gpioPin}',
                                    style: const TextStyle(
                                      color: AppColors.darkText,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: item.active
                                            ? AppColors.accentGreen.withValues(
                                                alpha: 0.12,
                                              )
                                            : AppColors.red.withValues(
                                                alpha: 0.12,
                                              ),
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                      ),
                                      child: Text(
                                        item.active ? 'Active' : 'Inactive',
                                        style: TextStyle(
                                          color: item.active
                                              ? AppColors.accentGreen
                                              : AppColors.red,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      tooltip: 'Edit',
                                      onPressed: () async {
                                        final updated = await showDialog<bool>(
                                          context: context,
                                          barrierDismissible: false,
                                          builder: (_) =>
                                              _ComponentUpsertDialog(
                                                deviceId: deviceId,
                                                editItem: item,
                                              ),
                                        );

                                        if (updated != true ||
                                            !context.mounted) {
                                          return;
                                        }
                                        ref.invalidate(
                                          adminDeviceComponentsProvider(
                                            deviceId,
                                          ),
                                        );
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Component updated successfully.',
                                            ),
                                          ),
                                        );
                                      },
                                      icon: const Icon(
                                        Icons.edit_rounded,
                                        color: AppColors.blue,
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'Delete',
                                      onPressed: () async {
                                        final deleted = await showDialog<bool>(
                                          context: context,
                                          builder: (_) =>
                                              _DeleteComponentDialog(
                                                deviceId: deviceId,
                                                compId: item.id,
                                                name: item.name,
                                              ),
                                        );

                                        if (deleted != true ||
                                            !context.mounted) {
                                          return;
                                        }
                                        ref.invalidate(
                                          adminDeviceComponentsProvider(
                                            deviceId,
                                          ),
                                        );
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Component deleted successfully.',
                                            ),
                                          ),
                                        );
                                      },
                                      icon: const Icon(
                                        Icons.delete_rounded,
                                        color: AppColors.red,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ComponentUpsertDialog extends ConsumerStatefulWidget {
  const _ComponentUpsertDialog({required this.deviceId, this.editItem});

  final String deviceId;
  final AdminDeviceComponent? editItem;

  @override
  ConsumerState<_ComponentUpsertDialog> createState() =>
      _ComponentUpsertDialogState();
}

class _ComponentUpsertDialogState
    extends ConsumerState<_ComponentUpsertDialog> {
  final _formKey = GlobalKey<FormState>();
  final _gpioController = TextEditingController();
  final _nameController = TextEditingController();

  bool get _isEdit => widget.editItem != null;

  @override
  void initState() {
    super.initState();
    final item = widget.editItem;
    _gpioController.text = item == null ? '' : item.gpioPin.toString();
    _nameController.text = item?.name ?? '';
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
                  hintText: 'Enter GPIO pin',
                  labelText: 'gpioPin',
                  keyboardType: TextInputType.number,
                  validator: _validatePin,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _nameController,
                  hintText: 'Enter name',
                  labelText: 'name',
                  validator: (value) => _required(value, 'name'),
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
}

class _DeleteComponentDialog extends ConsumerWidget {
  const _DeleteComponentDialog({
    required this.deviceId,
    required this.compId,
    required this.name,
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
