import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wms/core/core.dart';
import 'package:wms/shared/shared.dart';
import 'package:wms/user/features/dashboard/providers/user_admin_users_providers.dart';
import 'package:wms/user/features/dashboard/screens/user_admin_user_permissions_editor.dart';
import 'package:wms/user/features/dashboard/services/user_admin_users_service.dart';

const userAdminCountryDialCodes = <UserAdminCountryDialCode>[
  UserAdminCountryDialCode(isoCode: 'IN', name: 'India', dialCode: '+91'),
];

final addUserFormUiProvider =
    NotifierProvider.autoDispose<AddUserFormUiNotifier, AddUserFormUiState>(
      AddUserFormUiNotifier.new,
    );

class AddUserFormUiState {
  const AddUserFormUiState({
    required this.selectedCountry,
    this.obscurePassword = true,
    this.permissions = const UserAdminUserPermissions(
      canViewDashboard: true,
      canControlValves: true,
      canCreateSchedules: true,
      canUpdateSchedules: true,
      canDeleteSchedules: true,
      canCreateTriggers: true,
      canManageNotifs: true,
    ),
  });

  final UserAdminCountryDialCode selectedCountry;
  final bool obscurePassword;
  final UserAdminUserPermissions permissions;

  AddUserFormUiState copyWith({
    UserAdminCountryDialCode? selectedCountry,
    bool? obscurePassword,
    UserAdminUserPermissions? permissions,
  }) {
    return AddUserFormUiState(
      selectedCountry: selectedCountry ?? this.selectedCountry,
      obscurePassword: obscurePassword ?? this.obscurePassword,
      permissions: permissions ?? this.permissions,
    );
  }
}

class AddUserFormUiNotifier extends Notifier<AddUserFormUiState> {
  @override
  AddUserFormUiState build() {
    return AddUserFormUiState(selectedCountry: userAdminCountryDialCodes.first);
  }

  void setCountry(UserAdminCountryDialCode country) {
    state = state.copyWith(selectedCountry: country);
  }

  void toggleObscurePassword() {
    state = state.copyWith(obscurePassword: !state.obscurePassword);
  }

  void updatePermissions(UserAdminUserPermissions permissions) {
    state = state.copyWith(permissions: permissions);
  }
}

class UserAdminDeleteUserDialog extends ConsumerWidget {
  const UserAdminDeleteUserDialog({required this.user, super.key});

  final UserAdminUserSummary user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(userAdminDeleteUserControllerProvider);

    return AlertDialog(
      title: const Text('Delete User'),
      content: Text(
        'Are you sure you want to delete "${user.fullName.isEmpty ? user.username : user.fullName}"?',
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
                        .read(userAdminDeleteUserControllerProvider.notifier)
                        .delete(user.userId);
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
                        : 'Unable to delete user.';
                    showAppSnackBar(
                      context,
                      message,
                      status: AppSnackBarStatus.error,
                    );
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

class UserAdminAddUserDialog extends ConsumerStatefulWidget {
  const UserAdminAddUserDialog({super.key});

  @override
  ConsumerState<UserAdminAddUserDialog> createState() =>
      _UserAdminAddUserDialogState();
}

class _UserAdminAddUserDialogState
    extends ConsumerState<UserAdminAddUserDialog> {
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
    final createState = ref.watch(userAdminCreateUserControllerProvider);
    final uiState = ref.watch(addUserFormUiProvider);
    final permissions = uiState.permissions;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.darkText,
        elevation: 0,
        title: const Text('Add User'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 180,
                      child: DropdownButtonFormField<UserAdminCountryDialCode>(
                        initialValue: uiState.selectedCountry,
                        decoration: InputDecoration(
                          labelText: 'Country',
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
                        items: userAdminCountryDialCodes
                            .map(
                              (country) =>
                                  DropdownMenuItem<UserAdminCountryDialCode>(
                                    value: country,
                                    child: Text(
                                      '${country.name} (${country.dialCode})',
                                    ),
                                  ),
                            )
                            .toList(),
                        onChanged: createState.isLoading
                            ? null
                            : (value) {
                                ref
                                    .read(addUserFormUiProvider.notifier)
                                    .setCountry(
                                      value ?? userAdminCountryDialCodes.first,
                                    );
                              },
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
                const SizedBox(height: 10),
                AppTextField(
                  controller: _usernameController,
                  hintText: 'Enter username',
                  labelText: 'Username',
                  validator: (v) => _required(v, 'Username'),
                ),
                const SizedBox(height: 10),
                AppTextField(
                  controller: _passwordController,
                  hintText: 'Enter password',
                  labelText: 'Password',
                  obscureText: uiState.obscurePassword,
                  suffixIcon: IconButton(
                    onPressed: createState.isLoading
                        ? null
                        : () {
                            ref
                                .read(addUserFormUiProvider.notifier)
                                .toggleObscurePassword();
                          },
                    icon: Icon(
                      uiState.obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                  validator: (v) => _required(v, 'Password'),
                ),
                const SizedBox(height: 10),
                AppTextField(
                  controller: _fullNameController,
                  hintText: 'Enter full name',
                  labelText: 'Full Name',
                  validator: (v) => _required(v, 'Full name'),
                ),
                const SizedBox(height: 10),
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
                const SizedBox(height: 10),
                AppTextField(
                  controller: _villageController,
                  hintText: 'Enter village',
                  labelText: 'Village',
                ),
                const SizedBox(height: 10),
                AppTextField(
                  controller: _addressLine1Controller,
                  hintText: 'Enter address line 1',
                  labelText: 'Address Line 1',
                ),
                const SizedBox(height: 10),
                AppTextField(
                  controller: _addressLine2Controller,
                  hintText: 'Enter address line 2',
                  labelText: 'Address Line 2',
                ),
                const SizedBox(height: 10),
                AppTextField(
                  controller: _talukaController,
                  hintText: 'Enter taluka',
                  labelText: 'Taluka',
                ),
                const SizedBox(height: 10),
                AppTextField(
                  controller: _districtController,
                  hintText: 'Enter district',
                  labelText: 'District',
                ),
                const SizedBox(height: 10),
                AppTextField(
                  controller: _stateController,
                  hintText: 'Enter state',
                  labelText: 'State',
                ),
                const SizedBox(height: 10),
                AppTextField(
                  controller: _pincodeController,
                  hintText: 'Enter pincode',
                  labelText: 'Pincode',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                UserAdminUserPermissionsEditor(
                  permissions: permissions,
                  onChanged: _updateDraftPermissions,
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
          child: Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: createState.isLoading
                      ? null
                      : () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryTeal,
                    foregroundColor: AppColors.white,
                  ),
                  onPressed: createState.isLoading ? null : _submit,
                  child: createState.isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.white,
                          ),
                        )
                      : const Text('Add User'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _updateDraftPermissions(UserAdminUserPermissions permissions) {
    ref.read(addUserFormUiProvider.notifier).updatePermissions(permissions);
  }

  Future<void> _submit() async {
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) {
      return;
    }

    final uiState = ref.read(addUserFormUiProvider);
    final phone = _phoneController.text.trim();
    final request = UserAdminUserCreateRequest(
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
      role: 'USER',
      permissions: uiState.permissions,
    );

    try {
      await ref
          .read(userAdminCreateUserControllerProvider.notifier)
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
          : 'Unable to add user.';
      showAppSnackBar(
        context,
        message,
        status: AppSnackBarStatus.error,
      );
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
    final phoneRegex = RegExp(r'^[0-9]{8,15}$');
    if (!phoneRegex.hasMatch(input)) {
      return 'Enter a valid mobile number';
    }
    return null;
  }
}

class UserAdminCountryDialCode {
  const UserAdminCountryDialCode({
    required this.isoCode,
    required this.name,
    required this.dialCode,
  });

  final String isoCode;
  final String name;
  final String dialCode;
}
