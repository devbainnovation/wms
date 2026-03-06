part of 'admin_customers_screen.dart';

class _EditCustomerDialog extends ConsumerStatefulWidget {
  const _EditCustomerDialog({required this.customer});

  final AdminCustomerSummary customer;

  @override
  ConsumerState<_EditCustomerDialog> createState() =>
      _EditCustomerDialogState();
}

class _EditCustomerDialogState extends ConsumerState<_EditCustomerDialog> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _villageController = TextEditingController();
  final _addressLine1Controller = TextEditingController();
  final _addressLine2Controller = TextEditingController();
  final _talukaController = TextEditingController();
  final _districtController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final item = widget.customer;
    _fullNameController.text = item.fullName;
    _emailController.text = item.email;
    _villageController.text = item.village;
    _addressLine1Controller.text = item.addressLine1;
    _addressLine2Controller.text = item.addressLine2;
    _talukaController.text = item.taluka;
    _districtController.text = item.district;
    _stateController.text = item.state;
    _pincodeController.text = item.pincode;
  }

  @override
  void dispose() {
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
    final state = ref.watch(adminUpdateCustomerControllerProvider);

    return AlertDialog(
      backgroundColor: AppColors.lightBackground,
      title: const Text('Edit Customer'),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: state.isLoading
              ? null
              : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primaryTeal,
            foregroundColor: AppColors.white,
          ),
          onPressed: state.isLoading ? null : _submit,
          child: state.isLoading
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

    final request = AdminCustomerUpdateRequest(
      fullName: _fullNameController.text.trim(),
      email: _emailController.text.trim(),
      village: _villageController.text.trim(),
      addressLine1: _addressLine1Controller.text.trim(),
      addressLine2: _addressLine2Controller.text.trim(),
      taluka: _talukaController.text.trim(),
      district: _districtController.text.trim(),
      state: _stateController.text.trim(),
      pincode: _pincodeController.text.trim(),
    );

    try {
      await ref
          .read(adminUpdateCustomerControllerProvider.notifier)
          .update(customerId: widget.customer.id, request: request);
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
          : 'Unable to update customer.';
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
}
