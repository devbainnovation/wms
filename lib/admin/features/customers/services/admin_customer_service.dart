import 'package:wms/core/api/api.dart';

class AdminCustomerRequest {
  const AdminCustomerRequest({
    required this.phoneNumber,
    required this.username,
    required this.password,
    required this.fullName,
    required this.email,
    required this.village,
    required this.address,
    required this.espUnitIds,
  });

  final String phoneNumber;
  final String username;
  final String password;
  final String fullName;
  final String email;
  final String village;
  final String address;
  final List<String> espUnitIds;

  Map<String, dynamic> toJson() {
    return {
      'phoneNumber': phoneNumber,
      'username': username,
      'password': password,
      'fullName': fullName,
      'email': email,
      'village': village,
      'address': address,
      'espUnitIds': espUnitIds,
    };
  }
}

class AdminCustomerSummary {
  const AdminCustomerSummary({
    required this.id,
    required this.phoneNumber,
    required this.username,
    required this.fullName,
    required this.email,
    required this.village,
    required this.address,
    required this.espUnitIds,
  });

  final String id;
  final String phoneNumber;
  final String username;
  final String fullName;
  final String email;
  final String village;
  final String address;
  final List<String> espUnitIds;

  factory AdminCustomerSummary.fromJson(Map<String, dynamic> json) {
    final espUnitsRaw = json['espUnitIds'] ?? json['espIds'] ?? json['devices'];
    final espUnitIds = espUnitsRaw is List
        ? espUnitsRaw.map((e) => e.toString()).where((e) => e.isNotEmpty).toList()
        : const <String>[];

    return AdminCustomerSummary(
      id: (json['id'] ?? json['customerId'] ?? '').toString(),
      phoneNumber: (json['phoneNumber'] ?? '').toString(),
      username: (json['username'] ?? '').toString(),
      fullName: (json['fullName'] ?? json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      village: (json['village'] ?? '').toString(),
      address: (json['address'] ?? '').toString(),
      espUnitIds: espUnitIds,
    );
  }
}

class AdminUnassignedDevice {
  const AdminUnassignedDevice({
    required this.id,
    required this.displayName,
  });

  final String id;
  final String displayName;

  factory AdminUnassignedDevice.fromJson(Map<String, dynamic> json) {
    final id = (json['id'] ?? json['espId'] ?? json['deviceId'] ?? '').toString();
    final name = (json['displayName'] ?? json['name'] ?? json['macAddress'] ?? id)
        .toString();
    return AdminUnassignedDevice(id: id, displayName: name);
  }
}

class AdminCustomerPageResult {
  const AdminCustomerPageResult({
    required this.items,
    required this.page,
    required this.size,
    required this.totalPages,
    required this.totalElements,
  });

  final List<AdminCustomerSummary> items;
  final int page;
  final int size;
  final int totalPages;
  final int totalElements;

  bool get hasPrevious => page > 0;
  bool get hasNext => page + 1 < totalPages;
}

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
