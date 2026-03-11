import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wms/admin/features/customers/screens/admin_customer_devices_screen.dart';
import 'package:wms/admin/features/customers/providers/admin_customers_providers.dart';
import 'package:wms/admin/features/customers/services/admin_customer_service.dart';
import 'package:wms/core/core.dart';
import 'package:wms/shared/shared.dart';

part 'admin_customers_tile_part.dart';
part 'admin_customers_create_dialog_part.dart';
part 'admin_customers_edit_dialog_part.dart';
part 'admin_customers_assign_delete_part.dart';

final _customerFormUiProvider =
    NotifierProvider.autoDispose<_CustomerFormUiNotifier, _CustomerFormUiState>(
      _CustomerFormUiNotifier.new,
    );

class _CustomerFormUiState {
  const _CustomerFormUiState({
    required this.selectedCountry,
    required this.selectedDevices,
    required this.obscurePassword,
    required this.isActive,
  });

  final _CountryDialCode selectedCountry;
  final List<AdminUnassignedDevice> selectedDevices;
  final bool obscurePassword;
  final bool isActive;

  _CustomerFormUiState copyWith({
    _CountryDialCode? selectedCountry,
    List<AdminUnassignedDevice>? selectedDevices,
    bool? obscurePassword,
    bool? isActive,
  }) {
    return _CustomerFormUiState(
      selectedCountry: selectedCountry ?? this.selectedCountry,
      selectedDevices: selectedDevices ?? this.selectedDevices,
      obscurePassword: obscurePassword ?? this.obscurePassword,
      isActive: isActive ?? this.isActive,
    );
  }
}

class _CustomerFormUiNotifier extends Notifier<_CustomerFormUiState> {
  @override
  _CustomerFormUiState build() {
    return _CustomerFormUiState(
      selectedCountry: _CustomerCreateDialogState._countryDialCodes.first,
      selectedDevices: const <AdminUnassignedDevice>[],
      obscurePassword: true,
      isActive: true,
    );
  }

  void setCountry(_CountryDialCode country) {
    state = state.copyWith(selectedCountry: country);
  }

  void setCountryByIsoCode(String? isoCode) {
    if (isoCode == null || isoCode.trim().isEmpty) {
      return;
    }
    final upperIso = isoCode.toUpperCase();
    final match = _CustomerCreateDialogState._countryDialCodes.where((item) {
      return item.isoCode.toUpperCase() == upperIso;
    });
    if (match.isEmpty) {
      return;
    }
    state = state.copyWith(selectedCountry: match.first);
  }

  void addDeviceFromPicker(AdminUnassignedDevice device) {
    if (state.selectedDevices.any((d) => d.id == device.id)) {
      return;
    }
    state = state.copyWith(selectedDevices: [...state.selectedDevices, device]);
  }

  void removeDeviceById(String id) {
    state = state.copyWith(
      selectedDevices: state.selectedDevices
          .where((item) => item.id != id)
          .toList(),
    );
  }

  void togglePasswordVisibility() {
    state = state.copyWith(obscurePassword: !state.obscurePassword);
  }

  void setActive(bool value) {
    state = state.copyWith(isActive: value);
  }
}

class AdminCustomersScreen extends ConsumerStatefulWidget {
  const AdminCustomersScreen({super.key});

  @override
  ConsumerState<AdminCustomersScreen> createState() =>
      _AdminCustomersScreenState();
}

class _AdminCustomersScreenState extends ConsumerState<AdminCustomersScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(adminCustomersListProvider);
    final query = ref.watch(adminCustomersQueryProvider);
    final isMobile = MediaQuery.sizeOf(context).width < 900;

    return Padding(
      padding: EdgeInsets.all(isMobile ? 12 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Customers',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppColors.darkText,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primaryTeal,
                          foregroundColor: AppColors.white,
                        ),
                        onPressed: _openAddCustomerDialog,
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Add Customer'),
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    const Text(
                      'Customers',
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
                      onPressed: _openAddCustomerDialog,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Add Customer'),
                    ),
                  ],
                ),
          const SizedBox(height: 14),
          AppTextField(
            controller: _searchController,
            hintText: 'Search customer by text',
            labelText: 'Search',
            prefixIcon: const Icon(Icons.search_rounded),
            onChanged: (value) {
              final normalized = value.trim();
              if (normalized == query.search) {
                return;
              }
              ref.read(adminCustomersQueryProvider.notifier).setSearch(value);
            },
          ),
          const SizedBox(height: 14),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.lightGreyText),
              ),
              child: customersAsync.when(
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
                            : 'Unable to load customers.',
                        style: const TextStyle(
                          color: AppColors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () =>
                            ref.invalidate(adminCustomersListProvider),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
                data: (result) {
                  if (result.items.isEmpty) {
                    return const Center(
                      child: Text(
                        'No customers found.',
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
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) => _CustomerTile(
                            item: result.items[index],
                            isMobile: isMobile,
                            onAssignDevice: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => AdminCustomerDevicesScreen(
                                    customer: result.items[index],
                                  ),
                                ),
                              );
                            },
                            onEdit: () async {
                              final updated = await showDialog<bool>(
                                context: context,
                                barrierDismissible: false,
                                builder: (_) => _EditCustomerDialog(
                                  customer: result.items[index],
                                ),
                              );
                              if (updated == true) {
                                ref.invalidate(adminCustomersListProvider);
                                if (!context.mounted) {
                                  return;
                                }
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Customer updated successfully.',
                                    ),
                                  ),
                                );
                              }
                            },
                            onDelete: () async {
                              final deleted = await showDialog<bool>(
                                context: context,
                                builder: (_) => _DeleteCustomerDialog(
                                  customerId: result.items[index].id,
                                  customerName: result.items[index].fullName,
                                ),
                              );
                              if (deleted == true) {
                                ref.invalidate(adminCustomersListProvider);
                                if (!context.mounted) {
                                  return;
                                }
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Customer deleted successfully.',
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
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
                                                      adminCustomersQueryProvider
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
                                                      adminCustomersQueryProvider
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
                                                  adminCustomersQueryProvider
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
                                                  adminCustomersQueryProvider
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

  Future<void> _openAddCustomerDialog() async {
    final created = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _CustomerCreateDialog(),
    );

    if (!mounted || created != true) {
      return;
    }

    ref.invalidate(adminCustomersListProvider);
    ref.invalidate(adminUnassignedDevicesProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Customer created successfully.')),
    );
  }
}
