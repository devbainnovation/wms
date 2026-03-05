import 'package:wms/core/api/api.dart';

class UserAdminUserPermissions {
  const UserAdminUserPermissions({
    required this.canViewDashboard,
    required this.canControlValves,
    required this.canCreateSchedules,
    required this.canUpdateSchedules,
    required this.canDeleteSchedules,
    required this.canCreateTriggers,
    required this.canManageNotifs,
  });

  final bool canViewDashboard;
  final bool canControlValves;
  final bool canCreateSchedules;
  final bool canUpdateSchedules;
  final bool canDeleteSchedules;
  final bool canCreateTriggers;
  final bool canManageNotifs;

  Map<String, dynamic> toJson() {
    return {
      'canViewDashboard': canViewDashboard,
      'canControlValves': canControlValves,
      'canCreateSchedules': canCreateSchedules,
      'canUpdateSchedules': canUpdateSchedules,
      'canDeleteSchedules': canDeleteSchedules,
      'canCreateTriggers': canCreateTriggers,
      'canManageNotifs': canManageNotifs,
    };
  }

  factory UserAdminUserPermissions.fromJson(Map<String, dynamic>? json) {
    final map = json ?? const <String, dynamic>{};
    bool read(String key, {bool fallback = true}) {
      final value = map[key];
      if (value is bool) {
        return value;
      }
      if (value is String) {
        final normalized = value.trim().toLowerCase();
        if (normalized == 'true') {
          return true;
        }
        if (normalized == 'false') {
          return false;
        }
      }
      return fallback;
    }

    return UserAdminUserPermissions(
      canViewDashboard: read('canViewDashboard'),
      canControlValves: read('canControlValves'),
      canCreateSchedules: read('canCreateSchedules'),
      canUpdateSchedules: read('canUpdateSchedules'),
      canDeleteSchedules: read('canDeleteSchedules'),
      canCreateTriggers: read('canCreateTriggers'),
      canManageNotifs: read('canManageNotifs'),
    );
  }
}

class UserAdminUserCreateRequest {
  const UserAdminUserCreateRequest({
    required this.phoneNumber,
    required this.username,
    required this.password,
    required this.fullName,
    required this.email,
    required this.village,
    required this.addressLine1,
    required this.addressLine2,
    required this.taluka,
    required this.district,
    required this.state,
    required this.pincode,
    required this.role,
    required this.permissions,
  });

  final String phoneNumber;
  final String username;
  final String password;
  final String fullName;
  final String email;
  final String village;
  final String addressLine1;
  final String addressLine2;
  final String taluka;
  final String district;
  final String state;
  final String pincode;
  final String role;
  final UserAdminUserPermissions permissions;

  Map<String, dynamic> toJson() {
    return {
      'phoneNumber': phoneNumber.trim(),
      'username': username.trim(),
      'password': password,
      'fullName': fullName.trim(),
      'email': email.trim(),
      'village': village.trim(),
      'addressLine1': addressLine1.trim(),
      'addressLine2': addressLine2.trim(),
      'taluka': taluka.trim(),
      'district': district.trim(),
      'state': state.trim(),
      'pincode': pincode.trim(),
      'role': role.trim(),
      'permissions': permissions.toJson(),
    };
  }
}

class UserAdminUserSummary {
  const UserAdminUserSummary({
    required this.userId,
    required this.fullName,
    required this.phoneNumber,
    required this.username,
    required this.email,
    required this.village,
    required this.addressLine1,
    required this.addressLine2,
    required this.taluka,
    required this.district,
    required this.state,
    required this.pincode,
    required this.role,
    required this.permissions,
  });

  final String userId;
  final String fullName;
  final String phoneNumber;
  final String username;
  final String email;
  final String village;
  final String addressLine1;
  final String addressLine2;
  final String taluka;
  final String district;
  final String state;
  final String pincode;
  final String role;
  final UserAdminUserPermissions permissions;

  factory UserAdminUserSummary.fromJson(Map<String, dynamic> json) {
    String read(List<String> keys) {
      for (final key in keys) {
        final value = (json[key] ?? '').toString().trim();
        if (value.isNotEmpty && value.toLowerCase() != 'null') {
          return value;
        }
      }
      return '';
    }

    return UserAdminUserSummary(
      userId: read(const ['userId', 'id', 'customerId']),
      fullName: read(const ['fullName', 'name']),
      phoneNumber: read(const ['phoneNumber', 'phone']),
      username: read(const ['username', 'userName']),
      email: read(const ['email', 'mail']),
      village: read(const ['village', 'city']),
      addressLine1: read(const ['addressLine1', 'address', 'address1']),
      addressLine2: read(const ['addressLine2', 'address2']),
      taluka: read(const ['taluka']),
      district: read(const ['district', 'districtName']),
      state: read(const ['state', 'stateName']),
      pincode: read(const ['pincode', 'pinCode', 'postalCode']),
      role: read(const ['role']),
      permissions: UserAdminUserPermissions.fromJson(
        json['permissions'] as Map<String, dynamic>?,
      ),
    );
  }
}

class UserAdminUsersService {
  UserAdminUsersService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<UserAdminUserSummary>> getUsers({
    required String bearerToken,
  }) async {
    final response = await _apiClient.get(
      ApiEndpoints.customerUsers,
      bearerToken: bearerToken,
      showGlobalLoader: false,
    );

    if (!response.isSuccess) {
      throw ApiException(
        _extractMessage(response.data) ?? 'Unable to fetch users.',
        statusCode: response.statusCode,
      );
    }

    final data = response.data;
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(UserAdminUserSummary.fromJson)
          .toList();
    }

    if (data is Map<String, dynamic>) {
      final content = data['content'] ?? data['items'] ?? data['data'];
      if (content is List) {
        return content
            .whereType<Map<String, dynamic>>()
            .map(UserAdminUserSummary.fromJson)
            .toList();
      }
    }

    return const <UserAdminUserSummary>[];
  }

  Future<void> createUser({
    required String bearerToken,
    required UserAdminUserCreateRequest request,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.customerUsers,
      bearerToken: bearerToken,
      body: request.toJson(),
    );

    if (response.isSuccess) {
      return;
    }

    throw ApiException(
      _extractMessage(response.data) ?? 'Unable to create user.',
      statusCode: response.statusCode,
    );
  }

  Future<void> deleteUser({
    required String bearerToken,
    required String userId,
  }) async {
    final normalizedId = userId.trim();
    if (normalizedId.isEmpty) {
      throw const ApiException('User ID is missing.');
    }

    final response = await _apiClient.delete(
      ApiEndpoints.customerUserById(normalizedId),
      bearerToken: bearerToken,
    );

    if (response.isSuccess) {
      return;
    }

    throw ApiException(
      _extractMessage(response.data) ?? 'Unable to delete user.',
      statusCode: response.statusCode,
    );
  }

  Future<UserAdminUserSummary> getUserById({
    required String bearerToken,
    required String userId,
  }) async {
    final normalizedId = userId.trim();
    if (normalizedId.isEmpty) {
      throw const ApiException('User ID is missing.');
    }

    final response = await _apiClient.get(
      ApiEndpoints.customerUserById(normalizedId),
      bearerToken: bearerToken,
      showGlobalLoader: false,
    );

    if (!response.isSuccess) {
      throw ApiException(
        _extractMessage(response.data) ?? 'Unable to fetch user details.',
        statusCode: response.statusCode,
      );
    }

    final data = response.data;
    if (data is Map<String, dynamic>) {
      return UserAdminUserSummary.fromJson(data);
    }
    throw const ApiException('Invalid user details response.');
  }

  Future<void> updateUserPermissions({
    required String bearerToken,
    required String userId,
    required UserAdminUserPermissions permissions,
  }) async {
    final normalizedId = userId.trim();
    if (normalizedId.isEmpty) {
      throw const ApiException('User ID is missing.');
    }

    final response = await _apiClient.put(
      ApiEndpoints.customerUserPermissions(normalizedId),
      bearerToken: bearerToken,
      body: permissions.toJson(),
    );

    if (response.isSuccess) {
      return;
    }

    throw ApiException(
      _extractMessage(response.data) ?? 'Unable to update user permissions.',
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
