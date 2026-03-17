import 'package:wms/core/api/api.dart';

class AdminDashboardSummary {
  const AdminDashboardSummary({
    required this.totalDevices,
    required this.totalActiveDevices,
    required this.totalInactiveDevices,
    required this.totalUnassignedDevices,
    required this.totalCustomers,
    required this.totalActiveCustomers,
    required this.totalInactiveCustomers,
    required this.totalUnassignedCustomers,
  });

  final int totalDevices;
  final int totalActiveDevices;
  final int totalInactiveDevices;
  final int totalUnassignedDevices;
  final int totalCustomers;
  final int totalActiveCustomers;
  final int totalInactiveCustomers;
  final int totalUnassignedCustomers;

  AdminDashboardSummary copyWith({
    int? totalDevices,
    int? totalActiveDevices,
    int? totalInactiveDevices,
    int? totalUnassignedDevices,
    int? totalCustomers,
    int? totalActiveCustomers,
    int? totalInactiveCustomers,
    int? totalUnassignedCustomers,
  }) {
    return AdminDashboardSummary(
      totalDevices: totalDevices ?? this.totalDevices,
      totalActiveDevices: totalActiveDevices ?? this.totalActiveDevices,
      totalInactiveDevices: totalInactiveDevices ?? this.totalInactiveDevices,
      totalUnassignedDevices:
          totalUnassignedDevices ?? this.totalUnassignedDevices,
      totalCustomers: totalCustomers ?? this.totalCustomers,
      totalActiveCustomers: totalActiveCustomers ?? this.totalActiveCustomers,
      totalInactiveCustomers:
          totalInactiveCustomers ?? this.totalInactiveCustomers,
      totalUnassignedCustomers:
          totalUnassignedCustomers ?? this.totalUnassignedCustomers,
    );
  }

  factory AdminDashboardSummary.fromJson(Map<String, dynamic> json) {
    int asInt(String key) => (json[key] as num?)?.toInt() ?? 0;

    return AdminDashboardSummary(
      totalDevices: asInt('totalDevices'),
      totalActiveDevices: asInt('totalActiveDevices'),
      totalInactiveDevices: asInt('totalInactiveDevices'),
      totalUnassignedDevices: asInt('totalUnassignedDevices'),
      totalCustomers: asInt('totalCustomers'),
      totalActiveCustomers: asInt('totalActiveCustomers'),
      totalInactiveCustomers: asInt('totalInactiveCustomers'),
      totalUnassignedCustomers: asInt('totalUnassignedCustomers'),
    );
  }
}

class AdminDashboardService {
  AdminDashboardService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<AdminDashboardSummary> getSummary({
    required String bearerToken,
  }) async {
    final responses = await Future.wait([
      _apiClient.get(
        ApiEndpoints.adminSystemDashboard,
        bearerToken: bearerToken,
        showGlobalLoader: false,
      ),
      _apiClient.get(
        ApiEndpoints.adminUnassignedDevices,
        bearerToken: bearerToken,
        showGlobalLoader: false,
      ),
    ]);

    final summaryResponse = responses[0];
    if (!summaryResponse.isSuccess) {
      throw ApiException(
        'Unable to fetch dashboard summary.',
        statusCode: summaryResponse.statusCode,
      );
    }

    final data = summaryResponse.data;
    if (data is! Map<String, dynamic>) {
      throw const ApiException('Invalid dashboard summary response.');
    }

    final unassignedResponse = responses[1];
    var totalUnassignedDevices = 0;
    if (unassignedResponse.isSuccess) {
      final unassignedData = unassignedResponse.data;
      if (unassignedData is List) {
        totalUnassignedDevices = unassignedData.length;
      } else if (unassignedData is Map<String, dynamic>) {
        final content =
            unassignedData['content'] ??
            unassignedData['items'] ??
            unassignedData['data'];
        if (content is List) {
          totalUnassignedDevices = content.length;
        }
      }
    }

    return AdminDashboardSummary.fromJson(
      data,
    ).copyWith(totalUnassignedDevices: totalUnassignedDevices);
  }
}
