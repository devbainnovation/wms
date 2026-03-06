part of 'admin_customers_screen.dart';

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
  final _addressLine1Controller = TextEditingController();
  final _addressLine2Controller = TextEditingController();
  final _talukaController = TextEditingController();
  final _districtController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();

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
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _talukaController.dispose();
    _districtController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
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
                  controller: _addressLine1Controller,
                  hintText: 'Enter address line 1',
                  labelText: 'Address Line 1',
                  validator: (v) => _required(v, 'Address line 1'),
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _addressLine2Controller,
                  hintText: 'Enter address line 2',
                  labelText: 'Address Line 2 (optional)',
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _talukaController,
                  hintText: 'Enter taluka',
                  labelText: 'Taluka (optional)',
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _districtController,
                  hintText: 'Enter district',
                  labelText: 'District',
                  validator: (v) => _required(v, 'District'),
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _stateController,
                  hintText: 'Enter state',
                  labelText: 'State',
                  validator: (v) => _required(v, 'State'),
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _pincodeController,
                  hintText: 'Enter pincode',
                  labelText: 'Pincode',
                  keyboardType: TextInputType.number,
                  validator: (v) => _required(v, 'Pincode'),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.lightGreyText),
                  ),
                  child: Row(
                    children: [
                      Text(
                        uiState.isActive ? 'Active' : 'Deactive',
                        style: TextStyle(
                          color: uiState.isActive
                              ? AppColors.accentGreen
                              : AppColors.red,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Switch(
                        value: uiState.isActive,
                        activeThumbColor: AppColors.accentGreen,
                        onChanged: isLoading
                            ? null
                            : (value) => ref
                                  .read(_customerFormUiProvider.notifier)
                                  .setActive(value),
                      ),
                    ],
                  ),
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
      addressLine1: _addressLine1Controller.text.trim(),
      addressLine2: _addressLine2Controller.text.trim(),
      taluka: _talukaController.text.trim(),
      district: _districtController.text.trim(),
      state: _stateController.text.trim(),
      pincode: _pincodeController.text.trim(),
      espUnitIds: uiState.selectedDevices
          .map((d) => d.id.trim())
          .where((id) => id.isNotEmpty)
          .toList(),
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
