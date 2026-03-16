import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wms/core/core.dart';
import 'package:wms/user/features/dashboard/services/customer_devices_service.dart';

final customerDevicesServiceProvider = Provider<CustomerDevicesService>((ref) {
  return CustomerDevicesService();
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
