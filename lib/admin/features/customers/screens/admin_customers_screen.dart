import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wms/admin/features/customers/providers/admin_customers_providers.dart';
import 'package:wms/admin/features/customers/services/admin_customer_service.dart';
import 'package:wms/core/core.dart';
import 'package:wms/shared/shared.dart';

final _customerFormUiProvider =
    NotifierProvider.autoDispose<_CustomerFormUiNotifier, _CustomerFormUiState>(
      _CustomerFormUiNotifier.new,
    );

class _CustomerFormUiState {
  const _CustomerFormUiState({
    required this.selectedCountry,
    required this.selectedDevices,
    required this.obscurePassword,
  });

  final _CountryDialCode selectedCountry;
  final List<AdminUnassignedDevice> selectedDevices;
  final bool obscurePassword;

  _CustomerFormUiState copyWith({
    _CountryDialCode? selectedCountry,
    List<AdminUnassignedDevice>? selectedDevices,
    bool? obscurePassword,
  }) {
    return _CustomerFormUiState(
      selectedCountry: selectedCountry ?? this.selectedCountry,
      selectedDevices: selectedDevices ?? this.selectedDevices,
      obscurePassword: obscurePassword ?? this.obscurePassword,
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

class _CustomerTile extends StatelessWidget {
  const _CustomerTile({required this.item, required this.isMobile});

  final AdminCustomerSummary item;
  final bool isMobile;

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
          flex: 2,
          child: Text(
            item.fullName.isEmpty ? '-' : item.fullName,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.darkText,
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            item.username.isEmpty ? '-' : item.username,
            style: const TextStyle(color: AppColors.darkText),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            item.phoneNumber.isEmpty ? '-' : item.phoneNumber,
            style: const TextStyle(color: AppColors.darkText),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            item.email.isEmpty ? '-' : item.email,
            style: const TextStyle(color: AppColors.darkText),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            item.village.isEmpty ? '-' : item.village,
            style: const TextStyle(color: AppColors.darkText),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            item.espUnitIds.isEmpty ? 'No devices' : item.espUnitIds.join(', '),
            style: const TextStyle(color: AppColors.greyText),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _mobileLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.fullName.isEmpty ? item.username : item.fullName,
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
            _metaChip('User: ${item.username.isEmpty ? '-' : item.username}'),
            _metaChip(
              'Phone: ${item.phoneNumber.isEmpty ? '-' : item.phoneNumber}',
            ),
            _metaChip('Village: ${item.village.isEmpty ? '-' : item.village}'),
            _metaChip(
              item.espUnitIds.isEmpty
                  ? 'Devices: None'
                  : 'Devices: ${item.espUnitIds.length}',
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
}

class _CustomerCreateDialog extends ConsumerStatefulWidget {
  const _CustomerCreateDialog();

  @override
  ConsumerState<_CustomerCreateDialog> createState() =>
      _CustomerCreateDialogState();
}

class _CustomerCreateDialogState extends ConsumerState<_CustomerCreateDialog> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _villageController = TextEditingController();
  final _addressController = TextEditingController();

  static const _countryDialCodes = <_CountryDialCode>[
    _CountryDialCode(isoCode: 'IN', name: 'India', dialCode: '+91'),
    // _CountryDialCode(isoCode: 'US', name: 'United States', dialCode: '+1'),
    // _CountryDialCode(isoCode: 'GB', name: 'United Kingdom', dialCode: '+44'),
    // _CountryDialCode(isoCode: 'AU', name: 'Australia', dialCode: '+61'),
    // _CountryDialCode(isoCode: 'AE', name: 'United Arab Emirates', dialCode: '+971'),
    // _CountryDialCode(isoCode: 'CA', name: 'Canada', dialCode: '+1'),
    // _CountryDialCode(isoCode: 'DE', name: 'Germany', dialCode: '+49'),
    // _CountryDialCode(isoCode: 'FR', name: 'France', dialCode: '+33'),
    // _CountryDialCode(isoCode: 'SG', name: 'Singapore', dialCode: '+65'),
    // _CountryDialCode(isoCode: 'SA', name: 'Saudi Arabia', dialCode: '+966'),
  ];

  @override
  void dispose() {
    _phoneController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _villageController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final createState = ref.watch(adminCreateCustomerControllerProvider);
    final devicesAsync = ref.watch(adminUnassignedDevicesProvider);
    final uiState = ref.watch(_customerFormUiProvider);
    final isLoading = createState.isLoading;

    return AlertDialog(
      backgroundColor: AppColors.lightBackground,
      title: const Text('Add Customer'),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 210,
                      child: DropdownButtonFormField<_CountryDialCode>(
                        initialValue: uiState.selectedCountry,
                        decoration: const InputDecoration(
                          labelText: 'Country',
                          filled: true,
                          fillColor: AppColors.white,
                          border: OutlineInputBorder(),
                        ),
                        items: _countryDialCodes
                            .map(
                              (country) => DropdownMenuItem<_CountryDialCode>(
                                value: country,
                                child: Text(
                                  '${country.name} (${country.dialCode})',
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: isLoading
                            ? null
                            : (value) => ref
                                  .read(_customerFormUiProvider.notifier)
                                  .setCountry(value ?? _countryDialCodes.first),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: AppTextField(
                        controller: _phoneController,
                        hintText: 'Mobile number',
                        labelText: 'Phone Number',
                        keyboardType: TextInputType.phone,
                        validator: _validateMobile,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _usernameController,
                  hintText: 'Enter username',
                  labelText: 'Username',
                  validator: (v) => _required(v, 'Username'),
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _passwordController,
                  hintText: 'Enter password',
                  labelText: 'Password',
                  obscureText: uiState.obscurePassword,
                  suffixIcon: IconButton(
                    tooltip: uiState.obscurePassword
                        ? 'Show password'
                        : 'Hide password',
                    onPressed: isLoading
                        ? null
                        : () => ref
                              .read(_customerFormUiProvider.notifier)
                              .togglePasswordVisibility(),
                    icon: Icon(
                      uiState.obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                  validator: (v) => _required(v, 'Password'),
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _fullNameController,
                  hintText: 'Enter full name',
                  labelText: 'Full Name',
                  validator: (v) => _required(v, 'Full name'),
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _emailController,
                  hintText: 'Enter email',
                  labelText: 'Email',
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    final requiredMsg = _required(v, 'Email');
                    if (requiredMsg != null) {
                      return requiredMsg;
                    }
                    return AppValidators.email(v);
                  },
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _villageController,
                  hintText: 'Enter village',
                  labelText: 'Village',
                  validator: (v) => _required(v, 'Village'),
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _addressController,
                  hintText: 'Enter address',
                  labelText: 'Address',
                  validator: (v) => _required(v, 'Address'),
                ),
                const SizedBox(height: 14),
                _devicePicker(devicesAsync, isLoading, uiState),
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
          onPressed: isLoading ? null : () => _submit(),
          child: isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.white,
                  ),
                )
              : const Text('Create'),
        ),
      ],
    );
  }

  Widget _devicePicker(
    AsyncValue<List<AdminUnassignedDevice>> devicesAsync,
    bool isLoading,
    _CustomerFormUiState uiState,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.lightGreyText),
      ),
      child: devicesAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primaryTeal,
            ),
          ),
        ),
        error: (error, _) => Column(
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

          final available = uniqueDevices.values
              .where((d) => !uiState.selectedDevices.any((s) => s.id == d.id))
              .toList();
          final canPick = available.isNotEmpty && !isLoading;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Assign Devices (optional)',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkText,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: canPick
                      ? () async {
                          final selected = await _openDeviceSearchDialog(
                            available,
                          );
                          if (selected == null) {
                            return;
                          }
                          ref
                              .read(_customerFormUiProvider.notifier)
                              .addDeviceFromPicker(selected);
                        }
                      : null,
                  icon: const Icon(Icons.search_rounded),
                  label: Text(
                    canPick
                        ? 'Search and select device (${available.length} available)'
                        : 'No unassigned devices available',
                  ),
                ),
              ),
              if (uiState.selectedDevices.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: uiState.selectedDevices
                      .map(
                        (d) => Chip(
                          label: Text('${d.displayName} (${d.id})'),
                          onDeleted: () => ref
                              .read(_customerFormUiProvider.notifier)
                              .removeDeviceById(d.id),
                        ),
                      )
                      .toList(),
                ),
              ],
              if (available.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'No unassigned devices available.',
                    style: TextStyle(color: AppColors.greyText),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _submit() async {
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) {
      return;
    }

    final uiState = ref.read(_customerFormUiProvider);
    final phone = _phoneController.text.trim();
    final request = AdminCustomerRequest(
      phoneNumber: '${uiState.selectedCountry.dialCode}$phone',
      username: _usernameController.text.trim(),
      password: _passwordController.text.trim(),
      fullName: _fullNameController.text.trim(),
      email: _emailController.text.trim(),
      village: _villageController.text.trim(),
      address: _addressController.text.trim(),
      espUnitIds: uiState.selectedDevices.map((d) => d.id).toList(),
    );

    try {
      await ref
          .read(adminCreateCustomerControllerProvider.notifier)
          .create(request);
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
          : 'Unable to create customer.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  String? _required(String? value, String label) {
    if ((value ?? '').trim().isEmpty) {
      return '$label is required';
    }
    return null;
  }

  String? _validateMobile(String? value) {
    final requiredResult = _required(value, 'Phone number');
    if (requiredResult != null) {
      return requiredResult;
    }

    final input = value!.trim();
    final phoneRegex = RegExp(r'^[0-9]{10,15}$');
    if (!phoneRegex.hasMatch(input)) {
      return 'Enter a valid mobile number';
    }
    return null;
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
                  onChanged: (value) => query.value = value.trim().toLowerCase(),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ValueListenableBuilder<String>(
                    valueListenable: query,
                    builder: (context, value, child) {
                      final filtered = devices.where((device) {
                        final haystack =
                            '${device.displayName} ${device.id}'.toLowerCase();
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
