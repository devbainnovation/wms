import 'package:flutter/material.dart';
import 'package:wms/shared/shared.dart';
import 'package:wms/user/features/dashboard/services/user_admin_users_service.dart';

class UserAdminUserDetailsForm extends StatelessWidget {
  const UserAdminUserDetailsForm({
    required this.formKey,
    required this.user,
    required this.fullNameController,
    required this.emailController,
    required this.villageController,
    required this.addressLine1Controller,
    required this.addressLine2Controller,
    required this.talukaController,
    required this.districtController,
    required this.stateController,
    required this.pincodeController,
    required this.isSaving,
    required this.onSave,
    super.key,
  });

  final GlobalKey<FormState> formKey;
  final UserAdminUserSummary user;
  final TextEditingController fullNameController;
  final TextEditingController emailController;
  final TextEditingController villageController;
  final TextEditingController addressLine1Controller;
  final TextEditingController addressLine2Controller;
  final TextEditingController talukaController;
  final TextEditingController districtController;
  final TextEditingController stateController;
  final TextEditingController pincodeController;
  final bool isSaving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ReadOnlyField(label: 'Mobile Number', value: user.phoneNumber),
            const SizedBox(height: 10),
            _ReadOnlyField(label: 'Username', value: user.username),
            const SizedBox(height: 10),
            _ReadOnlyField(label: 'Role', value: user.role),
            const SizedBox(height: 10),
            AppTextField(
              controller: fullNameController,
              hintText: 'Enter full name',
              labelText: 'Full Name',
              validator: (v) => _required(v, 'Full name'),
            ),
            const SizedBox(height: 10),
            AppTextField(
              controller: emailController,
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
            const SizedBox(height: 10),
            AppTextField(
              controller: villageController,
              hintText: 'Enter village',
              labelText: 'Village',
            ),
            const SizedBox(height: 10),
            AppTextField(
              controller: addressLine1Controller,
              hintText: 'Enter address line 1',
              labelText: 'Address Line 1',
            ),
            const SizedBox(height: 10),
            AppTextField(
              controller: addressLine2Controller,
              hintText: 'Enter address line 2',
              labelText: 'Address Line 2',
            ),
            const SizedBox(height: 10),
            AppTextField(
              controller: talukaController,
              hintText: 'Enter taluka',
              labelText: 'Taluka',
            ),
            const SizedBox(height: 10),
            AppTextField(
              controller: districtController,
              hintText: 'Enter district',
              labelText: 'District',
            ),
            const SizedBox(height: 10),
            AppTextField(
              controller: stateController,
              hintText: 'Enter state',
              labelText: 'State',
            ),
            const SizedBox(height: 10),
            AppTextField(
              controller: pincodeController,
              hintText: 'Enter pincode',
              labelText: 'Pincode',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryTeal,
                  foregroundColor: AppColors.white,
                ),
                onPressed: isSaving ? null : onSave,
                child: isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.white,
                        ),
                      )
                    : const Text('Update User Details'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final text = value.trim().isEmpty ? '-' : value.trim();
    return AppSectionCard(
      width: double.infinity,
      radius: 12,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
            text,
            style: const TextStyle(
              color: AppColors.darkText,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

String? _required(String? value, String label) {
  if ((value ?? '').trim().isEmpty) {
    return '$label is required';
  }
  return null;
}
