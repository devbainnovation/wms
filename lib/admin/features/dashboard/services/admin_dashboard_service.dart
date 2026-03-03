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
    final response = await _apiClient.get(
      ApiEndpoints.adminSystemDashboard,
      bearerToken: bearerToken,
      showGlobalLoader: false,
    );

    if (!response.isSuccess) {
      throw ApiException(
        'Unable to fetch dashboard summary.',
        statusCode: response.statusCode,
      );
    }

    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw const ApiException('Invalid dashboard summary response.');
    }

    return AdminDashboardSummary.fromJson(data);
  }
}
