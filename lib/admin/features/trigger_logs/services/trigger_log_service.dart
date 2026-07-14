import 'package:wms/core/api/api.dart';
import 'package:wms/admin/features/trigger_logs/services/trigger_log_models.dart';
import 'package:wms/admin/features/devices/services/admin_device_component_service.dart';

class TriggerLogService {
  TriggerLogService({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<TriggerLogPageResult> getTriggerLogs({
    required String bearerToken,
    required TriggerLogQuery query,
  }) async {
    final params = <String, dynamic>{
      'page': query.page,
      'size': query.size,
    };

    if (query.espId != null && query.espId!.isNotEmpty) {
      params['espId'] = query.espId;
    }
    if (query.triggerType != null) {
      params['triggerType'] = query.triggerType!.value;
    }
    if (query.componentType != null) {
      params['componentType'] = _formatComponentType(query.componentType!);
    }
    if (query.actorId != null && query.actorId!.isNotEmpty) {
      params['actorId'] = query.actorId;
    }
    if (query.startTime != null) {
      params['startTime'] = query.startTime!.toIso8601String().split('.').first.replaceAll('Z', '');
    }
    if (query.endTime != null) {
      params['endTime'] = query.endTime!.toIso8601String().split('.').first.replaceAll('Z', '');
    }

    final response = await _apiClient.get(
      ApiEndpoints.adminTriggerLogs,
      bearerToken: bearerToken,
      queryParameters: params,
      showGlobalLoader: false,
    );

    if (!response.isSuccess) {
      throw ApiException(
        _extractMessage(response.data) ?? 'Unable to fetch trigger logs.',
        statusCode: response.statusCode,
      );
    }

    final data = response.data;
    if (data is! Map<String, dynamic>) {
      return TriggerLogPageResult(
        items: const [],
        page: query.page,
        size: query.size,
        totalPages: 1,
        totalElements: 0,
      );
    }

    final content = data['content'];
    final items = content is List
        ? content
            .whereType<Map<String, dynamic>>()
            .map(TriggerLog.fromJson)
            .toList()
        : const <TriggerLog>[];

    return TriggerLogPageResult(
      items: items,
      page: (data['number'] as num?)?.toInt() ?? query.page,
      size: (data['size'] as num?)?.toInt() ?? query.size,
      totalPages: (data['totalPages'] as num?)?.toInt() ?? 1,
      totalElements: (data['totalElements'] as num?)?.toInt() ?? items.length,
    );
  }

  String _formatComponentType(AdminComponentType type) {
    return switch (type) {
      AdminComponentType.motor => 'MOTOR',
      AdminComponentType.valve => 'VALVE',
      AdminComponentType.sensor => 'SENSOR',
    };
  }

  String? _extractMessage(dynamic body) {
    if (body is! Map<String, dynamic>) {
      return null;
    }
    final msg = body['message'] ?? body['error'] ?? body['detail'];
    if (msg == null) {
      return null;
    }
    final text = msg.toString().trim();
    return text.isEmpty ? null : text;
  }
}
