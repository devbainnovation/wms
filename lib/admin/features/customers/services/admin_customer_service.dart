import 'package:wms/core/api/api.dart';
import 'package:wms/admin/features/customers/services/admin_customer_models.dart';

export 'admin_customer_models.dart';

class AdminCustomerService {
  AdminCustomerService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<AdminCustomerPageResult> getCustomers({
    required String bearerToken,
    required int page,
    int size = 10,
    String search = '',
  }) async {
    final params = <String, dynamic>{'page': page, 'size': size};
    final normalizedSearch = search.trim();
    if (normalizedSearch.isNotEmpty) {
      params['search'] = normalizedSearch;
    }

    final response = await _apiClient.get(
      ApiEndpoints.adminCustomers,
      bearerToken: bearerToken,
      queryParameters: params,
      showGlobalLoader: false,
    );

    if (!response.isSuccess) {
      throw ApiException(
        _extractMessage(response.data) ?? 'Unable to fetch customers.',
        statusCode: response.statusCode,
      );
    }

    final data = response.data;
    if (data is! Map<String, dynamic>) {
      return AdminCustomerPageResult(
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
              .map(AdminCustomerSummary.fromJson)
              .toList()
        : const <AdminCustomerSummary>[];

    final totalPages = (data['totalPages'] as num?)?.toInt() ?? 1;
    final totalElements =
        (data['totalElements'] as num?)?.toInt() ?? items.length;
    final currentPage = (data['number'] as num?)?.toInt() ?? page;
    final currentSize = (data['size'] as num?)?.toInt() ?? size;

    return AdminCustomerPageResult(
      items: items,
      page: currentPage,
      size: currentSize,
      totalPages: totalPages < 1 ? 1 : totalPages,
      totalElements: totalElements,
    );
  }

  Future<List<AdminUnassignedDevice>> getUnassignedDevices({
    required String bearerToken,
  }) async {
    final response = await _apiClient.get(
      ApiEndpoints.adminUnassignedDevices,
      bearerToken: bearerToken,
      showGlobalLoader: false,
    );

    if (!response.isSuccess) {
      throw ApiException(
        _extractMessage(response.data) ?? 'Unable to fetch unassigned devices.',
        statusCode: response.statusCode,
      );
    }

    final data = response.data;
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(AdminUnassignedDevice.fromJson)
          .toList();
    }
    if (data is Map<String, dynamic>) {
      final content = data['content'] ?? data['items'] ?? data['data'];
      if (content is List) {
        return content
            .whereType<Map<String, dynamic>>()
            .map(AdminUnassignedDevice.fromJson)
            .toList();
      }
    }
    return const <AdminUnassignedDevice>[];
  }

  Future<AdminCustomerAssignedDevicePageResult> getCustomerDevices({
    required String bearerToken,
    required String customerId,
    required int page,
    int size = 10,
  }) async {
    final normalizedCustomerId = customerId.trim();
    if (normalizedCustomerId.isEmpty) {
      throw const ApiException(
        'Customer ID is missing. Please refresh customers and try again.',
      );
    }

    final response = await _apiClient.get(
      ApiEndpoints.adminCustomerDevices(normalizedCustomerId),
      bearerToken: bearerToken,
      queryParameters: {'page': page, 'size': size},
      showGlobalLoader: false,
    );

    if (!response.isSuccess) {
      throw ApiException(
        _extractMessage(response.data) ?? 'Unable to fetch assigned devices.',
        statusCode: response.statusCode,
      );
    }

    final data = response.data;
    if (data is! Map<String, dynamic>) {
      return AdminCustomerAssignedDevicePageResult(
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
              .map(AdminCustomerAssignedDevice.fromJson)
              .toList()
        : const <AdminCustomerAssignedDevice>[];

    final totalPages = (data['totalPages'] as num?)?.toInt() ?? 1;
    final totalElements =
        (data['totalElements'] as num?)?.toInt() ?? items.length;
    final currentPage = (data['number'] as num?)?.toInt() ?? page;
    final currentSize = (data['size'] as num?)?.toInt() ?? size;

    return AdminCustomerAssignedDevicePageResult(
      items: items,
      page: currentPage,
      size: currentSize,
      totalPages: totalPages < 1 ? 1 : totalPages,
      totalElements: totalElements,
    );
  }

  Future<void> createCustomer({
    required String bearerToken,
    required AdminCustomerRequest request,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.adminCustomers,
      bearerToken: bearerToken,
      body: request.toJson(),
    );

    if (response.isSuccess) {
      return;
    }

    throw ApiException(
      _extractMessage(response.data) ?? 'Unable to create customer.',
      statusCode: response.statusCode,
    );
  }

  Future<void> updateCustomer({
    required String bearerToken,
    required String customerId,
    required AdminCustomerUpdateRequest request,
  }) async {
    final normalizedCustomerId = customerId.trim();
    if (normalizedCustomerId.isEmpty) {
      throw const ApiException(
        'Customer ID is missing. Please refresh customers and try again.',
      );
    }

    final response = await _apiClient.put(
      ApiEndpoints.adminCustomerById(normalizedCustomerId),
      bearerToken: bearerToken,
      body: request.toJson(),
    );

    if (response.isSuccess) {
      return;
    }

    throw ApiException(
      _extractMessage(response.data) ?? 'Unable to update customer.',
      statusCode: response.statusCode,
    );
  }

  Future<void> deleteCustomer({
    required String bearerToken,
    required String customerId,
  }) async {
    final normalizedCustomerId = customerId.trim();
    if (normalizedCustomerId.isEmpty) {
      throw const ApiException(
        'Customer ID is missing. Please refresh customers and try again.',
      );
    }

    final response = await _apiClient.delete(
      ApiEndpoints.adminCustomerById(normalizedCustomerId),
      bearerToken: bearerToken,
    );

    if (response.isSuccess) {
      return;
    }

    throw ApiException(
      _extractMessage(response.data) ?? 'Unable to delete customer.',
      statusCode: response.statusCode,
    );
  }

  Future<void> assignDevices({
    required String bearerToken,
    required String customerId,
    required AdminCustomerAssignDevicesRequest request,
  }) async {
    final normalizedCustomerId = customerId.trim();
    if (normalizedCustomerId.isEmpty) {
      throw const ApiException(
        'Customer ID is missing. Please refresh customers and try again.',
      );
    }

    final response = await _apiClient.post(
      ApiEndpoints.adminCustomerDevices(normalizedCustomerId),
      bearerToken: bearerToken,
      body: request.toJson(),
    );

    if (response.isSuccess) {
      return;
    }

    throw ApiException(
      _extractMessage(response.data) ?? 'Unable to assign device(s).',
      statusCode: response.statusCode,
    );
  }

  Future<String> unassignDevice({
    required String bearerToken,
    required String espId,
  }) async {
    final normalizedEspId = espId.trim();
    if (normalizedEspId.isEmpty) {
      throw const ApiException('Device ID is missing. Please try again.');
    }

    final response = await _apiClient.put(
      ApiEndpoints.adminDeviceUnassign(normalizedEspId),
      bearerToken: bearerToken,
    );

    if (response.isSuccess) {
      if (response.data is String) {
        final message = response.data.toString().trim();
        if (message.isNotEmpty) {
          return message;
        }
      }
      return _extractMessage(response.data) ?? 'Device unassigned successfully';
    }

    throw ApiException(
      _extractMessage(response.data) ?? 'Unable to unassign device.',
      statusCode: response.statusCode,
    );
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
