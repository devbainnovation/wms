part of 'admin_customers_screen.dart';

class _CustomerTile extends StatelessWidget {
  const _CustomerTile({
    required this.item,
    required this.isMobile,
    required this.onAssignDevice,
    required this.onEdit,
    required this.onDelete,
  });

  final AdminCustomerSummary item;
  final bool isMobile;
  final VoidCallback onAssignDevice;
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
          flex: 2,
          child: Text(
            item.fullName.isEmpty ? '-' : item.fullName,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.darkText,
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            item.username.isEmpty ? '-' : item.username,
            style: const TextStyle(color: AppColors.darkText),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            item.phoneNumber.isEmpty ? '-' : item.phoneNumber,
            style: const TextStyle(color: AppColors.darkText),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            item.email.isEmpty ? '-' : item.email,
            style: const TextStyle(color: AppColors.darkText),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            item.formattedAddress.isEmpty ? '-' : item.formattedAddress,
            style: const TextStyle(color: AppColors.darkText),
            softWrap: true,
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            item.espUnitIds.isEmpty ? '' : item.espUnitIds.join(', '),
            style: const TextStyle(color: AppColors.greyText),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: [
            IconButton(
              tooltip: 'Assign Device',
              onPressed: onAssignDevice,
              icon: const Icon(
                Icons.device_hub_rounded,
                color: AppColors.primaryTeal,
              ),
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

  Widget _mobileLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.fullName.isEmpty ? item.username : item.fullName,
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
            _metaChip('User: ${item.username.isEmpty ? '-' : item.username}'),
            _metaChip(
              'Phone: ${item.phoneNumber.isEmpty ? '-' : item.phoneNumber}',
            ),
            _metaChip(
              'Address: ${item.formattedAddress.isEmpty ? '-' : item.formattedAddress}',
            ),
            _metaChip(
              item.espUnitIds.isEmpty
                  ? 'Devices: None'
                  : 'Devices: ${item.espUnitIds.length}',
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            OutlinedButton.icon(
              onPressed: onAssignDevice,
              icon: const Icon(
                Icons.device_hub_rounded,
                size: 18,
                color: AppColors.primaryTeal,
              ),
              label: const Text('Assign Device'),
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

  Widget _metaChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.lightBackground,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.darkText,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
