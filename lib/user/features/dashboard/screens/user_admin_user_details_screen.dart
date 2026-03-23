import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wms/core/core.dart';
import 'package:wms/shared/shared.dart';
import 'package:wms/user/features/auth/screens/session_expiry_navigation.dart';
import 'package:wms/user/features/dashboard/providers/user_admin_users_providers.dart';
import 'package:wms/user/features/dashboard/screens/user_admin_user_details_form.dart';
import 'package:wms/user/features/dashboard/screens/user_admin_user_permissions_editor.dart';
import 'package:wms/user/features/dashboard/services/user_admin_users_service.dart';

final userPermissionsDraftProvider =
    NotifierProvider.autoDispose<
      _UserPermissionsDraftNotifier,
      _UserPermissionsDraftState
    >(_UserPermissionsDraftNotifier.new);

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

class UserAdminUserDetailsScreen extends ConsumerStatefulWidget {
  const UserAdminUserDetailsScreen({required this.seedUser, super.key});

  final UserAdminUserSummary seedUser;

  @override
  ConsumerState<UserAdminUserDetailsScreen> createState() =>
      _UserAdminUserDetailsScreenState();
}

class _UserAdminUserDetailsScreenState
    extends ConsumerState<UserAdminUserDetailsScreen> {
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
          .read(userPermissionsDraftProvider.notifier)
          .seed(widget.seedUser.permissions);
      final user = await ref.read(
        userAdminUserDetailsProvider(widget.seedUser.userId).future,
      );
      if (!mounted) {
        return;
      }
      _seedDetailsForm(user);
      ref
          .read(userPermissionsDraftProvider.notifier)
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
    final permissionsState = ref.watch(userPermissionsDraftProvider);
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
          error: (error, _) {
            final message = error is ApiException
                ? error.message
                : 'Unable to load user details.';
            final isSessionExpired = isSessionExpiredMessage(message);
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    message,
                    style: const TextStyle(
                      color: AppColors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => isSessionExpired
                        ? navigateToUserLogin(context)
                        : ref.invalidate(
                            userAdminUserDetailsProvider(widget.seedUser.userId),
                          ),
                    child: Text(isSessionExpired ? 'Login' : 'Retry'),
                  ),
                ],
              ),
            );
          },
          data: (_) => TabBarView(
            children: [
              UserAdminUserDetailsForm(
                formKey: _detailsFormKey,
                user: user,
                fullNameController: _fullNameController,
                emailController: _emailController,
                villageController: _villageController,
                addressLine1Controller: _addressLine1Controller,
                addressLine2Controller: _addressLine2Controller,
                talukaController: _talukaController,
                districtController: _districtController,
                stateController: _stateController,
                pincodeController: _pincodeController,
                isSaving: updateUserState.isLoading,
                onSave: () => _saveUserDetails(user.userId),
              ),
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

  Widget _permissionsTab(
    String userId,
    UserAdminUserPermissions permissions,
    bool isSaving,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          UserAdminUserPermissionsEditor(
            permissions: permissions,
            enabled: !isSaving,
            onChanged: _updatePermissions,
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
    );
  }

  void _updatePermissions(UserAdminUserPermissions permissions) {
    ref.read(userPermissionsDraftProvider.notifier).update(permissions);
  }

  Future<void> _savePermissions(String userId) async {
    final request = ref.read(userPermissionsDraftProvider).permissions;
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
}
