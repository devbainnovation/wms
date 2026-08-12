import 'package:wms/core/api/api.dart';
import 'package:wms/admin/features/customers/services/admin_customer_models.dart';

export 'admin_customer_models.dart';

class AdminCustomerService {
  AdminCustomerService({required ApiClient apiClient}) : _apiClient = apiClient;

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
    if (data is List) {
      final items = data
          .whereType<Map<String, dynamic>>()
          .map(AdminCustomerSummary.fromJson)
          .toList();
      return AdminCustomerPageResult(
        items: items,
        page: page,
        size: items.length > size ? items.length : size,
        totalPages: 1,
        totalElements: items.length,
      );
    }

    if (data is! Map<String, dynamic>) {
      return AdminCustomerPageResult(
        items: const [],
        page: page,
        size: size,
        totalPages: 1,
        totalElements: 0,
      );
    }

    final content = data['content'] ?? data['items'] ?? data['data'];
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
    print('--- getCustomerDevices: START ---');
    print('Customer ID: "$normalizedCustomerId", Page: $page, Size: $size');

    if (normalizedCustomerId.isEmpty) {
      print('getCustomerDevices: Error - Customer ID is empty');
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

    print('getCustomerDevices: API Status Code: ${response.statusCode}');
    print('getCustomerDevices: API Success: ${response.isSuccess}');

    if (!response.isSuccess) {
      print('getCustomerDevices: Error Response Data: ${response.data}');
      throw ApiException(
        _extractMessage(response.data) ?? 'Unable to fetch assigned devices.',
        statusCode: response.statusCode,
      );
    }

    final data = response.data;
    print('getCustomerDevices: Data Type: ${data.runtimeType}');

    if (data is List) {
      print('getCustomerDevices: Processing as List...');
      final items = data
          .whereType<Map<String, dynamic>>()
          .map(AdminCustomerAssignedDevice.fromJson)
          .toList();
      print('getCustomerDevices: Parsed List count: ${items.length}');
      print('--- getCustomerDevices: END (List) ---');
      return AdminCustomerAssignedDevicePageResult(
        items: items,
        page: page,
        size: items.length > size ? items.length : size,
        totalPages: 1,
        totalElements: items.length,
      );
    }

    if (data is! Map<String, dynamic>) {
      print('getCustomerDevices: Warning - Data is not a Map or List. Returning empty result.');
      return AdminCustomerAssignedDevicePageResult(
        items: const [],
        page: page,
        size: size,
        totalPages: 1,
        totalElements: 0,
      );
    }

    print('getCustomerDevices: Processing as Map...');
    final content = data['content'] ?? data['items'] ?? data['data'];
    print('getCustomerDevices: "content/items/data" field value: $content');
    
    final items = content is List
        ? content
              .whereType<Map<String, dynamic>>()
              .map(AdminCustomerAssignedDevice.fromJson)
              .toList()
        : const <AdminCustomerAssignedDevice>[];

    print('getCustomerDevices: Parsed items count: ${items.length}');

    final totalPages = (data['totalPages'] as num?)?.toInt() ?? 1;
    final totalElements =
        (data['totalElements'] as num?)?.toInt() ?? items.length;
    final currentPage = (data['number'] as num?)?.toInt() ?? page;
    final currentSize = (data['size'] as num?)?.toInt() ?? size;

    print('getCustomerDevices: Page: $currentPage, Total Pages: $totalPages, Total Elements: $totalElements');
    print('--- getCustomerDevices: END (Map) ---');

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
      ApiEndpoints.adminCustomerUserById(normalizedCustomerId),
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
