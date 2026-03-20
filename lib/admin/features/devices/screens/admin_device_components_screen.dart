import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wms/admin/features/devices/providers/admin_device_components_providers.dart';
import 'package:wms/admin/features/devices/screens/admin_device_component_dialogs.dart';
import 'package:wms/admin/features/devices/screens/admin_device_component_tile.dart';
import 'package:wms/core/core.dart';
import 'package:wms/shared/shared.dart';

class AdminDeviceComponentsScreen extends ConsumerWidget {
  const AdminDeviceComponentsScreen({
    required this.deviceId,
    required this.deviceName,
    super.key,
  });

  final String deviceId;
  final String deviceName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final componentsAsync = ref.watch(adminDeviceComponentsProvider(deviceId));

    return Scaffold(
      backgroundColor: const Color(0xFFF7FBFC),
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0.5,
        title: Text('Components • $deviceName'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: AppSectionCard(
          width: double.infinity,
          radius: 16,
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                Row(
                  children: [
                    const Text(
                      'Components',
                      style: TextStyle(
                        fontSize: 24,
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
                          builder: (_) =>
                              AdminDeviceComponentUpsertDialog(
                                deviceId: deviceId,
                              ),
                        );

                        if (created != true || !context.mounted) {
                          return;
                        }

                        ref.invalidate(adminDeviceComponentsProvider(deviceId));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Component created successfully.'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Add Component'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              Expanded(
                child: componentsAsync.when(
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
                                : 'Unable to load components.',
                            style: const TextStyle(
                              color: AppColors.red,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () => ref.invalidate(
                              adminDeviceComponentsProvider(deviceId),
                            ),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                    data: (items) {
                      if (items.isEmpty) {
                        return const Center(
                          child: Text(
                            'No components found.',
                            style: TextStyle(
                              color: AppColors.greyText,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }

                      return ListView.separated(
                        itemCount: items.length,
                        separatorBuilder: (_, index) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return AdminDeviceComponentTile(
                            item: item,
                            onEdit: () async {
                              final updated = await showDialog<bool>(
                                context: context,
                                barrierDismissible: false,
                                builder: (_) => AdminDeviceComponentUpsertDialog(
                                  deviceId: deviceId,
                                  editItem: item,
                                ),
                              );

                              if (updated != true || !context.mounted) {
                                return;
                              }
                              ref.invalidate(
                                adminDeviceComponentsProvider(deviceId),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Component updated successfully.',
                                  ),
                                ),
                              );
                            },
                            onDelete: () async {
                              final deleted = await showDialog<bool>(
                                context: context,
                                builder: (_) => AdminDeleteComponentDialog(
                                  deviceId: deviceId,
                                  compId: item.id,
                                  name: item.name,
                                ),
                              );

                              if (deleted != true || !context.mounted) {
                                return;
                              }
                              ref.invalidate(
                                adminDeviceComponentsProvider(deviceId),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Component deleted successfully.',
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
