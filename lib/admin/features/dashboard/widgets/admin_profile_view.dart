import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wms/admin/features/dashboard/providers/providers.dart';
import 'package:wms/core/core.dart';
import 'package:wms/shared/shared.dart';
import 'package:wms/user/features/dashboard/services/user_profile_service.dart';

class AdminProfileView extends ConsumerWidget {
  const AdminProfileView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(adminProfileProvider);

    return profileAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primaryTeal),
      ),
      error: (error, _) => _ProfileErrorView(
        message: error is ApiException
            ? error.message
            : 'Unable to load profile.',
        onRetry: () => ref.invalidate(adminProfileProvider),
      ),
      data: (profile) => RefreshIndicator(
        color: AppColors.primaryTeal,
        onRefresh: () async => ref.invalidate(adminProfileProvider),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _ProfileHeroCard(profile: profile),
            const SizedBox(height: 18),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _InfoCard(
                  width: 240,
                  icon: Icons.call_rounded,
                  title: 'Phone Number',
                  value: profile.phoneNumber,
                ),
                _InfoCard(
                  width: 240,
                  icon: Icons.account_circle_rounded,
                  title: 'Username',
                  value: profile.username,
                ),
                _InfoCard(
                  width: 240,
                  icon: Icons.location_on_rounded,
                  title: 'Village',
                  value: profile.village,
                ),
                _InfoCard(
                  width: 240,
                  icon: Icons.calendar_today_rounded,
                  title: 'Created',
                  value: profile.createdAt == null
                      ? '-'
                      : AppDateTimeFormatter.formatDateTime(profile.createdAt!),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Account Actions',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.darkText,
              ),
            ),
            const SizedBox(height: 12),
            _ActionTile(
              icon: Icons.edit_rounded,
              iconColor: AppColors.primaryTeal,
              title: 'Update Profile',
              subtitle: 'Edit name, email, village, and address details',
              onTap: () => showDialog<void>(
                context: context,
                builder: (_) => _EditProfileDialog(profile: profile),
              ),
            ),
            const SizedBox(height: 12),
            _ActionTile(
              icon: Icons.lock_rounded,
              iconColor: const Color(0xFF2C6BED),
              title: 'Change Password',
              subtitle: 'Update your password for this admin account',
              onTap: () => showDialog<void>(
                context: context,
                builder: (_) => const _ChangePasswordDialog(),
              ),
            ),
            const SizedBox(height: 24),
            _AddressSection(profile: profile),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeroCard extends StatelessWidget {
  const _ProfileHeroCard({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final displayName = profile.fullName.isEmpty
        ? profile.username
        : profile.fullName;
    final initials = _initials(displayName);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF4FBF8), Color(0xFFE7F5EF)],
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFD8E9E1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(22),
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryTeal,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Admin Profile',
                  style: TextStyle(
                    color: AppColors.greyText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  displayName.isEmpty ? 'Admin User' : displayName,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.darkText,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  profile.email.isEmpty ? profile.phoneNumber : profile.email,
                  style: const TextStyle(
                    color: AppColors.greyText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _HeroChip(
                      icon: Icons.badge_rounded,
                      label: profile.role.isEmpty ? 'ADMIN' : profile.role,
                    ),
                    _HeroChip(
                      icon: profile.active
                          ? Icons.verified_user_rounded
                          : Icons.pause_circle_rounded,
                      label: profile.active ? 'Active' : 'Inactive',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _initials(String value) {
    final parts = value
        .split(' ')
        .where((part) => part.trim().isNotEmpty)
        .take(2)
        .toList();
    if (parts.isEmpty) {
      return 'A';
    }
    return parts.map((part) => part.trim()[0].toUpperCase()).join();
  }
}

class _AddressSection extends StatelessWidget {
  const _AddressSection({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Address Details',
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          _ReadOnlyInfoRow(
            label: 'Address Line 1',
            value: profile.addressLine1,
          ),
          _ReadOnlyInfoRow(
            label: 'Address Line 2',
            value: profile.addressLine2,
          ),
          _ReadOnlyInfoRow(label: 'Taluka', value: profile.taluka),
          _ReadOnlyInfoRow(label: 'District', value: profile.district),
          _ReadOnlyInfoRow(label: 'State', value: profile.state),
          _ReadOnlyInfoRow(label: 'Pincode', value: profile.pincode),
        ],
      ),
    );
  }
}

class _EditProfileDialog extends ConsumerStatefulWidget {
  const _EditProfileDialog({required this.profile});

  final UserProfile profile;

  @override
  ConsumerState<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends ConsumerState<_EditProfileDialog> {
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
                  _SectionCard(
                    title: 'Basic Info',
                    child: Column(
                      children: [
                        _StaticValueField(
                          label: 'Phone Number',
                          value: widget.profile.phoneNumber,
                        ),
                        const SizedBox(height: 12),
                        _StaticValueField(
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
                  _SectionCard(
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

class _ChangePasswordDialog extends ConsumerStatefulWidget {
  const _ChangePasswordDialog();

  @override
  ConsumerState<_ChangePasswordDialog> createState() =>
      _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends ConsumerState<_ChangePasswordDialog> {
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
                  _SectionCard(
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

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.width,
    required this.icon,
    required this.title,
    required this.value,
  });

  final double width;
  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFDCE7E2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFE9F7F1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: AppColors.primaryTeal),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.greyText,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value.trim().isEmpty ? '-' : value.trim(),
              style: const TextStyle(
                color: AppColors.darkText,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFDCE7E2)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: iconColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.darkText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.greyText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: AppColors.greyText,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF6F0),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFD2E8DE)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.primaryTeal),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.primaryTeal,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFDCE7E2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.darkText,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _ReadOnlyInfoRow extends StatelessWidget {
  const _ReadOnlyInfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF6FAF8),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppColors.greyText,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value.trim().isEmpty ? '-' : value.trim(),
              style: const TextStyle(
                color: AppColors.darkText,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StaticValueField extends StatelessWidget {
  const _StaticValueField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF6FAF8),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.greyText,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value.trim().isEmpty ? '-' : value.trim(),
            style: const TextStyle(
              color: AppColors.darkText,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileErrorView extends StatelessWidget {
  const _ProfileErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.person_off_rounded,
              size: 52,
              color: AppColors.red,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.darkText,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
