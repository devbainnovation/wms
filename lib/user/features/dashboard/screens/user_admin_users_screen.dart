import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wms/core/core.dart';
import 'package:wms/shared/shared.dart';
import 'package:wms/user/features/dashboard/providers/user_admin_users_providers.dart';
import 'package:wms/user/features/dashboard/services/user_admin_users_service.dart';

const _countryDialCodes = <_CountryDialCode>[
  _CountryDialCode(isoCode: 'IN', name: 'India', dialCode: '+91'),
];

final _userPermissionsDraftProvider =
    NotifierProvider.autoDispose<
      _UserPermissionsDraftNotifier,
      _UserPermissionsDraftState
    >(_UserPermissionsDraftNotifier.new);

final _addUserFormUiProvider =
    NotifierProvider.autoDispose<_AddUserFormUiNotifier, _AddUserFormUiState>(
      _AddUserFormUiNotifier.new,
    );

class _UserPermissionsDraftState {
  const _UserPermissionsDraftState({
    required this.permissions,
    this.isHydrated = false,
  });

  final UserAdminUserPermissions permissions;
  final bool isHydrated;

  _UserPermissionsDraftState copyWith({
    UserAdminUserPermissions? permissions,
    bool? isHydrated,
  }) {
    return _UserPermissionsDraftState(
      permissions: permissions ?? this.permissions,
      isHydrated: isHydrated ?? this.isHydrated,
    );
  }
}

class _UserPermissionsDraftNotifier
    extends Notifier<_UserPermissionsDraftState> {
  @override
  _UserPermissionsDraftState build() {
    return const _UserPermissionsDraftState(
      permissions: UserAdminUserPermissions(
        canViewDashboard: true,
        canControlValves: true,
        canCreateSchedules: true,
        canUpdateSchedules: true,
        canDeleteSchedules: true,
        canCreateTriggers: true,
        canManageNotifs: true,
      ),
    );
  }

  void seed(UserAdminUserPermissions permissions) {
    state = _UserPermissionsDraftState(permissions: permissions);
  }

  void hydrate(UserAdminUserPermissions permissions) {
    if (state.isHydrated) {
      return;
    }
    state = state.copyWith(permissions: permissions, isHydrated: true);
  }

  void update(UserAdminUserPermissions permissions) {
    state = state.copyWith(permissions: permissions, isHydrated: true);
  }
}

class _AddUserFormUiState {
  const _AddUserFormUiState({
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

  final _CountryDialCode selectedCountry;
  final bool obscurePassword;
  final UserAdminUserPermissions permissions;

  _AddUserFormUiState copyWith({
    _CountryDialCode? selectedCountry,
    bool? obscurePassword,
    UserAdminUserPermissions? permissions,
  }) {
    return _AddUserFormUiState(
      selectedCountry: selectedCountry ?? this.selectedCountry,
      obscurePassword: obscurePassword ?? this.obscurePassword,
      permissions: permissions ?? this.permissions,
    );
  }
}

class _AddUserFormUiNotifier extends Notifier<_AddUserFormUiState> {
  @override
  _AddUserFormUiState build() {
    return _AddUserFormUiState(selectedCountry: _countryDialCodes.first);
  }

  void setCountry(_CountryDialCode country) {
    state = state.copyWith(selectedCountry: country);
  }

  void toggleObscurePassword() {
    state = state.copyWith(obscurePassword: !state.obscurePassword);
  }

  void updatePermissions(UserAdminUserPermissions permissions) {
    state = state.copyWith(permissions: permissions);
  }
}

class UserAdminUsersScreen extends ConsumerWidget {
  const UserAdminUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(userAdminUsersListProvider);

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.darkText,
        elevation: 0,
        title: const Text('View Users'),
        actions: [
          IconButton(
            tooltip: 'Add User',
            icon: const Icon(Icons.person_add_alt_1_rounded),
            onPressed: () async {
              final created = await Navigator.of(context).push<bool>(
                MaterialPageRoute(builder: (_) => const _AddUserDialog()),
              );

              if (created == true) {
                ref.invalidate(userAdminUsersListProvider);
                if (!context.mounted) {
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('User added successfully.')),
                );
              }
            },
          ),
        ],
      ),
      body: usersAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primaryTeal),
        ),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                error is ApiException
                    ? error.message
                    : 'Unable to fetch users.',
                style: const TextStyle(
                  color: AppColors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref.invalidate(userAdminUsersListProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (users) {
          if (users.isEmpty) {
            return const Center(
              child: Text(
                'No users found.',
                style: TextStyle(
                  color: AppColors.greyText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(userAdminUsersListProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: users.length,
              separatorBuilder: (_, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final user = users[index];
                return _UserCard(user: user);
              },
            ),
          );
        },
      ),
    );
  }
}

class _UserCard extends ConsumerWidget {
  const _UserCard({required this.user});

  final UserAdminUserSummary user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => _UserDetailsScreen(seedUser: user)),
        ),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.lightGreyText),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      user.fullName.isEmpty ? user.username : user.fullName,
                      style: const TextStyle(
                        color: AppColors.darkText,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Delete User',
                    onPressed: () async {
                      final deleted = await showDialog<bool>(
                        context: context,
                        builder: (_) => _DeleteUserDialog(user: user),
                      );

                      if (deleted == true) {
                        ref.invalidate(userAdminUsersListProvider);
                        if (!context.mounted) {
                          return;
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('User deleted successfully.'),
                          ),
                        );
                      }
                    },
                    icon: const Icon(
                      Icons.delete_rounded,
                      color: AppColors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                user.phoneNumber.isEmpty ? '-' : user.phoneNumber,
                style: const TextStyle(
                  color: AppColors.greyText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UserDetailsScreen extends ConsumerStatefulWidget {
  const _UserDetailsScreen({required this.seedUser});

  final UserAdminUserSummary seedUser;

  @override
  ConsumerState<_UserDetailsScreen> createState() => _UserDetailsScreenState();
}

class _UserDetailsScreenState extends ConsumerState<_UserDetailsScreen> {
  final _detailsFormKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _villageController = TextEditingController();
  final _addressLine1Controller = TextEditingController();
  final _addressLine2Controller = TextEditingController();
  final _talukaController = TextEditingController();
  final _districtController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  bool _detailsHydrated = false;

  @override
  void initState() {
    super.initState();
    Future<void>(() async {
      _seedDetailsForm(widget.seedUser);
      ref
          .read(_userPermissionsDraftProvider.notifier)
          .seed(widget.seedUser.permissions);
      final user = await ref.read(
        userAdminUserDetailsProvider(widget.seedUser.userId).future,
      );
      if (!mounted) {
        return;
      }
      _seedDetailsForm(user);
      ref
          .read(_userPermissionsDraftProvider.notifier)
          .hydrate(user.permissions);
    });
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
    final detailsAsync = ref.watch(
      userAdminUserDetailsProvider(widget.seedUser.userId),
    );
    final updateUserState = ref.watch(userAdminUpdateUserControllerProvider);
    final updatePermissionsState = ref.watch(
      userAdminUpdatePermissionsControllerProvider,
    );
    final permissionsState = ref.watch(_userPermissionsDraftProvider);
    final user = detailsAsync.asData?.value ?? widget.seedUser;

    if (detailsAsync.hasValue && !_detailsHydrated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        _seedDetailsForm(detailsAsync.value!);
      });
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.white,
        appBar: AppBar(
          backgroundColor: AppColors.white,
          foregroundColor: AppColors.darkText,
          elevation: 0,
          title: const Text('User Details'),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(70),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F5F7),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.lightGreyText),
                ),
                child: TabBar(
                  padding: const EdgeInsets.all(4),
                  dividerColor: Colors.transparent,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x14000000),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  labelColor: AppColors.darkText,
                  unselectedLabelColor: AppColors.greyText,
                  labelStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  tabs: const [
                    Tab(text: 'User Details'),
                    Tab(text: 'Permissions'),
                  ],
                ),
              ),
            ),
          ),
        ),
        body: detailsAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primaryTeal),
          ),
          error: (error, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  error is ApiException
                      ? error.message
                      : 'Unable to load user details.',
                  style: const TextStyle(
                    color: AppColors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => ref.invalidate(
                    userAdminUserDetailsProvider(widget.seedUser.userId),
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
          data: (_) => TabBarView(
            children: [
              _detailsTab(user, updateUserState.isLoading),
              _permissionsTab(
                user.userId,
                permissionsState.permissions,
                updatePermissionsState.isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailsTab(UserAdminUserSummary user, bool isSaving) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Form(
        key: _detailsFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _readOnlyField('Mobile Number', user.phoneNumber),
            _readOnlyField('Username', user.username),
            _readOnlyField('Role', user.role),
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
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryTeal,
                  foregroundColor: AppColors.white,
                ),
                onPressed: isSaving
                    ? null
                    : () => _saveUserDetails(user.userId),
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

  Widget _permissionsTab(
    String userId,
    UserAdminUserPermissions permissions,
    bool isSaving,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.lightGreyText),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Permissions',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.darkText,
              ),
            ),
            const SizedBox(height: 8),
            _permissionTile(
              title: 'Can View Dashboard',
              value: permissions.canViewDashboard,
              enabled: !isSaving,
              onChanged: (v) => _updatePermissions(
                _copyPermissions(permissions, canViewDashboard: v ?? true),
              ),
            ),
            _permissionTile(
              title: 'Can Control Valves',
              value: permissions.canControlValves,
              enabled: !isSaving,
              onChanged: (v) => _updatePermissions(
                _copyPermissions(permissions, canControlValves: v ?? true),
              ),
            ),
            _permissionTile(
              title: 'Can Create Schedules',
              value: permissions.canCreateSchedules,
              enabled: !isSaving,
              onChanged: (v) => _updatePermissions(
                _copyPermissions(permissions, canCreateSchedules: v ?? true),
              ),
            ),
            _permissionTile(
              title: 'Can Update Schedules',
              value: permissions.canUpdateSchedules,
              enabled: !isSaving,
              onChanged: (v) => _updatePermissions(
                _copyPermissions(permissions, canUpdateSchedules: v ?? true),
              ),
            ),
            _permissionTile(
              title: 'Can Delete Schedules',
              value: permissions.canDeleteSchedules,
              enabled: !isSaving,
              onChanged: (v) => _updatePermissions(
                _copyPermissions(permissions, canDeleteSchedules: v ?? true),
              ),
            ),
            _permissionTile(
              title: 'Can Create Triggers',
              value: permissions.canCreateTriggers,
              enabled: !isSaving,
              onChanged: (v) => _updatePermissions(
                _copyPermissions(permissions, canCreateTriggers: v ?? true),
              ),
            ),
            _permissionTile(
              title: 'Can Manage Notifs',
              value: permissions.canManageNotifs,
              enabled: !isSaving,
              onChanged: (v) => _updatePermissions(
                _copyPermissions(permissions, canManageNotifs: v ?? true),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryTeal,
                  foregroundColor: AppColors.white,
                ),
                onPressed: isSaving ? null : () => _savePermissions(userId),
                child: isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.white,
                        ),
                      )
                    : const Text('Update Permissions'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _readOnlyField(String label, String value) {
    final text = value.trim().isEmpty ? '-' : value.trim();
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightGreyText),
      ),
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

  Widget _permissionTile({
    required String title,
    required bool value,
    required bool enabled,
    required ValueChanged<bool?> onChanged,
  }) {
    return CheckboxListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
      title: Text(title, style: const TextStyle(fontSize: 13)),
      value: value,
      onChanged: enabled ? onChanged : null,
      activeColor: AppColors.primaryTeal,
      checkColor: AppColors.white,
      controlAffinity: ListTileControlAffinity.leading,
    );
  }

  void _updatePermissions(UserAdminUserPermissions permissions) {
    ref.read(_userPermissionsDraftProvider.notifier).update(permissions);
  }

  Future<void> _savePermissions(String userId) async {
    final request = ref.read(_userPermissionsDraftProvider).permissions;
    try {
      await ref
          .read(userAdminUpdatePermissionsControllerProvider.notifier)
          .update(userId: userId, permissions: request);
      ref.invalidate(userAdminUsersListProvider);
      ref.invalidate(userAdminUserDetailsProvider(userId));
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permissions updated successfully.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      final message = error is ApiException
          ? error.message
          : 'Unable to update permissions.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _saveUserDetails(String userId) async {
    final valid = _detailsFormKey.currentState?.validate() ?? false;
    if (!valid) {
      return;
    }

    final request = UserAdminUserUpdateRequest(
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
          .read(userAdminUpdateUserControllerProvider.notifier)
          .update(userId: userId, request: request);
      ref.invalidate(userAdminUsersListProvider);
      ref.invalidate(userAdminUserDetailsProvider(userId));
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User details updated successfully.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      final message = error is ApiException
          ? error.message
          : 'Unable to update user details.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  void _seedDetailsForm(UserAdminUserSummary user) {
    _fullNameController.text = user.fullName;
    _emailController.text = user.email;
    _villageController.text = user.village;
    _addressLine1Controller.text = user.addressLine1;
    _addressLine2Controller.text = user.addressLine2;
    _talukaController.text = user.taluka;
    _districtController.text = user.district;
    _stateController.text = user.state;
    _pincodeController.text = user.pincode;
    _detailsHydrated = true;
  }

  String? _required(String? value, String label) {
    if ((value ?? '').trim().isEmpty) {
      return '$label is required';
    }
    return null;
  }
}

class _DeleteUserDialog extends ConsumerWidget {
  const _DeleteUserDialog({required this.user});

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
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(message)));
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

class _AddUserDialog extends ConsumerStatefulWidget {
  const _AddUserDialog();

  @override
  ConsumerState<_AddUserDialog> createState() => _AddUserDialogState();
}

class _AddUserDialogState extends ConsumerState<_AddUserDialog> {
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
    final uiState = ref.watch(_addUserFormUiProvider);
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
                      child: DropdownButtonFormField<_CountryDialCode>(
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
                        onChanged: createState.isLoading
                            ? null
                            : (value) {
                                ref
                                    .read(_addUserFormUiProvider.notifier)
                                    .setCountry(
                                      value ?? _countryDialCodes.first,
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
                                .read(_addUserFormUiProvider.notifier)
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
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.lightGreyText),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Permissions',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.darkText,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _permissionTile(
                        title: 'Can View Dashboard',
                        value: permissions.canViewDashboard,
                        onChanged: (v) => _updateDraftPermissions(
                          _copyPermissions(
                            permissions,
                            canViewDashboard: v ?? true,
                          ),
                        ),
                      ),
                      _permissionTile(
                        title: 'Can Control Valves',
                        value: permissions.canControlValves,
                        onChanged: (v) => _updateDraftPermissions(
                          _copyPermissions(
                            permissions,
                            canControlValves: v ?? true,
                          ),
                        ),
                      ),
                      _permissionTile(
                        title: 'Can Create Schedules',
                        value: permissions.canCreateSchedules,
                        onChanged: (v) => _updateDraftPermissions(
                          _copyPermissions(
                            permissions,
                            canCreateSchedules: v ?? true,
                          ),
                        ),
                      ),
                      _permissionTile(
                        title: 'Can Update Schedules',
                        value: permissions.canUpdateSchedules,
                        onChanged: (v) => _updateDraftPermissions(
                          _copyPermissions(
                            permissions,
                            canUpdateSchedules: v ?? true,
                          ),
                        ),
                      ),
                      _permissionTile(
                        title: 'Can Delete Schedules',
                        value: permissions.canDeleteSchedules,
                        onChanged: (v) => _updateDraftPermissions(
                          _copyPermissions(
                            permissions,
                            canDeleteSchedules: v ?? true,
                          ),
                        ),
                      ),
                      _permissionTile(
                        title: 'Can Create Triggers',
                        value: permissions.canCreateTriggers,
                        onChanged: (v) => _updateDraftPermissions(
                          _copyPermissions(
                            permissions,
                            canCreateTriggers: v ?? true,
                          ),
                        ),
                      ),
                      _permissionTile(
                        title: 'Can Manage Notifs',
                        value: permissions.canManageNotifs,
                        onChanged: (v) => _updateDraftPermissions(
                          _copyPermissions(
                            permissions,
                            canManageNotifs: v ?? true,
                          ),
                        ),
                      ),
                    ],
                  ),
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

  Widget _permissionTile({
    required String title,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return CheckboxListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
      title: Text(title, style: const TextStyle(fontSize: 13)),
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.primaryTeal,
      checkColor: AppColors.white,
      controlAffinity: ListTileControlAffinity.leading,
    );
  }

  void _updateDraftPermissions(UserAdminUserPermissions permissions) {
    ref.read(_addUserFormUiProvider.notifier).updatePermissions(permissions);
  }

  Future<void> _submit() async {
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) {
      return;
    }

    final uiState = ref.read(_addUserFormUiProvider);
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
    final phoneRegex = RegExp(r'^[0-9]{8,15}$');
    if (!phoneRegex.hasMatch(input)) {
      return 'Enter a valid mobile number';
    }
    return null;
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

UserAdminUserPermissions _copyPermissions(
  UserAdminUserPermissions value, {
  bool? canViewDashboard,
  bool? canControlValves,
  bool? canCreateSchedules,
  bool? canUpdateSchedules,
  bool? canDeleteSchedules,
  bool? canCreateTriggers,
  bool? canManageNotifs,
}) {
  return UserAdminUserPermissions(
    canViewDashboard: canViewDashboard ?? value.canViewDashboard,
    canControlValves: canControlValves ?? value.canControlValves,
    canCreateSchedules: canCreateSchedules ?? value.canCreateSchedules,
    canUpdateSchedules: canUpdateSchedules ?? value.canUpdateSchedules,
    canDeleteSchedules: canDeleteSchedules ?? value.canDeleteSchedules,
    canCreateTriggers: canCreateTriggers ?? value.canCreateTriggers,
    canManageNotifs: canManageNotifs ?? value.canManageNotifs,
  );
}
