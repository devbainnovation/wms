import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wms/core/core.dart';
import 'package:wms/user/features/dashboard/services/customer_devices_service.dart';

final customerDevicesServiceProvider = Provider<CustomerDevicesService>((ref) {
  return CustomerDevicesService();
});

final customerDevicesListProvider =
    FutureProvider.autoDispose<List<CustomerDeviceSummary>>((ref) async {
      final token = await _resolveToken(ref);
      if (token.isEmpty) {
        throw const ApiException('Session expired. Please login again.');
      }
      final service = ref.read(customerDevicesServiceProvider);
      return service.getDevices(bearerToken: token);
    });

Future<String> _resolveToken(Ref ref) async {
  final session = ref.read(currentAuthSessionProvider);
  var token = (session?.token ?? '').trim();
  if (token.isNotEmpty) {
    return token;
  }

  final remembered = await ref.read(authLocalStorageProvider).loadLoginData();
  token = (remembered?.token ?? '').trim();
  return token;
}
