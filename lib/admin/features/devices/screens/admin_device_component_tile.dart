import 'package:flutter/material.dart';
import 'package:wms/admin/features/devices/services/admin_device_component_service.dart';
import 'package:wms/shared/shared.dart';

class AdminDeviceComponentTile extends StatelessWidget {
  const AdminDeviceComponentTile({
    required this.item,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final AdminDeviceComponent item;
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name.isEmpty ? '-' : item.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkText,
                  ),
                ),
                if (item.installedArea.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      item.installedArea,
                      style: const TextStyle(
                        color: AppColors.greyText,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              item.type.label,
              style: const TextStyle(color: AppColors.darkText),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'GPIO ${item.gpioPin}',
              style: const TextStyle(color: AppColors.darkText),
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: AppStatusChip(
                label: item.active ? 'Active' : 'Inactive',
                active: item.active,
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'Edit',
                onPressed: onEdit,
                icon: const Icon(
                  Icons.edit_rounded,
                  color: AppColors.blue,
                ),
              ),
              IconButton(
                tooltip: 'Delete',
                onPressed: onDelete,
                icon: const Icon(
                  Icons.delete_rounded,
                  color: AppColors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
