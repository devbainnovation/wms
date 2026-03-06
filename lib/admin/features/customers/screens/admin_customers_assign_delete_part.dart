part of 'admin_customers_screen.dart';

class _AssignDevicesDialog extends ConsumerStatefulWidget {
  const _AssignDevicesDialog({required this.customer});

  final AdminCustomerSummary customer;

  @override
  ConsumerState<_AssignDevicesDialog> createState() =>
      _AssignDevicesDialogState();
}

class _AssignDevicesDialogState extends ConsumerState<_AssignDevicesDialog> {
  late final List<String> _selectedEspUnitIds;

  @override
  void initState() {
    super.initState();
    _selectedEspUnitIds = [...widget.customer.espUnitIds];
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
        width: 520,
        child: devicesAsync.when(
          loading: () => const SizedBox(
            height: 120,
            child: Center(
              child: CircularProgressIndicator(color: AppColors.primaryTeal),
            ),
          ),
          error: (error, _) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                error is ApiException
                    ? error.message
                    : 'Unable to load unassigned devices.',
                style: const TextStyle(color: AppColors.red),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref.invalidate(adminUnassignedDevicesProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
          data: (devices) {
            final uniqueDevices = <String, AdminUnassignedDevice>{};
            for (final device in devices) {
              uniqueDevices[device.id] = device;
            }

            final selectedIds = widget.customer.espUnitIds
                .where((id) => id.trim().isNotEmpty)
                .toList();
            for (final id in selectedIds) {
              uniqueDevices.putIfAbsent(
                id,
                () => AdminUnassignedDevice(id: id, displayName: id),
              );
            }

            final allDevices = uniqueDevices.values.toList()
              ..sort((a, b) => a.displayName.compareTo(b.displayName));

            final canPick = allDevices.isNotEmpty && !isLoading;

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Selected devices',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkText,
                  ),
                ),
                const SizedBox(height: 8),
                if (_selectedEspUnitIds.isEmpty)
                  const Text(
                    'No devices selected.',
                    style: TextStyle(color: AppColors.greyText),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _selectedEspUnitIds.map((id) {
                      final match = uniqueDevices[id];
                      final display = match == null
                          ? id
                          : '${match.displayName} (${match.id})';
                      return Chip(
                        label: Text(display),
                        onDeleted: isLoading
                            ? null
                            : () => setState(() {
                                _selectedEspUnitIds.remove(id);
                              }),
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: canPick
                        ? () async {
                            final selected = await _openDeviceSearchDialog(
                              allDevices,
                            );
                            if (selected == null) {
                              return;
                            }
                            if (_selectedEspUnitIds.contains(selected.id)) {
                              return;
                            }
                            setState(
                              () => _selectedEspUnitIds.add(selected.id),
                            );
                          }
                        : null,
                    icon: const Icon(Icons.search_rounded),
                    label: Text(
                      canPick
                          ? 'Search and select device (${allDevices.length} available)'
                          : 'No devices available',
                    ),
                  ),
                ),
              ],
            );
          },
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
              : const Text('Save'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    try {
      await ref
          .read(adminAssignDevicesCustomerControllerProvider.notifier)
          .assign(
            customerId: widget.customer.id,
            espUnitIds: _selectedEspUnitIds,
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

  Future<AdminUnassignedDevice?> _openDeviceSearchDialog(
    List<AdminUnassignedDevice> devices,
  ) async {
    final queryController = TextEditingController();
    final query = ValueNotifier<String>('');
    final selected = await showDialog<AdminUnassignedDevice>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.white,
          title: const Text('Select Device'),
          content: SizedBox(
            width: 520,
            height: 420,
            child: Column(
              children: [
                TextField(
                  controller: queryController,
                  decoration: const InputDecoration(
                    hintText: 'Search by device name or ID',
                    prefixIcon: Icon(Icons.search_rounded),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) =>
                      query.value = value.trim().toLowerCase(),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ValueListenableBuilder<String>(
                    valueListenable: query,
                    builder: (context, value, child) {
                      final filtered = devices.where((device) {
                        final haystack = '${device.displayName} ${device.id}'
                            .toLowerCase();
                        return haystack.contains(value);
                      }).toList();

                      if (filtered.isEmpty) {
                        return const Center(
                          child: Text(
                            'No matching devices.',
                            style: TextStyle(color: AppColors.greyText),
                          ),
                        );
                      }

                      return ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, index) =>
                            const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final device = filtered[index];
                          return ListTile(
                            title: Text(device.displayName),
                            subtitle: Text(device.id),
                            onTap: () =>
                                Navigator.of(dialogContext).pop(device),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
    queryController.dispose();
    query.dispose();
    return selected;
  }
}

class _DeleteCustomerDialog extends ConsumerWidget {
  const _DeleteCustomerDialog({
    required this.customerId,
    required this.customerName,
  });

  final String customerId;
  final String customerName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminDeleteCustomerControllerProvider);

    return AlertDialog(
      backgroundColor: AppColors.lightBackground,
      title: const Text('Delete Customer'),
      content: Text(
        'Are you sure you want to delete "${customerName.trim().isEmpty ? customerId : customerName}"? This action cannot be undone.',
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
                        : 'Unable to delete customer.';
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
