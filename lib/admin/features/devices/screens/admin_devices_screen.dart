import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wms/admin/features/devices/screens/admin_device_components_screen.dart';
import 'package:wms/admin/features/devices/screens/admin_device_dialogs.dart';
import 'package:wms/admin/features/devices/screens/admin_device_tile.dart';
import 'package:wms/admin/features/devices/providers/admin_devices_providers.dart';
import 'package:wms/core/core.dart';
import 'package:wms/shared/shared.dart';

class AdminDevicesScreen extends ConsumerWidget {
  const AdminDevicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devicesAsync = ref.watch(adminDevicesListProvider);
    final showUnassignedOnly = ref.watch(
      adminDevicesShowUnassignedOnlyProvider,
    );
    final isMobile = MediaQuery.sizeOf(context).width < 900;
    final screenTitle = showUnassignedOnly ? 'Unassigned Devices' : 'Devices';

    return Padding(
      padding: EdgeInsets.all(isMobile ? 12 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          isMobile
              ? Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      screenTitle,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppColors.darkText,
                      ),
                    ),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primaryTeal,
                        foregroundColor: AppColors.white,
                      ),
                      onPressed: () async {
                        final created = await showDialog<bool>(
                          context: context,
                          barrierDismissible: false,
                          builder: (_) => const AdminDeviceUpsertDialog(),
                        );

                        if (!context.mounted || created != true) {
                          return;
                        }

                        ref.invalidate(adminDevicesListProvider);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Device registered successfully.'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Add Devices'),
                    ),
                  ],
                )
              : Row(
                  children: [
                    Text(
                      screenTitle,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppColors.darkText,
                      ),
                    ),
                    const Spacer(),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primaryTeal,
                        foregroundColor: AppColors.white,
                      ),
                      onPressed: () async {
                        final created = await showDialog<bool>(
                          context: context,
                          barrierDismissible: false,
                          builder: (_) => const AdminDeviceUpsertDialog(),
                        );

                        if (!context.mounted || created != true) {
                          return;
                        }

                        ref.invalidate(adminDevicesListProvider);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Device registered successfully.'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Add Devices'),
                    ),
                  ],
                ),
          SizedBox(height: isMobile ? 12 : 18),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.lightGreyText),
              ),
              child: devicesAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryTeal,
                  ),
                ),
                error: (error, _) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        error is ApiException
                            ? error.message
                            : 'Unable to load devices',
                        style: const TextStyle(
                          color: AppColors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () =>
                            ref.invalidate(adminDevicesListProvider),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
                data: (result) {
                  if (result.items.isEmpty) {
                    return const Center(
                      child: Text(
                        'No devices found.',
                        style: TextStyle(
                          color: AppColors.greyText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: [
                      Expanded(
                        child: ListView.separated(
                          padding: EdgeInsets.all(isMobile ? 10 : 16),
                          itemCount: result.items.length,
                          separatorBuilder: (_, index) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final item = result.items[index];
                            return AdminDeviceTile(
                              item: item,
                              isMobile: isMobile,
                              onOpenComponents: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => AdminDeviceComponentsScreen(
                                      deviceId: item.id,
                                      deviceName: item.displayName,
                                    ),
                                  ),
                                );
                              },
                              onEdit: () async {
                                final updated = await showDialog<bool>(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (_) =>
                                      AdminDeviceUpsertDialog(editItem: item),
                                );
                                if (updated == true) {
                                  ref.invalidate(adminDevicesListProvider);
                                  if (!context.mounted) {
                                    return;
                                  }
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Device updated successfully.',
                                      ),
                                    ),
                                  );
                                }
                              },
                              onDelete: () async {
                                final deleted = await showDialog<bool>(
                                  context: context,
                                  builder: (_) => AdminDeleteDeviceDialog(
                                    id: item.id,
                                    name: item.displayName,
                                  ),
                                );
                                if (deleted == true) {
                                  ref.invalidate(adminDevicesListProvider);
                                  if (!context.mounted) {
                                    return;
                                  }
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Device deleted successfully.',
                                      ),
                                    ),
                                  );
                                }
                              },
                            );
                          },
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
                        child: isMobile
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Page ${result.page + 1} of ${result.totalPages} • Total ${result.totalElements}',
                                    style: const TextStyle(
                                      color: AppColors.greyText,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      OutlinedButton(
                                        onPressed: result.hasPrevious
                                            ? () {
                                                ref
                                                    .read(
                                                      adminDevicesPageProvider
                                                          .notifier,
                                                    )
                                                    .previous();
                                              }
                                            : null,
                                        child: const Text('Previous'),
                                      ),
                                      const SizedBox(width: 8),
                                      FilledButton(
                                        onPressed: result.hasNext
                                            ? () {
                                                ref
                                                    .read(
                                                      adminDevicesPageProvider
                                                          .notifier,
                                                    )
                                                    .next();
                                              }
                                            : null,
                                        child: const Text('Next'),
                                      ),
                                    ],
                                  ),
                                ],
                              )
                            : Row(
                                children: [
                                  Text(
                                    'Page ${result.page + 1} of ${result.totalPages} • Total ${result.totalElements}',
                                    style: const TextStyle(
                                      color: AppColors.greyText,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const Spacer(),
                                  OutlinedButton(
                                    onPressed: result.hasPrevious
                                        ? () {
                                            ref
                                                .read(
                                                  adminDevicesPageProvider
                                                      .notifier,
                                                )
                                                .previous();
                                          }
                                        : null,
                                    child: const Text('Previous'),
                                  ),
                                  const SizedBox(width: 8),
                                  FilledButton(
                                    onPressed: result.hasNext
                                        ? () {
                                            ref
                                                .read(
                                                  adminDevicesPageProvider
                                                      .notifier,
                                                )
                                                .next();
                                          }
                                        : null,
                                    child: const Text('Next'),
                                  ),
                                ],
                              ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
