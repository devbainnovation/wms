import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wms/admin/features/dashboard/services/services.dart';
import 'package:wms/core/core.dart';

final adminDashboardServiceProvider = Provider<AdminDashboardService>((ref) {
  return AdminDashboardService(apiClient: ref.watch(apiClientProvider));
});

final adminDashboardSummaryProvider =
    FutureProvider.autoDispose<AdminDashboardSummary>((ref) async {
      final service = ref.read(adminDashboardServiceProvider);
      final token = await resolveAuthToken(ref);

      if (token.isEmpty) {
        throw const ApiException('Session expired. Please login again.');
      }

      return service.getSummary(bearerToken: token);
    });

