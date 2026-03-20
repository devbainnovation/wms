import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wms/admin/features/dashboard/providers/providers.dart';
import 'package:wms/admin/features/dashboard/widgets/admin_profile_sections.dart';
import 'package:wms/core/core.dart';
import 'package:wms/shared/shared.dart';
import 'package:wms/user/features/dashboard/services/user_profile_service.dart';

class EditProfileDialog extends ConsumerStatefulWidget {
  const EditProfileDialog({required this.profile, super.key});

  final UserProfile profile;

  @override
  ConsumerState<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends ConsumerState<EditProfileDialog> {
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
    _fullNameController.text = widget.profile.fullName;
    _emailController.text = widget.profile.email;
    _villageController.text = widget.profile.village;
    _addressLine1Controller.text = widget.profile.addressLine1;
    _addressLine2Controller.text = widget.profile.addressLine2;
    _talukaController.text = widget.profile.taluka;
    _districtController.text = widget.profile.district;
    _stateController.text = widget.profile.state;
    _pincodeController.text = widget.profile.pincode;
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
    final updateState = ref.watch(adminProfileUpdateControllerProvider);
    final width = MediaQuery.sizeOf(context).width;

    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: width < 760 ? 560 : 760),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Update Profile',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.darkText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Keep your admin account details up to date.',
                    style: TextStyle(
                      color: AppColors.greyText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SectionCard(
                    title: 'Basic Info',
                    child: Column(
                      children: [
                        StaticValueField(
                          label: 'Phone Number',
                          value: widget.profile.phoneNumber,
                        ),
                        const SizedBox(height: 12),
                        StaticValueField(
                          label: 'Username',
                          value: widget.profile.username,
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
                            final msg = _required(v, 'Email');
                            if (msg != null) {
                              return msg;
                            }
                            return AppValidators.email(v);
                          },
                        ),
                        const SizedBox(height: 12),
                        AppTextField(
                          controller: _villageController,
                          hintText: 'Enter village',
                          labelText: 'Village',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SectionCard(
                    title: 'Address',
                    child: Column(
                      children: [
                        AppTextField(
                          controller: _addressLine1Controller,
                          hintText: 'Enter address line 1',
                          labelText: 'Address Line 1',
                        ),
                        const SizedBox(height: 12),
                        AppTextField(
                          controller: _addressLine2Controller,
                          hintText: 'Enter address line 2',
                          labelText: 'Address Line 2',
                        ),
                        const SizedBox(height: 12),
                        AppTextField(
                          controller: _talukaController,
                          hintText: 'Enter taluka',
                          labelText: 'Taluka',
                        ),
                        const SizedBox(height: 12),
                        AppTextField(
                          controller: _districtController,
                          hintText: 'Enter district',
                          labelText: 'District',
                        ),
                        const SizedBox(height: 12),
                        AppTextField(
                          controller: _stateController,
                          hintText: 'Enter state',
                          labelText: 'State',
                        ),
                        const SizedBox(height: 12),
                        AppTextField(
                          controller: _pincodeController,
                          hintText: 'Enter pincode',
                          labelText: 'Pincode',
                          keyboardType: TextInputType.number,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: updateState.isLoading
                              ? null
                              : () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppButton(
                          text: 'Save Profile',
                          isLoading: updateState.isLoading,
                          onPressed: _submit,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) {
      return;
    }

    final request = UserProfileUpdateRequest(
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
          .read(adminProfileUpdateControllerProvider.notifier)
          .update(request);
      ref.invalidate(adminProfileProvider);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully.')),
      );
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) {
        return;
      }
      final message = error is ApiException
          ? error.message
          : 'Unable to update profile.';
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

class ChangePasswordDialog extends ConsumerStatefulWidget {
  const ChangePasswordDialog({super.key});

  @override
  ConsumerState<ChangePasswordDialog> createState() =>
      _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends ConsumerState<ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final updateState = ref.watch(adminPasswordUpdateControllerProvider);

    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Change Password',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.darkText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Use a strong password with letters, numbers and symbols.',
                    style: TextStyle(
                      color: AppColors.greyText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SectionCard(
                    title: 'Security',
                    child: Column(
                      children: [
                        AppTextField(
                          controller: _currentPasswordController,
                          hintText: 'Enter current password',
                          labelText: 'Current Password',
                          obscureText: true,
                          validator: (v) => _required(v, 'Current password'),
                        ),
                        const SizedBox(height: 12),
                        AppTextField(
                          controller: _newPasswordController,
                          hintText: 'Enter new password',
                          labelText: 'New Password',
                          obscureText: true,
                          validator: AppValidators.password,
                        ),
                        const SizedBox(height: 12),
                        AppTextField(
                          controller: _confirmPasswordController,
                          hintText: 'Confirm new password',
                          labelText: 'Confirm Password',
                          obscureText: true,
                          validator: (v) {
                            final msg = _required(v, 'Confirm password');
                            if (msg != null) {
                              return msg;
                            }
                            if (v!.trim() !=
                                _newPasswordController.text.trim()) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: updateState.isLoading
                              ? null
                              : () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppButton(
                          text: 'Update Password',
                          isLoading: updateState.isLoading,
                          onPressed: _submit,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) {
      return;
    }

    final request = UserProfilePasswordUpdateRequest(
      currentPassword: _currentPasswordController.text.trim(),
      newPassword: _newPasswordController.text.trim(),
    );

    try {
      await ref
          .read(adminPasswordUpdateControllerProvider.notifier)
          .update(request);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated successfully.')),
      );
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) {
        return;
      }
      final message = error is ApiException
          ? error.message
          : 'Unable to update password.';
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
