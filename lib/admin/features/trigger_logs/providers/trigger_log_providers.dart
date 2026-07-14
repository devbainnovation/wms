import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wms/admin/features/trigger_logs/services/trigger_log_service.dart';
import 'package:wms/admin/features/trigger_logs/services/trigger_log_models.dart';
import 'package:wms/core/core.dart';
import 'package:wms/routing/routing.dart';

import '../../devices/services/admin_device_component_service.dart';

final triggerLogServiceProvider = Provider<TriggerLogService>((ref) {
  return TriggerLogService(apiClient: ref.watch(apiClientProvider));
});

final triggerLogQueryProvider =
    NotifierProvider<TriggerLogQueryNotifier, TriggerLogQuery>(
      TriggerLogQueryNotifier.new,
    );

class TriggerLogQueryNotifier extends Notifier<TriggerLogQuery> {
  @override
  TriggerLogQuery build() {
    final route = ref.watch(appRouteProvider);
    if (route.section != AppRouteSection.triggerLogs) {
      return const TriggerLogQuery();
    }

    final params = route.queryParameters;
    return TriggerLogQuery(
      page: int.tryParse(params['page'] ?? '') ?? 0,
      size: int.tryParse(params['size'] ?? '') ?? 20,
      espId: params['espId'],
      triggerType: TriggerType.fromString(params['triggerType']),
      componentType: _parseComponentType(params['componentType']),
      actorId: params['actorId'],
      startTime: params['startTime'] != null ? DateTime.tryParse(params['startTime']!) : null,
      endTime: params['endTime'] != null ? DateTime.tryParse(params['endTime']!) : null,
    );
  }

  static AdminComponentType? _parseComponentType(String? value) {
    if (value == null) return null;
    return AdminComponentType.values.firstWhere(
      (e) => e.name.toUpperCase() == value.toUpperCase(),
      orElse: () => AdminComponentType.motor,
    );
  }

  void next() {
    state = state.copyWith(page: state.page + 1);
    _syncRoute();
  }

  void previous() {
    state = state.copyWith(page: state.page > 0 ? state.page - 1 : 0);
    _syncRoute();
  }

  void updateQuery(TriggerLogQuery newQuery) {
    state = newQuery;
    _syncRoute();
  }

  void resetFilters() {
    state = const TriggerLogQuery();
    _syncRoute();
  }

  void _syncRoute() {
    final queryParameters = <String, String>{};
    if (state.page > 0) queryParameters['page'] = state.page.toString();
    if (state.size != 20) queryParameters['size'] = state.size.toString();
    if (state.espId != null && state.espId!.isNotEmpty) queryParameters['espId'] = state.espId!;
    if (state.triggerType != null) queryParameters['triggerType'] = state.triggerType!.value;
    if (state.componentType != null) {
      queryParameters['componentType'] = state.componentType!.name.toUpperCase();
    }
    if (state.actorId != null && state.actorId!.isNotEmpty) queryParameters['actorId'] = state.actorId!;
    if (state.startTime != null) queryParameters['startTime'] = state.startTime!.toIso8601String();
    if (state.endTime != null) queryParameters['endTime'] = state.endTime!.toIso8601String();

    ref.read(appRouteProvider.notifier).goToSection(
      AppRouteSection.triggerLogs,
      queryParameters: queryParameters,
    );
  }
}

final triggerLogListProvider =
    FutureProvider.autoDispose<TriggerLogPageResult>((ref) async {
      final service = ref.read(triggerLogServiceProvider);
      final query = ref.watch(triggerLogQueryProvider);
      
      final session = ref.read(currentAuthSessionProvider);
      final token = (session?.token ?? '').trim();

      if (token.isEmpty) {
        throw const ApiException('Session expired. Please login again.');
      }

      return service.getTriggerLogs(
        bearerToken: token,
        query: query,
      );
    });
