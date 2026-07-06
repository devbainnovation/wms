import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wms/core/core.dart';
import 'package:wms/user/features/dashboard/services/customer_devices_service.dart';

final customerDevicesServiceProvider = Provider<CustomerDevicesService>((ref) {
  return CustomerDevicesService(apiClient: ref.watch(apiClientProvider));
});

final customerDevicesListProvider = FutureProvider<List<CustomerDeviceSummary>>(
  retry: (_, _) => null,
  (ref) async {
    ref.watch(currentAuthSessionProvider);
    final token = await _resolveToken(ref);
    if (token.isEmpty) {
      throw const ApiException('Session expired. Please login again.');
    }
    final service = ref.read(customerDevicesServiceProvider);
    return service.getDevices(bearerToken: token);
  },
);

final customerAssignedDevicesProvider =
    FutureProvider<List<CustomerDeviceSummary>>(
      retry: (_, _) => null,
      (ref) async {
        ref.watch(currentAuthSessionProvider);
        final token = await _resolveToken(ref);
        if (token.isEmpty) {
          throw const ApiException('Session expired. Please login again.');
        }
        final service = ref.read(customerDevicesServiceProvider);
        return service.getCustomerDevices(bearerToken: token);
      },
    );

final customerDashboardDevicesProvider =
    FutureProvider<List<CustomerDeviceSummary>>(
      retry: (_, _) => null,
      (ref) async {
        final assignedDevices = await ref.watch(customerAssignedDevicesProvider.future);
        final liveDevices = await ref.watch(customerDevicesListProvider.future);

        final assignedByEspId = <String, CustomerDeviceSummary>{
          for (final device in assignedDevices)
            if (device.espId.trim().isNotEmpty) device.espId.trim(): device,
        };

        final mergedLiveDevices = liveDevices.map((liveDevice) {
          final assigned = assignedByEspId[liveDevice.espId.trim()];
          if (assigned == null) {
            return liveDevice;
          }
          return assigned.mergeWith(liveDevice);
        }).toList();

        final liveEspIds = mergedLiveDevices
            .map((device) => device.espId.trim())
            .where((espId) => espId.isNotEmpty)
            .toSet();

        for (final assigned in assignedDevices) {
          final espId = assigned.espId.trim();
          if (espId.isEmpty || liveEspIds.contains(espId)) {
            continue;
          }
          mergedLiveDevices.add(assigned);
        }

        return mergedLiveDevices;
      },
    );

final customerManualTriggerControllerProvider =
    NotifierProvider<CustomerManualTriggerController, AsyncValue<void>>(
      CustomerManualTriggerController.new,
    );

class CustomerManualTriggerController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData<void>(null);

  Future<ApiResponse> trigger({
    required String componentId,
    required String action,
    int? duration,
  }) async {
    state = const AsyncLoading<void>();
    try {
      final token = await _resolveToken(ref);
      if (!ref.mounted) {
        throw const ApiException('Manual trigger request was cancelled.');
      }
      if (token.isEmpty) {
        throw const ApiException('Session expired. Please login again.');
      }
      final service = ref.read(customerDevicesServiceProvider);
      final response = await service.triggerManualAction(
        bearerToken: token,
        componentId: componentId,
        action: action,
        duration: duration,
      );
      if (!ref.mounted) {
        throw const ApiException('Manual trigger request was cancelled.');
      }
      state = const AsyncData<void>(null);
      return response;
    } catch (error, stackTrace) {
      if (ref.mounted) {
        state = AsyncError<void>(error, stackTrace);
      }
      rethrow;
    }
  }
}

Future<String> _resolveToken(Ref ref) async {
  final session = ref.read(currentAuthSessionProvider);
  return (session?.token ?? '').trim();
}
