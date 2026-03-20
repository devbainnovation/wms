import 'package:flutter/material.dart';
import 'package:wms/admin/features/devices/services/admin_device_service.dart';
import 'package:wms/shared/shared.dart';

class AdminDeviceTile extends StatelessWidget {
  const AdminDeviceTile({
    required this.item,
    required this.isMobile,
    required this.onOpenComponents,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final AdminDeviceSummary item;
  final bool isMobile;
  final VoidCallback onOpenComponents;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightGreyText),
      ),
      child: isMobile ? _mobileLayout() : _desktopLayout(),
    );
  }

  Widget _desktopLayout() {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Text(
            item.displayName,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.darkText,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            item.macAddress.isEmpty ? '-' : item.macAddress,
            style: const TextStyle(color: AppColors.darkText),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            item.fwVersion.isEmpty ? '-' : item.fwVersion,
            style: const TextStyle(color: AppColors.darkText),
          ),
        ),
        Expanded(
          flex: 2,
          child: Align(
            alignment: Alignment.centerLeft,
            child: AppStatusChip(
              label: item.isActive ? 'Active' : 'Inactive',
              active: item.isActive,
            ),
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            OutlinedButton.icon(
              onPressed: onOpenComponents,
              icon: const Icon(
                Icons.settings_input_component_rounded,
                size: 18,
                color: AppColors.primaryTeal,
              ),
              label: const Text('Add Component'),
            ),
            const SizedBox(width: 6),
            IconButton(
              tooltip: 'Edit',
              onPressed: onEdit,
              icon: const Icon(Icons.edit_rounded, color: AppColors.blue),
            ),
            IconButton(
              tooltip: 'Delete',
              onPressed: onDelete,
              icon: const Icon(Icons.delete_rounded, color: AppColors.red),
            ),
          ],
        ),
      ],
    );
  }

  Widget _mobileLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.displayName,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.darkText,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            AppMetaChip(
              label: 'MAC: ${item.macAddress.isEmpty ? '-' : item.macAddress}',
            ),
            AppMetaChip(
              label: 'FW: ${item.fwVersion.isEmpty ? '-' : item.fwVersion}',
            ),
            AppStatusChip(
              label: item.isActive ? 'Active' : 'Inactive',
              active: item.isActive,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            OutlinedButton.icon(
              onPressed: onOpenComponents,
              icon: const Icon(
                Icons.settings_input_component_rounded,
                size: 18,
                color: AppColors.primaryTeal,
              ),
              label: const Text('Add Component'),
            ),
            IconButton(
              tooltip: 'Edit',
              onPressed: onEdit,
              icon: const Icon(Icons.edit_rounded, color: AppColors.blue),
            ),
            IconButton(
              tooltip: 'Delete',
              onPressed: onDelete,
              icon: const Icon(Icons.delete_rounded, color: AppColors.red),
            ),
          ],
        ),
      ],
    );
  }
}
