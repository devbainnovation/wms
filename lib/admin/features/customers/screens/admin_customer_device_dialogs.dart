import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wms/admin/features/customers/providers/admin_customers_providers.dart';
import 'package:wms/admin/features/customers/services/admin_customer_service.dart';
import 'package:wms/admin/features/devices/providers/admin_device_components_providers.dart';
import 'package:wms/admin/features/devices/services/admin_device_component_service.dart';
import 'package:wms/core/core.dart';
import 'package:wms/shared/shared.dart';

class AssignCustomerDevicesDialog extends ConsumerStatefulWidget {
  const AssignCustomerDevicesDialog({required this.customer, super.key});

  final AdminCustomerSummary customer;

  @override
  ConsumerState<AssignCustomerDevicesDialog> createState() =>
      _AssignCustomerDevicesDialogState();
}

class _AssignCustomerDevicesDialogState
    extends ConsumerState<AssignCustomerDevicesDialog> {
  final _formKey = GlobalKey<FormState>();
  final _searchController = TextEditingController();
  final Set<String> _selectedDeviceIds = <String>{};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final devicesAsync = ref.watch(adminUnassignedDevicesProvider);
    final assignState = ref.watch(adminAssignDevicesCustomerControllerProvider);
    final isLoading = assignState.isLoading;

    return AlertDialog(
      backgroundColor: AppColors.lightBackground,
      title: const Text('Assign Device'),
      content: SizedBox(
        width: 720,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              devicesAsync.when(
                loading: () => const SizedBox(
                  height: 180,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryTeal,
                    ),
                  ),
                ),
                error: (error, _) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      error is ApiException
                          ? error.message
                          : 'Unable to load unassigned devices.',
                      style: const TextStyle(color: AppColors.red),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () =>
                          ref.invalidate(adminUnassignedDevicesProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
                data: (devices) {
                  final uniqueDevices = <String, AdminUnassignedDevice>{};
                  for (final device in devices) {
                    uniqueDevices[device.id] = device;
                  }

                  final availableDevices = uniqueDevices.values.toList()
                    ..sort((a, b) => a.displayName.compareTo(b.displayName));
                  final query = _searchController.text.trim().toLowerCase();
                  final filteredDevices = availableDevices.where((device) {
                    if (query.isEmpty) {
                      return true;
                    }
                    final haystack = '${device.displayName} ${device.id}'
                        .toLowerCase();
                    return haystack.contains(query);
                  }).toList();

                  return StatefulBuilder(
                    builder: (context, setLocalState) {
                      void toggleSelection(String id, bool selected) {
                        setLocalState(() {
                          if (selected) {
                            _selectedDeviceIds.add(id);
                          } else {
                            _selectedDeviceIds.remove(id);
                          }
                        });
                      }

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Unassigned Devices',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.darkText,
                                  ),
                                ),
                              ),
                              Text(
                                '${_selectedDeviceIds.length} selected',
                                style: const TextStyle(
                                  color: AppColors.greyText,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _searchController,
                            onChanged: (_) => setLocalState(() {}),
                            decoration: const InputDecoration(
                              hintText: 'Search by device name or ID',
                              prefixIcon: Icon(Icons.search_rounded),
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (_selectedDeviceIds.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: availableDevices
                                    .where(
                                      (device) => _selectedDeviceIds.contains(
                                        device.id,
                                      ),
                                    )
                                    .map(
                                      (device) => Chip(
                                        label: Text(
                                          '${device.displayName} (${device.id})',
                                        ),
                                        onDeleted: isLoading
                                            ? null
                                            : () => toggleSelection(
                                                device.id,
                                                false,
                                              ),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
                          Container(
                            constraints: const BoxConstraints(maxHeight: 320),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: AppColors.lightGreyText,
                              ),
                            ),
                            child: filteredDevices.isEmpty
                                ? const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(20),
                                      child: Text(
                                        'No unassigned devices found.',
                                        style: TextStyle(
                                          color: AppColors.greyText,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  )
                                : ListView.separated(
                                    shrinkWrap: true,
                                    itemCount: filteredDevices.length,
                                    separatorBuilder: (_, index) =>
                                        const Divider(height: 1),
                                    itemBuilder: (context, index) {
                                      final device = filteredDevices[index];
                                      final selected = _selectedDeviceIds
                                          .contains(device.id);
                                      return CheckboxListTile(
                                        value: selected,
                                        dense: true,
                                        activeColor: AppColors.primaryTeal,
                                        controlAffinity:
                                            ListTileControlAffinity.leading,
                                        onChanged: isLoading
                                            ? null
                                            : (value) => toggleSelection(
                                                device.id,
                                                value ?? false,
                                              ),
                                        title: Text(
                                          device.displayName.isEmpty
                                              ? device.id
                                              : device.displayName,
                                        ),
                                        subtitle: Text(device.id),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ],
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
              : const Text('Assign'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (_selectedDeviceIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one device to assign.')),
      );
      return;
    }

    try {
      await ref
          .read(adminAssignDevicesCustomerControllerProvider.notifier)
          .assign(
            customerId: widget.customer.id,
            espUnitIds: [...widget.customer.espUnitIds, ..._selectedDeviceIds],
          );
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
          : 'Unable to assign device(s).';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }
}

class EditCustomerComponentDialog extends ConsumerStatefulWidget {
  const EditCustomerComponentDialog({
    required this.deviceId,
    required this.component,
    super.key,
  });

  final String deviceId;
  final AdminCustomerDeviceComponent component;

  @override
  ConsumerState<EditCustomerComponentDialog> createState() =>
      _EditCustomerComponentDialogState();
}

class _EditCustomerComponentDialogState
    extends ConsumerState<EditCustomerComponentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _gpioController = TextEditingController();
  final _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _gpioController.text = widget.component.gpioPin.toString();
    _nameController.text = widget.component.name;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      ref
          .read(customerComponentTypeProvider.notifier)
          .set(parseCustomerComponentType(widget.component.type));
      ref
          .read(customerComponentActiveProvider.notifier)
          .set(widget.component.active);
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
    final updateState = ref.watch(adminUpdateComponentControllerProvider);
    final selectedType = ref.watch(customerComponentTypeProvider);
    final isActive = ref.watch(customerComponentActiveProvider);
    final isLoading = updateState.isLoading;

    return AlertDialog(
      backgroundColor: AppColors.lightBackground,
      title: const Text('Edit Component'),
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
                              .read(customerComponentTypeProvider.notifier)
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
                                .read(customerComponentActiveProvider.notifier)
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
              : const Text('Update'),
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
      type: ref.read(customerComponentTypeProvider),
      gpioPin: int.parse(_gpioController.text.trim()),
      name: _nameController.text.trim(),
      installedArea: '',
      active: ref.read(customerComponentActiveProvider),
    );

    try {
      await ref
          .read(adminUpdateComponentControllerProvider.notifier)
          .update(
            deviceId: widget.deviceId,
            compId: widget.component.componentId.toString(),
            request: request,
          );
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
          : 'Unable to update component.';
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

final customerComponentTypeProvider =
    NotifierProvider.autoDispose<
      _CustomerComponentTypeNotifier,
      AdminComponentType
    >(_CustomerComponentTypeNotifier.new);

class _CustomerComponentTypeNotifier extends Notifier<AdminComponentType> {
  @override
  AdminComponentType build() => AdminComponentType.valve;

  void set(AdminComponentType value) => state = value;
}

final customerComponentActiveProvider =
    NotifierProvider.autoDispose<_CustomerComponentActiveNotifier, bool>(
      _CustomerComponentActiveNotifier.new,
    );

class _CustomerComponentActiveNotifier extends Notifier<bool> {
  @override
  bool build() => true;

  void set(bool value) => state = value;
}

AdminComponentType parseCustomerComponentType(String raw) {
  switch (raw.trim().toUpperCase()) {
    case 'SENSOR':
      return AdminComponentType.sensor;
    case 'MOTOR':
      return AdminComponentType.motor;
    case 'VALVE':
    default:
      return AdminComponentType.valve;
  }
}
