import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wms/admin/features/customers/providers/admin_customers_providers.dart';
import 'package:wms/admin/features/customers/services/admin_customer_service.dart';
import 'package:wms/admin/features/devices/providers/admin_device_components_providers.dart';
import 'package:wms/admin/features/devices/services/admin_device_component_service.dart';
import 'package:wms/core/core.dart';
import 'package:wms/shared/shared.dart';

final _adminCustomerDevicesUiProvider = NotifierProvider.autoDispose<
    _AdminCustomerDevicesUiNotifier, _AdminCustomerDevicesUiState>(
  _AdminCustomerDevicesUiNotifier.new,
);

class _AdminCustomerDevicesUiState {
  const _AdminCustomerDevicesUiState({
    this.expandedDeviceIds = const <String>{},
    this.componentSchedules =
        const <String, Map<int, List<AppScheduleTimeRange>>>{},
  });

  final Set<String> expandedDeviceIds;
  final Map<String, Map<int, List<AppScheduleTimeRange>>> componentSchedules;

  _AdminCustomerDevicesUiState copyWith({
    Set<String>? expandedDeviceIds,
    Map<String, Map<int, List<AppScheduleTimeRange>>>? componentSchedules,
  }) {
    return _AdminCustomerDevicesUiState(
      expandedDeviceIds: expandedDeviceIds ?? this.expandedDeviceIds,
      componentSchedules: componentSchedules ?? this.componentSchedules,
    );
  }
}

class _AdminCustomerDevicesUiNotifier extends Notifier<_AdminCustomerDevicesUiState> {
  @override
  _AdminCustomerDevicesUiState build() {
    return const _AdminCustomerDevicesUiState();
  }

  void toggleExpanded(String deviceId) {
    final nextExpanded = Set<String>.from(state.expandedDeviceIds);
    if (!nextExpanded.add(deviceId)) {
      nextExpanded.remove(deviceId);
    }
    state = state.copyWith(expandedDeviceIds: nextExpanded);
  }

  void saveSchedules(
    String componentKey,
    Map<int, List<AppScheduleTimeRange>> schedules,
  ) {
    state = state.copyWith(
      componentSchedules: {
        ...state.componentSchedules,
        componentKey: schedules,
      },
    );
  }
}

class AdminCustomerDevicesScreen extends ConsumerWidget {
  const AdminCustomerDevicesScreen({required this.customer, super.key});

  final AdminCustomerSummary customer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devicesAsync = ref.watch(
      adminCustomerAssignedDevicesProvider(customer.id),
    );
    final uiState = ref.watch(_adminCustomerDevicesUiProvider);
    final unassignState = ref.watch(
      adminUnassignCustomerDeviceControllerProvider,
    );
    final isMobile = MediaQuery.sizeOf(context).width < 900;
    final isUnassigning = unassignState.isLoading;

    return Scaffold(
      backgroundColor: const Color(0xFFF7FBFC),
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0.5,
        title: Text(
          customer.fullName.trim().isEmpty
              ? 'Assigned Devices'
              : 'Assigned Devices • ${customer.fullName}',
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(isMobile ? 12 : 20),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.lightGreyText),
          ),
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 14 : 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _CustomerDeviceHeader(
                        customer: customer,
                        isMobile: isMobile,
                      ),
                    ),
                    if (!isMobile) ...[
                      const SizedBox(width: 12),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primaryTeal,
                          foregroundColor: AppColors.white,
                        ),
                        onPressed: () =>
                            _openAssignDeviceDialog(context, ref, customer),
                        icon: const Icon(Icons.add_link_rounded),
                        label: const Text('Assign Device'),
                      ),
                    ],
                  ],
                ),
                if (isMobile) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primaryTeal,
                        foregroundColor: AppColors.white,
                      ),
                      onPressed: () =>
                          _openAssignDeviceDialog(context, ref, customer),
                      icon: const Icon(Icons.add_link_rounded),
                      label: const Text('Assign Device'),
                    ),
                  ),
                ],
                SizedBox(height: isMobile ? 14 : 18),
                Expanded(
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
                                : 'Unable to load assigned devices.',
                            style: const TextStyle(
                              color: AppColors.red,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () => ref.invalidate(
                              adminCustomerAssignedDevicesProvider(customer.id),
                            ),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                    data: (result) {
                      if (result.items.isEmpty) {
                        return const Center(
                          child: Text(
                            'No assigned devices found for this customer.',
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
                              itemCount: result.items.length,
                              separatorBuilder: (_, index) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final item = result.items[index];
                                return _AssignedDeviceCard(
                                  item: item,
                                  isMobile: isMobile,
                                  isUnassigning: isUnassigning,
                                  expanded: uiState.expandedDeviceIds.contains(
                                    item.espId,
                                  ),
                                  onToggleComponents: () {
                                    ref
                                        .read(
                                          _adminCustomerDevicesUiProvider
                                              .notifier,
                                        )
                                        .toggleExpanded(item.espId);
                                  },
                                  onUnassign: () => _confirmUnassign(
                                    context: context,
                                    ref: ref,
                                    customerId: customer.id,
                                    espId: item.espId,
                                    deviceName: item.displayName,
                                  ),
                                  onEditComponent: (component) =>
                                      _openEditComponentDialog(
                                        context: context,
                                        ref: ref,
                                        customerId: customer.id,
                                        deviceId: item.espId,
                                        component: component,
                                      ),
                                  onOpenSchedules: (component) =>
                                      _openScheduleDialog(
                                        context: context,
                                        ref: ref,
                                        customerId: customer.id,
                                        component: component,
                                      ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 12),
                          _PaginationBar(
                            isMobile: isMobile,
                            page: result.page,
                            totalPages: result.totalPages,
                            totalElements: result.totalElements,
                            hasPrevious: result.hasPrevious,
                            hasNext: result.hasNext,
                            onPrevious: () {
                              ref
                                  .read(
                                    adminCustomerDevicesQueryProvider(
                                      customer.id,
                                    ).notifier,
                                  )
                                  .previous();
                            },
                            onNext: () {
                              ref
                                  .read(
                                    adminCustomerDevicesQueryProvider(
                                      customer.id,
                                    ).notifier,
                                  )
                                  .next();
                            },
                          ),
                        ],
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

  Future<void> _openAssignDeviceDialog(
    BuildContext context,
    WidgetRef ref,
    AdminCustomerSummary customer,
  ) async {
    final assigned = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _AssignCustomerDevicesDialog(customer: customer),
    );

    if (assigned != true || !context.mounted) {
      return;
    }

    ref.invalidate(adminCustomerAssignedDevicesProvider(customer.id));
    ref.invalidate(adminUnassignedDevicesProvider);
    ref.invalidate(adminCustomersListProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Device assignment updated successfully.')),
    );
  }

  Future<void> _confirmUnassign({
    required BuildContext context,
    required WidgetRef ref,
    required String customerId,
    required String espId,
    required String deviceName,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.lightBackground,
        title: const Text('Unassign Device'),
        content: Text(
          'Do you want to unassign "${deviceName.trim().isEmpty ? espId : deviceName}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Unassign'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    try {
      final message = await ref
          .read(adminUnassignCustomerDeviceControllerProvider.notifier)
          .unassign(espId: espId);
      ref.invalidate(adminCustomerAssignedDevicesProvider(customerId));
      ref.invalidate(adminUnassignedDevicesProvider);
      ref.invalidate(adminCustomersListProvider);
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      final message = error is ApiException
          ? error.message
          : 'Unable to unassign device.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _openEditComponentDialog({
    required BuildContext context,
    required WidgetRef ref,
    required String customerId,
    required String deviceId,
    required AdminCustomerDeviceComponent component,
  }) async {
    final updated = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _EditCustomerComponentDialog(
        deviceId: deviceId,
        component: component,
      ),
    );

    if (updated != true || !context.mounted) {
      return;
    }

    ref.invalidate(adminCustomerAssignedDevicesProvider(customerId));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Component updated successfully.')),
    );
  }

  Future<void> _openScheduleDialog(
    {
    required BuildContext context,
    required WidgetRef ref,
    required String customerId,
    required AdminCustomerDeviceComponent component,
  }) async {
    final componentKey = _componentScheduleKey(component);
    final saved =
        ref.read(_adminCustomerDevicesUiProvider).componentSchedules[componentKey] ??
        const <int, List<AppScheduleTimeRange>>{};

    final schedules = await showDialog<Map<int, List<AppScheduleTimeRange>>>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AppScheduleEditorDialog(
        title:
            'Schedules • ${component.name.trim().isEmpty ? component.type : component.name}',
        initialSchedules: saved,
      ),
    );

    if (schedules == null || !context.mounted) {
      return;
    }

    ref
        .read(_adminCustomerDevicesUiProvider.notifier)
        .saveSchedules(componentKey, schedules);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Schedule saved locally. Connect a schedule API to persist it.',
        ),
      ),
    );
  }

  String _componentScheduleKey(AdminCustomerDeviceComponent component) {
    return '${component.componentId}|${component.gpioPin}|${component.name}';
  }
}

class _AssignCustomerDevicesDialog extends ConsumerStatefulWidget {
  const _AssignCustomerDevicesDialog({required this.customer});

  final AdminCustomerSummary customer;

  @override
  ConsumerState<_AssignCustomerDevicesDialog> createState() =>
      _AssignCustomerDevicesDialogState();
}

class _AssignCustomerDevicesDialogState
    extends ConsumerState<_AssignCustomerDevicesDialog> {
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

class _CustomerDeviceHeader extends StatelessWidget {
  const _CustomerDeviceHeader({required this.customer, required this.isMobile});

  final AdminCustomerSummary customer;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.lightBackground,
        borderRadius: BorderRadius.circular(14),
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _headline(),
                const SizedBox(height: 10),
                Wrap(spacing: 8, runSpacing: 8, children: _summaryChips()),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _headline(),
                const SizedBox(height: 10),
                Wrap(spacing: 8, runSpacing: 8, children: _summaryChips()),
              ],
            ),
    );
  }

  Widget _headline() {
    return Text(
      customer.fullName.trim().isEmpty ? customer.username : customer.fullName,
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: AppColors.darkText,
      ),
    );
  }

  List<Widget> _summaryChips() {
    return [
      _InfoChip(
        icon: Icons.person_outline_rounded,
        label: 'Username',
        value: _orDash(customer.username),
      ),
      _InfoChip(
        icon: Icons.phone_outlined,
        label: 'Phone',
        value: _orDash(customer.phoneNumber),
      ),
      _InfoChip(
        icon: Icons.email_outlined,
        label: 'Email',
        value: _orDash(customer.email),
      ),
      _InfoChip(
        icon: Icons.location_on_outlined,
        label: 'Address',
        value: _orDash(customer.formattedAddress),
      ),
    ];
  }
}

class _AssignedDeviceCard extends StatelessWidget {
  const _AssignedDeviceCard({
    required this.item,
    required this.isMobile,
    required this.isUnassigning,
    required this.expanded,
    required this.onToggleComponents,
    required this.onUnassign,
    required this.onEditComponent,
    required this.onOpenSchedules,
  });

  final AdminCustomerAssignedDevice item;
  final bool isMobile;
  final bool isUnassigning;
  final bool expanded;
  final VoidCallback onToggleComponents;
  final VoidCallback onUnassign;
  final ValueChanged<AdminCustomerDeviceComponent> onEditComponent;
  final ValueChanged<AdminCustomerDeviceComponent> onOpenSchedules;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.lightGreyText),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isMobile) _mobileHeader() else _desktopHeader(),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _InfoChip(
                icon: Icons.memory_rounded,
                label: 'ESP ID',
                value: _orDash(item.espId),
              ),
              _InfoChip(
                icon: Icons.badge_outlined,
                label: 'MAC',
                value: _orDash(item.macAddress),
              ),
              _InfoChip(
                icon: Icons.update_rounded,
                label: 'FW Version',
                value: _orDash(item.fwVersion),
              ),
              _InfoChip(
                icon: Icons.calendar_today_outlined,
                label: 'Created',
                value: _formatDate(item.createdAt),
              ),
              _InfoChip(
                icon: Icons.favorite_outline_rounded,
                label: 'Last Heartbeat',
                value: _formatDate(item.lastHeartbeat),
              ),
              _InfoChip(
                icon: Icons.verified_outlined,
                label: 'AMC Expiry',
                value: _formatDate(item.amcExpiry),
              ),
              _InfoChip(
                icon: Icons.currency_rupee_rounded,
                label: 'Recharge Expiry',
                value: _formatDate(item.rechargeExpiry),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Text(
                '${item.components.length} component${item.components.length == 1 ? '' : 's'}',
                style: const TextStyle(
                  color: AppColors.greyText,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: onToggleComponents,
                icon: Icon(
                  expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                ),
                label: Text(
                  expanded ? 'Hide components' : 'View all components',
                ),
              ),
            ],
          ),
          if (expanded) ...[
            const Divider(height: 18),
            if (item.components.isEmpty)
              const Text(
                'No components available.',
                style: TextStyle(
                  color: AppColors.greyText,
                  fontWeight: FontWeight.w600,
                ),
              )
            else
              Column(
                children: item.components
                    .map(
                      (component) => _ComponentTile(
                        component: component,
                        onEdit: () => onEditComponent(component),
                        onOpenSchedules: onOpenSchedules,
                      ),
                    )
                    .toList(),
              ),
          ],
        ],
      ),
    );
  }

  Widget _desktopHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _orDash(item.displayName),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkText,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.espId.trim().isEmpty ? 'Unnamed device' : item.espId,
                style: const TextStyle(color: AppColors.greyText),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.end,
          children: [
            _statusBadge(
              label: item.active ? 'Active' : 'Inactive',
              active: item.active,
            ),
            _statusBadge(
              label: item.online ? 'Online' : 'Offline',
              active: item.online,
            ),
            _unassignBadge(),
          ],
        ),
      ],
    );
  }

  Widget _mobileHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _orDash(item.displayName),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.darkText,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          item.espId.trim().isEmpty ? 'Unnamed device' : item.espId,
          style: const TextStyle(color: AppColors.greyText),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _statusBadge(
              label: item.active ? 'Active' : 'Inactive',
              active: item.active,
            ),
            _statusBadge(
              label: item.online ? 'Online' : 'Offline',
              active: item.online,
            ),
            _unassignBadge(),
          ],
        ),
      ],
    );
  }

  Widget _statusBadge({required String label, required bool active}) {
    final color = active ? AppColors.accentGreen : AppColors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _unassignBadge() {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: isUnassigning ? null : onUnassign,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.red.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
        ),
        child: isUnassigning
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.red,
                ),
              )
            : const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.link_off_rounded, size: 14, color: AppColors.red),
                  SizedBox(width: 6),
                  Text(
                    'Unassign Device',
                    style: TextStyle(
                      color: AppColors.red,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _ComponentTile extends StatelessWidget {
  const _ComponentTile({
    required this.component,
    required this.onEdit,
    required this.onOpenSchedules,
  });

  final AdminCustomerDeviceComponent component;
  final VoidCallback onEdit;
  final ValueChanged<AdminCustomerDeviceComponent> onOpenSchedules;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.lightBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                _orDash(component.name),
                style: const TextStyle(
                  color: AppColors.darkText,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Edit Component',
                onPressed: onEdit,
                icon: const Icon(Icons.edit_rounded, color: AppColors.blue),
              ),
              IconButton(
                tooltip: 'Schedules',
                onPressed: () => onOpenSchedules(component),
                icon: const Icon(
                  Icons.schedule_rounded,
                  color: AppColors.primaryTeal,
                ),
              ),
            ],
          ),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _InfoChip(
                icon: Icons.precision_manufacturing_outlined,
                label: 'Name',
                value: _orDash(component.name),
              ),
              _InfoChip(
                icon: Icons.category_outlined,
                label: 'Type',
                value: _orDash(component.type),
              ),
              _InfoChip(
                icon: Icons.settings_input_component_outlined,
                label: 'GPIO',
                value: '${component.gpioPin}',
              ),
              _InfoChip(
                icon: Icons.power_settings_new_rounded,
                label: 'State',
                value: _orDash(component.currentState),
              ),
              _InfoChip(
                icon: Icons.toggle_on_outlined,
                label: 'Status',
                value: component.active ? 'Active' : 'Inactive',
              ),
              _InfoChip(
                icon: Icons.schedule_rounded,
                label: 'Changed At',
                value: _formatDate(component.stateChangedAt),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EditCustomerComponentDialog extends ConsumerStatefulWidget {
  const _EditCustomerComponentDialog({
    required this.deviceId,
    required this.component,
  });

  final String deviceId;
  final AdminCustomerDeviceComponent component;

  @override
  ConsumerState<_EditCustomerComponentDialog> createState() =>
      _EditCustomerComponentDialogState();
}

class _EditCustomerComponentDialogState
    extends ConsumerState<_EditCustomerComponentDialog> {
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
          .read(_customerComponentTypeProvider.notifier)
          .set(_parseCustomerComponentType(widget.component.type));
      ref
          .read(_customerComponentActiveProvider.notifier)
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
    final selectedType = ref.watch(_customerComponentTypeProvider);
    final isActive = ref.watch(_customerComponentActiveProvider);
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
                              .read(_customerComponentTypeProvider.notifier)
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
                                .read(_customerComponentActiveProvider.notifier)
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
      type: ref.read(_customerComponentTypeProvider),
      gpioPin: int.parse(_gpioController.text.trim()),
      name: _nameController.text.trim(),
      active: ref.read(_customerComponentActiveProvider),
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

final _customerComponentTypeProvider =
    NotifierProvider.autoDispose<
      _CustomerComponentTypeNotifier,
      AdminComponentType
    >(_CustomerComponentTypeNotifier.new);

class _CustomerComponentTypeNotifier extends Notifier<AdminComponentType> {
  @override
  AdminComponentType build() => AdminComponentType.valve;

  void set(AdminComponentType value) => state = value;
}

final _customerComponentActiveProvider =
    NotifierProvider.autoDispose<_CustomerComponentActiveNotifier, bool>(
      _CustomerComponentActiveNotifier.new,
    );

class _CustomerComponentActiveNotifier extends Notifier<bool> {
  @override
  bool build() => true;

  void set(bool value) => state = value;
}

AdminComponentType _parseCustomerComponentType(String raw) {
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

class _PaginationBar extends StatelessWidget {
  const _PaginationBar({
    required this.isMobile,
    required this.page,
    required this.totalPages,
    required this.totalElements,
    required this.hasPrevious,
    required this.hasNext,
    required this.onPrevious,
    required this.onNext,
  });

  final bool isMobile;
  final int page;
  final int totalPages;
  final int totalElements;
  final bool hasPrevious;
  final bool hasNext;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final summary = 'Page ${page + 1} of $totalPages • Total $totalElements';
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            summary,
            style: const TextStyle(
              color: AppColors.greyText,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              OutlinedButton(
                onPressed: hasPrevious ? onPrevious : null,
                child: const Text('Previous'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: hasNext ? onNext : null,
                child: const Text('Next'),
              ),
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        Text(
          summary,
          style: const TextStyle(
            color: AppColors.greyText,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        OutlinedButton(
          onPressed: hasPrevious ? onPrevious : null,
          child: const Text('Previous'),
        ),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: hasNext ? onNext : null,
          child: const Text('Next'),
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 180),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.lightBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.primaryTeal),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.greyText,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.darkText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _formatDate(DateTime? value) {
  if (value == null) {
    return '-';
  }
  return AppDateTimeFormatter.formatDateTime(value);
}

String _orDash(String value) {
  final normalized = value.trim();
  return normalized.isEmpty ? '-' : normalized;
}
