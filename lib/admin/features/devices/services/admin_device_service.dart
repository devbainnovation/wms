import 'package:wms/core/api/api.dart';

class AdminDeviceRequest {
  const AdminDeviceRequest({
    required this.macAddress,
    required this.displayName,
    required this.fwVersion,
    required this.amcExpiry,
    required this.rechargeExpiry,
    required this.isActive,
  });

  final String macAddress;
  final String displayName;
  final String fwVersion;
  final DateTime amcExpiry;
  final DateTime rechargeExpiry;
  final bool isActive;

  Map<String, dynamic> toJson() {
    return {
      'macAddress': macAddress,
      'displayName': displayName,
      'fwVersion': fwVersion,
      'amcExpiry': _formatDate(amcExpiry),
      'rechargeExpiry': _formatDate(rechargeExpiry),
      'isActive': isActive,
    };
  }

  String _formatDate(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}

class AdminDeviceSummary {
  const AdminDeviceSummary({
    required this.id,
    required this.displayName,
    required this.macAddress,
    required this.fwVersion,
    required this.isActive,
    this.amcExpiry,
    this.rechargeExpiry,
  });

  final String id;
  final String displayName;
  final String macAddress;
  final String fwVersion;
  final bool isActive;
  final DateTime? amcExpiry;
  final DateTime? rechargeExpiry;

  factory AdminDeviceSummary.fromJson(Map<String, dynamic> json) {
    final id = (json['id'] ?? json['espId'] ?? json['deviceId'] ?? '')
        .toString();
    final displayName =
        (json['displayName'] ?? json['name'] ?? 'Unnamed Device').toString();
    final macAddress = (json['macAddress'] ?? '').toString();
    final fwVersion = (json['fwVersion'] ?? '').toString();
    final isActive = (json['isActive'] ?? json['active'] ?? true) == true;
    final amcExpiry = _tryParseDate(json['amcExpiry']);
    final rechargeExpiry = _tryParseDate(json['rechargeExpiry']);

    return AdminDeviceSummary(
      id: id,
      displayName: displayName,
      macAddress: macAddress,
      fwVersion: fwVersion,
      isActive: isActive,
      amcExpiry: amcExpiry,
      rechargeExpiry: rechargeExpiry,
    );
  }

  static DateTime? _tryParseDate(dynamic value) {
    if (value == null) {
      return null;
    }
    final raw = value.toString().trim();
    if (raw.isEmpty) {
      return null;
    }
    return DateTime.tryParse(raw);
  }
}

class AdminDevicePageResult {
  const AdminDevicePageResult({
    required this.items,
    required this.page,
    required this.size,
    required this.totalPages,
    required this.totalElements,
  });

  final List<AdminDeviceSummary> items;
  final int page;
  final int size;
  final int totalPages;
  final int totalElements;

  bool get hasPrevious => page > 0;
  bool get hasNext => page + 1 < totalPages;
}

class AdminDeviceService {
  AdminDeviceService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<AdminDevicePageResult> getDevices({
    required String bearerToken,
    required int page,
    int size = 20,
  }) async {
    final response = await _apiClient.get(
      ApiEndpoints.adminDevices,
      bearerToken: bearerToken,
      queryParameters: {'page': page, 'size': size},
      showGlobalLoader: false,
    );

    if (!response.isSuccess) {
      throw ApiException(
        'Unable to fetch devices.',
        statusCode: response.statusCode,
      );
    }

    final data = response.data;
    if (data is! Map<String, dynamic>) {
      return AdminDevicePageResult(
        items: const [],
        page: page,
        size: size,
        totalPages: 1,
        totalElements: 0,
      );
    }

    final content = data['content'];
    final items = content is List
        ? content
              .whereType<Map<String, dynamic>>()
              .map(AdminDeviceSummary.fromJson)
              .toList()
        : const <AdminDeviceSummary>[];

    final totalPages = (data['totalPages'] as num?)?.toInt() ?? 1;
    final totalElements =
        (data['totalElements'] as num?)?.toInt() ?? items.length;
    final currentPage = (data['number'] as num?)?.toInt() ?? page;
    final currentSize = (data['size'] as num?)?.toInt() ?? size;

    return AdminDevicePageResult(
      items: items,
      page: currentPage,
      size: currentSize,
      totalPages: totalPages < 1 ? 1 : totalPages,
      totalElements: totalElements,
    );
  }

  Future<void> registerDevice({
    required String bearerToken,
    required AdminDeviceRequest request,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.adminDevices,
      bearerToken: bearerToken,
      body: request.toJson(),
    );

    if (response.isSuccess) {
      return;
    }

    final body = response.data;
    if (body is Map<String, dynamic>) {
      final msg = body['message'] ?? body['error'] ?? body['detail'];
      if (msg != null && msg.toString().trim().isNotEmpty) {
        throw ApiException(msg.toString(), statusCode: response.statusCode);
      }
    }

    throw ApiException(
      'Device registration failed. Please try again.',
      statusCode: response.statusCode,
    );
  }

  Future<void> updateDevice({
    required String bearerToken,
    required String id,
    required AdminDeviceRequest request,
  }) async {
    final response = await _apiClient.put(
      ApiEndpoints.adminDeviceById(id),
      bearerToken: bearerToken,
      body: request.toJson(),
    );

    if (response.isSuccess) {
      return;
    }

    final body = response.data;
    if (body is Map<String, dynamic>) {
      final msg = body['message'] ?? body['error'] ?? body['detail'];
      if (msg != null && msg.toString().trim().isNotEmpty) {
        throw ApiException(msg.toString(), statusCode: response.statusCode);
      }
    }

    throw ApiException(
      'Device update failed. Please try again.',
      statusCode: response.statusCode,
    );
  }

  Future<void> deleteDevice({
    required String bearerToken,
    required String id,
  }) async {
    final response = await _apiClient.delete(
      ApiEndpoints.adminDeviceById(id),
      bearerToken: bearerToken,
    );

    if (response.isSuccess) {
      return;
    }

    final body = response.data;
    if (body is Map<String, dynamic>) {
      final msg = body['message'] ?? body['error'] ?? body['detail'];
      if (msg != null && msg.toString().trim().isNotEmpty) {
        throw ApiException(msg.toString(), statusCode: response.statusCode);
      }
    }

    throw ApiException(
      'Device delete failed. Please try again.',
      statusCode: response.statusCode,
    );
  }
}
