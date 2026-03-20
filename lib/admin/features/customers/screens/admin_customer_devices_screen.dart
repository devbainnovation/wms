import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wms/admin/features/customers/providers/admin_customers_providers.dart';
import 'package:wms/admin/features/customers/screens/admin_customer_device_dialogs.dart';
import 'package:wms/admin/features/customers/screens/admin_customer_device_widgets.dart';
import 'package:wms/admin/features/customers/services/admin_customer_service.dart';
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
        child: AppSectionCard(
          width: double.infinity,
          radius: 16,
          padding: EdgeInsets.all(isMobile ? 14 : 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: CustomerDeviceHeader(
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
                                return AssignedDeviceCard(
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
                          PaginationBar(
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
      builder: (_) => AssignCustomerDevicesDialog(customer: customer),
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
      builder: (_) => EditCustomerComponentDialog(
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
