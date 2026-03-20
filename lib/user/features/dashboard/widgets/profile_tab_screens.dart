import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wms/core/core.dart';
import 'package:wms/shared/shared.dart';
import 'package:wms/user/features/dashboard/providers/providers.dart';
import 'package:wms/user/features/dashboard/services/services.dart';
import 'package:wms/user/features/dashboard/widgets/profile_tab_sections.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({required this.profile, super.key});

  final UserProfile profile;

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
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
    final updateState = ref.watch(userProfileUpdateControllerProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7FAF9),
        foregroundColor: AppColors.darkText,
        elevation: 0,
        title: const Text('Edit Profile'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            SectionCard(
              title: 'Basic Info',
              child: Column(
                children: [
                  ReadOnlyInfoRow(
                    label: 'Phone Number',
                    value: widget.profile.phoneNumber,
                  ),
                  const SizedBox(height: 12),
                  ReadOnlyInfoRow(
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
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryTeal,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            onPressed: updateState.isLoading ? null : _submit,
            child: updateState.isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.white,
                    ),
                  )
                : const Text('Save Profile'),
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
          .read(userProfileUpdateControllerProvider.notifier)
          .update(request);
      ref.invalidate(userProfileProvider);
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

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
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
    final updateState = ref.watch(userPasswordUpdateControllerProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7FAF9),
        foregroundColor: AppColors.darkText,
        elevation: 0,
        title: const Text('Change Password'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFD9E5E0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Secure Your Account',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.darkText,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Use a strong password with letters, numbers and symbols.',
                    style: TextStyle(
                      color: AppColors.greyText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 18),
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
                      if (v!.trim() != _newPasswordController.text.trim()) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryTeal,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            onPressed: updateState.isLoading ? null : _submit,
            child: updateState.isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.white,
                    ),
                  )
                : const Text('Update Password'),
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
          .read(userPasswordUpdateControllerProvider.notifier)
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
