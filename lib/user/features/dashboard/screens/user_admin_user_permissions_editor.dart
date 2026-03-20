import 'package:flutter/material.dart';
import 'package:wms/shared/shared.dart';
import 'package:wms/user/features/dashboard/services/user_admin_users_service.dart';

class UserAdminUserPermissionsEditor extends StatelessWidget {
  const UserAdminUserPermissionsEditor({
    required this.permissions,
    required this.onChanged,
    this.enabled = true,
    super.key,
  });

  final UserAdminUserPermissions permissions;
  final bool enabled;
  final ValueChanged<UserAdminUserPermissions> onChanged;

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      padding: const EdgeInsets.all(10),
      radius: 12,
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
          _PermissionTile(
            title: 'Can View Dashboard',
            value: permissions.canViewDashboard,
            enabled: enabled,
            onChanged: (v) => onChanged(
              copyUserAdminPermissions(
                permissions,
                canViewDashboard: v ?? true,
              ),
            ),
          ),
          _PermissionTile(
            title: 'Can Control Valves',
            value: permissions.canControlValves,
            enabled: enabled,
            onChanged: (v) => onChanged(
              copyUserAdminPermissions(
                permissions,
                canControlValves: v ?? true,
              ),
            ),
          ),
          _PermissionTile(
            title: 'Can Create Schedules',
            value: permissions.canCreateSchedules,
            enabled: enabled,
            onChanged: (v) => onChanged(
              copyUserAdminPermissions(
                permissions,
                canCreateSchedules: v ?? true,
              ),
            ),
          ),
          _PermissionTile(
            title: 'Can Update Schedules',
            value: permissions.canUpdateSchedules,
            enabled: enabled,
            onChanged: (v) => onChanged(
              copyUserAdminPermissions(
                permissions,
                canUpdateSchedules: v ?? true,
              ),
            ),
          ),
          _PermissionTile(
            title: 'Can Delete Schedules',
            value: permissions.canDeleteSchedules,
            enabled: enabled,
            onChanged: (v) => onChanged(
              copyUserAdminPermissions(
                permissions,
                canDeleteSchedules: v ?? true,
              ),
            ),
          ),
          _PermissionTile(
            title: 'Can Create Triggers',
            value: permissions.canCreateTriggers,
            enabled: enabled,
            onChanged: (v) => onChanged(
              copyUserAdminPermissions(
                permissions,
                canCreateTriggers: v ?? true,
              ),
            ),
          ),
          _PermissionTile(
            title: 'Can Manage Notifs',
            value: permissions.canManageNotifs,
            enabled: enabled,
            onChanged: (v) => onChanged(
              copyUserAdminPermissions(
                permissions,
                canManageNotifs: v ?? true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PermissionTile extends StatelessWidget {
  const _PermissionTile({
    required this.title,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final String title;
  final bool value;
  final bool enabled;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
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
}

UserAdminUserPermissions copyUserAdminPermissions(
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
