import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wms/admin/features/dashboard/services/services.dart';
import 'package:wms/core/core.dart';

final adminDashboardServiceProvider = Provider<AdminDashboardService>((ref) {
  return AdminDashboardService();
});

final adminDashboardSummaryProvider =
    FutureProvider.autoDispose<AdminDashboardSummary>((ref) async {
      final service = ref.read(adminDashboardServiceProvider);
      final token = await _resolveToken(ref);

      if (token.isEmpty) {
        throw const ApiException('Session expired. Please login again.');
      }

      return service.getSummary(bearerToken: token);
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
