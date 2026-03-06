import 'package:wms/core/api/api.dart';

class AdminCustomerRequest {
  const AdminCustomerRequest({
    required this.phoneNumber,
    required this.username,
    required this.password,
    required this.fullName,
    required this.email,
    required this.village,
    required this.addressLine1,
    required this.district,
    required this.state,
    required this.pincode,
    required this.espUnitIds,
    this.addressLine2,
    this.taluka,
  });

  final String phoneNumber;
  final String username;
  final String password;
  final String fullName;
  final String email;
  final String village;
  final String addressLine1;
  final String? addressLine2;
  final String? taluka;
  final String district;
  final String state;
  final String pincode;
  final List<String> espUnitIds;

  Map<String, dynamic> toJson() {
    final normalizedAddressLine1 = _requiredTrimmed(
      addressLine1,
      'Address Line 1',
    );
    final normalizedAddressLine2 = (addressLine2 ?? '').trim();
    final normalizedTaluka = (taluka ?? '').trim();
    final normalizedDistrict = _requiredTrimmed(district, 'District');
    final normalizedState = _requiredTrimmed(state, 'State');
    final normalizedPincode = _requiredTrimmed(pincode, 'Pincode');

    final normalizedEspUnitIds = espUnitIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty && id.toLowerCase() != 'string')
        .toSet()
        .toList();

    return {
      'phoneNumber': phoneNumber,
      'username': username,
      'password': password,
      'fullName': fullName,
      'email': email,
      'village': village,
      'addressLine1': normalizedAddressLine1,
      'addressLine2': normalizedAddressLine2,
      'taluka': normalizedTaluka,
      'district': normalizedDistrict,
      'state': normalizedState,
      'pincode': normalizedPincode,
      'espUnitIds': normalizedEspUnitIds,
    };
  }
}

String _requiredTrimmed(String value, String label) {
  final text = value.trim();
  if (text.isEmpty) {
    throw ApiException('$label is required.');
  }
  return text;
}

class AdminCustomerUpdateRequest {
  const AdminCustomerUpdateRequest({
    required this.fullName,
    required this.email,
    required this.village,
    required this.addressLine1,
    required this.district,
    required this.state,
    required this.pincode,
    this.addressLine2,
    this.taluka,
  });

  final String fullName;
  final String email;
  final String village;
  final String addressLine1;
  final String? addressLine2;
  final String? taluka;
  final String district;
  final String state;
  final String pincode;

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'email': email,
      'village': village,
      'addressLine1': addressLine1.trim(),
      'addressLine2': (addressLine2 ?? '').trim(),
      'taluka': (taluka ?? '').trim(),
      'district': district,
      'state': state,
      'pincode': pincode,
    };
  }
}

class AdminCustomerAssignDevicesRequest {
  const AdminCustomerAssignDevicesRequest({
    required this.userId,
    required this.espUnitIds,
  });

  final String userId;
  final List<String> espUnitIds;

  Map<String, dynamic> toJson() {
    final normalizedEspUnitIds = espUnitIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty && id.toLowerCase() != 'string')
        .toSet()
        .toList();
    return {'userId': userId.trim(), 'espUnitIds': normalizedEspUnitIds};
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
    required this.addressLine1,
    required this.addressLine2,
    required this.taluka,
    required this.district,
    required this.state,
    required this.pincode,
    required this.espUnitIds,
  });

  final String id;
  final String phoneNumber;
  final String username;
  final String fullName;
  final String email;
  final String village;
  final String addressLine1;
  final String addressLine2;
  final String taluka;
  final String district;
  final String state;
  final String pincode;
  final List<String> espUnitIds;

  String get formattedAddress {
    final parts = <String>[
      village,
      addressLine1,
      addressLine2,
      taluka,
      district,
      state,
      pincode,
    ].where((part) => part.trim().isNotEmpty).toList();
    return parts.join(', ');
  }

  factory AdminCustomerSummary.fromJson(Map<String, dynamic> json) {
    final espUnitsRaw = json['espUnitIds'] ?? json['espIds'] ?? json['devices'];
    final espUnitIds = espUnitsRaw is List
        ? espUnitsRaw
              .map((e) => e.toString())
              .where((e) => e.isNotEmpty)
              .toList()
        : const <String>[];

    return AdminCustomerSummary(
      id: _extractCustomerId(json),
      phoneNumber: _readStringByKeys(json, const ['phoneNumber', 'phone']),
      username: _readStringByKeys(json, const ['username', 'userName']),
      fullName: _readStringByKeys(json, const ['fullName', 'name']),
      email: _readStringByKeys(json, const ['email', 'mail']),
      village: _readStringByKeys(json, const ['village', 'city']),
      addressLine1: _readStringByKeys(json, const [
        'addressLine1',
        'address1',
        'address',
        'line1',
      ]),
      addressLine2: _readStringByKeys(json, const [
        'addressLine2',
        'address2',
        'line2',
      ]),
      taluka: _readStringByKeys(json, const ['taluka', 'tehsil']),
      district: _readStringByKeys(json, const ['district', 'districtName']),
      state: _readStringByKeys(json, const ['state', 'stateName']),
      pincode: _readStringByKeys(json, const [
        'pincode',
        'pinCode',
        'postalCode',
        'zipCode',
        'zip',
      ]),
      espUnitIds: espUnitIds,
    );
  }
}

class AdminUnassignedDevice {
  const AdminUnassignedDevice({required this.id, required this.displayName});

  final String id;
  final String displayName;

  factory AdminUnassignedDevice.fromJson(Map<String, dynamic> json) {
    final id = (json['id'] ?? json['espId'] ?? json['deviceId'] ?? '')
        .toString();
    final name =
        (json['displayName'] ?? json['name'] ?? json['macAddress'] ?? id)
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

String _extractCustomerId(Map<String, dynamic> json) {
  const keys = <String>[
    'id',
    'userId',
    'userID',
    'user_id',
    'customerId',
    'customerID',
    'customer_id',
    'uuid',
    'customerUuid',
    'customerUUID',
  ];
  for (final key in keys) {
    final value = json[key];
    final text = (value ?? '').toString().trim();
    if (text.isNotEmpty) {
      return text;
    }
  }
  return '';
}

String _readStringByKeys(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    final text = (value ?? '').toString().trim();
    if (text.isNotEmpty && text.toLowerCase() != 'null') {
      return text;
    }
  }
  return '';
}
