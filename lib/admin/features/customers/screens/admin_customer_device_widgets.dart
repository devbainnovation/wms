import 'package:flutter/material.dart';
import 'package:wms/admin/features/customers/services/admin_customer_service.dart';
import 'package:wms/shared/shared.dart';

class CustomerDeviceHeader extends StatelessWidget {
  const CustomerDeviceHeader({
    required this.customer,
    required this.isMobile,
    super.key,
  });

  final AdminCustomerSummary customer;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.lightBackground,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _headline(),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: _summaryChips()),
        ],
      ),
    );
  }

  Widget _headline() {
    return Text(
      customer.fullName.trim().isEmpty ? customer.username : customer.fullName,
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: AppColors.darkText,
      ),
    );
  }

  List<Widget> _summaryChips() {
    return [
      InfoChip(
        icon: Icons.person_outline_rounded,
        label: 'Username',
        value: orDash(customer.username),
      ),
      InfoChip(
        icon: Icons.phone_outlined,
        label: 'Phone',
        value: orDash(customer.phoneNumber),
      ),
      InfoChip(
        icon: Icons.email_outlined,
        label: 'Email',
        value: orDash(customer.email),
      ),
      InfoChip(
        icon: Icons.location_on_outlined,
        label: 'Address',
        value: orDash(customer.formattedAddress),
      ),
    ];
  }
}

class AssignedDeviceCard extends StatelessWidget {
  const AssignedDeviceCard({
    required this.item,
    required this.isMobile,
    required this.isUnassigning,
    required this.expanded,
    required this.onToggleComponents,
    required this.onUnassign,
    required this.onEditComponent,
    required this.onOpenSchedules,
    super.key,
  });

  final AdminCustomerAssignedDevice item;
  final bool isMobile;
  final bool isUnassigning;
  final bool expanded;
  final VoidCallback onToggleComponents;
  final VoidCallback onUnassign;
  final ValueChanged<AdminCustomerDeviceComponent> onEditComponent;
  final ValueChanged<AdminCustomerDeviceComponent> onOpenSchedules;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.lightGreyText),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isMobile) _mobileHeader() else _desktopHeader(),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              InfoChip(
                icon: Icons.memory_rounded,
                label: 'ESP ID',
                value: orDash(item.espId),
              ),
              InfoChip(
                icon: Icons.badge_outlined,
                label: 'MAC',
                value: orDash(item.macAddress),
              ),
              InfoChip(
                icon: Icons.update_rounded,
                label: 'FW Version',
                value: orDash(item.fwVersion),
              ),
              InfoChip(
                icon: Icons.calendar_today_outlined,
                label: 'Created',
                value: formatDate(item.createdAt),
              ),
              InfoChip(
                icon: Icons.favorite_outline_rounded,
                label: 'Last Heartbeat',
                value: formatDate(item.lastHeartbeat),
              ),
              InfoChip(
                icon: Icons.verified_outlined,
                label: 'AMC Expiry',
                value: formatDate(item.amcExpiry),
              ),
              InfoChip(
                icon: Icons.currency_rupee_rounded,
                label: 'Recharge Expiry',
                value: formatDate(item.rechargeExpiry),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Text(
                '${item.components.length} component${item.components.length == 1 ? '' : 's'}',
                style: const TextStyle(
                  color: AppColors.greyText,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: onToggleComponents,
                icon: Icon(
                  expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                ),
                label: Text(
                  expanded ? 'Hide components' : 'View all components',
                ),
              ),
            ],
          ),
          if (expanded) ...[
            const Divider(height: 18),
            if (item.components.isEmpty)
              const Text(
                'No components available.',
                style: TextStyle(
                  color: AppColors.greyText,
                  fontWeight: FontWeight.w600,
                ),
              )
            else
              Column(
                children: item.components
                    .map(
                      (component) => ComponentTile(
                        component: component,
                        onEdit: () => onEditComponent(component),
                        onOpenSchedules: onOpenSchedules,
                      ),
                    )
                    .toList(),
              ),
          ],
        ],
      ),
    );
  }

  Widget _desktopHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                orDash(item.displayName),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkText,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.espId.trim().isEmpty ? 'Unnamed device' : item.espId,
                style: const TextStyle(color: AppColors.greyText),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.end,
          children: [
            _statusBadge(
              label: item.active ? 'Active' : 'Inactive',
              active: item.active,
            ),
            _statusBadge(
              label: item.online ? 'Online' : 'Offline',
              active: item.online,
            ),
            _unassignBadge(),
          ],
        ),
      ],
    );
  }

  Widget _mobileHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          orDash(item.displayName),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.darkText,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          item.espId.trim().isEmpty ? 'Unnamed device' : item.espId,
          style: const TextStyle(color: AppColors.greyText),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _statusBadge(
              label: item.active ? 'Active' : 'Inactive',
              active: item.active,
            ),
            _statusBadge(
              label: item.online ? 'Online' : 'Offline',
              active: item.online,
            ),
            _unassignBadge(),
          ],
        ),
      ],
    );
  }

  Widget _statusBadge({required String label, required bool active}) {
    return AppStatusChip(
      label: label,
      active: active,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    );
  }

  Widget _unassignBadge() {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: isUnassigning ? null : onUnassign,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.red.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
        ),
        child: isUnassigning
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.red,
                ),
              )
            : const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.link_off_rounded, size: 14, color: AppColors.red),
                  SizedBox(width: 6),
                  Text(
                    'Unassign Device',
                    style: TextStyle(
                      color: AppColors.red,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class ComponentTile extends StatelessWidget {
  const ComponentTile({
    required this.component,
    required this.onEdit,
    required this.onOpenSchedules,
    super.key,
  });

  final AdminCustomerDeviceComponent component;
  final VoidCallback onEdit;
  final ValueChanged<AdminCustomerDeviceComponent> onOpenSchedules;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.lightBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                orDash(component.name),
                style: const TextStyle(
                  color: AppColors.darkText,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Edit Component',
                onPressed: onEdit,
                icon: const Icon(Icons.edit_rounded, color: AppColors.blue),
              ),
              IconButton(
                tooltip: 'Schedules',
                onPressed: () => onOpenSchedules(component),
                icon: const Icon(
                  Icons.schedule_rounded,
                  color: AppColors.primaryTeal,
                ),
              ),
            ],
          ),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              InfoChip(
                icon: Icons.precision_manufacturing_outlined,
                label: 'Name',
                value: orDash(component.name),
              ),
              InfoChip(
                icon: Icons.category_outlined,
                label: 'Type',
                value: orDash(component.type),
              ),
              InfoChip(
                icon: Icons.settings_input_component_outlined,
                label: 'GPIO',
                value: '${component.gpioPin}',
              ),
              InfoChip(
                icon: Icons.power_settings_new_rounded,
                label: 'State',
                value: orDash(component.currentState),
              ),
              InfoChip(
                icon: Icons.toggle_on_outlined,
                label: 'Status',
                value: component.active ? 'Active' : 'Inactive',
              ),
              InfoChip(
                icon: Icons.schedule_rounded,
                label: 'Changed At',
                value: formatDate(component.stateChangedAt),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class PaginationBar extends StatelessWidget {
  const PaginationBar({
    required this.isMobile,
    required this.page,
    required this.totalPages,
    required this.totalElements,
    required this.hasPrevious,
    required this.hasNext,
    required this.onPrevious,
    required this.onNext,
    super.key,
  });

  final bool isMobile;
  final int page;
  final int totalPages;
  final int totalElements;
  final bool hasPrevious;
  final bool hasNext;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final summary = 'Page ${page + 1} of $totalPages • Total $totalElements';
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            summary,
            style: const TextStyle(
              color: AppColors.greyText,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              OutlinedButton(
                onPressed: hasPrevious ? onPrevious : null,
                child: const Text('Previous'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: hasNext ? onNext : null,
                child: const Text('Next'),
              ),
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        Text(
          summary,
          style: const TextStyle(
            color: AppColors.greyText,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        OutlinedButton(
          onPressed: hasPrevious ? onPrevious : null,
          child: const Text('Previous'),
        ),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: hasNext ? onNext : null,
          child: const Text('Next'),
        ),
      ],
    );
  }
}

class InfoChip extends StatelessWidget {
  const InfoChip({
    required this.icon,
    required this.label,
    required this.value,
    super.key,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 180),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.lightBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.primaryTeal),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
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
                  value,
                  style: const TextStyle(
                    color: AppColors.darkText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String formatDate(DateTime? value) {
  if (value == null) {
    return '-';
  }
  return AppDateTimeFormatter.formatDateTime(value);
}

String orDash(String value) {
  final normalized = value.trim();
  return normalized.isEmpty ? '-' : normalized;
}
