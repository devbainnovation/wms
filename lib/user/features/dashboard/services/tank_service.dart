import 'package:wms/core/api/api.dart';

class TankData {
  const TankData({
    required this.id,
    required this.espId,
    required this.espDisplayName,
    required this.installedArea,
    required this.currentLevel,
    required this.updatedAt,
  });

  final String id;
  final String espId;
  final String espDisplayName;
  final String installedArea;
  final double currentLevel;
  final DateTime updatedAt;

  double get levelPercent => (currentLevel.clamp(0, 100)) / 100;

  factory TankData.fromJson(Map<String, dynamic> json) {
    String read(List<String> keys) {
      for (final key in keys) {
        final raw = json[key];
        if (raw == null) {
          continue;
        }
        final value = raw.toString().trim();
        if (value.isNotEmpty && value.toLowerCase() != 'null') {
          return value;
        }
      }
      return '';
    }

    double readDouble(List<String> keys) {
      for (final key in keys) {
        final raw = json[key];
        if (raw is num) {
          return raw.toDouble();
        }
        if (raw is String) {
          final value = double.tryParse(raw.trim());
          if (value != null) {
            return value;
          }
        }
      }
      return 0;
    }

    DateTime readDateTime(List<String> keys) {
      for (final key in keys) {
        final raw = json[key];
        if (raw == null) {
          continue;
        }
        final parsed = DateTime.tryParse(raw.toString().trim());
        if (parsed != null) {
          return parsed;
        }
      }
      return DateTime.fromMillisecondsSinceEpoch(0);
    }

    final espId = read(const ['espId']);
    final componentId = read(const ['componentId', 'id']);

    return TankData(
      id: componentId.isNotEmpty ? componentId : espId,
      espId: espId,
      espDisplayName: read(const ['espDisplayName', 'displayName', 'name']),
      installedArea: read(const ['installedArea']),
      currentLevel: readDouble(const ['currentLevel', 'level']),
      updatedAt: readDateTime(const ['lastUpdatedAt', 'updatedAt']),
    );
  }
}

class TankService {
  TankService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<TankData>> getTanks({required String bearerToken}) async {
    final response = await _apiClient.get(
      ApiEndpoints.appTankLevels,
      bearerToken: bearerToken,
      showGlobalLoader: false,
    );

    if (!response.isSuccess) {
      throw ApiException(
        _extractMessage(response.data) ?? 'Unable to fetch tank levels.',
        statusCode: response.statusCode,
      );
    }

    final data = response.data;
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(TankData.fromJson)
          .toList();
    }

    if (data is Map<String, dynamic>) {
      final content = data['content'] ?? data['items'] ?? data['data'];
      if (content is List) {
        return content
            .whereType<Map<String, dynamic>>()
            .map(TankData.fromJson)
            .toList();
      }
    }

    return const <TankData>[];
  }

  String? _extractMessage(dynamic body) {
    if (body is! Map<String, dynamic>) {
      return null;
    }
    final rawMessage =
        body['message'] ??
        body['error'] ??
        body['detail'] ??
        body['errorMessage'];
    if (rawMessage == null) {
      return null;
    }
    final message = rawMessage.toString().trim();
    return message.isEmpty ? null : message;
  }
}
