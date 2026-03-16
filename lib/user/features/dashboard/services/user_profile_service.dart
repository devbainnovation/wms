import 'package:wms/core/api/api.dart';

class UserProfile {
  const UserProfile({
    required this.userId,
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
    required this.role,
    required this.createdAt,
    required this.active,
  });

  final String userId;
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
  final String role;
  final DateTime? createdAt;
  final bool active;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    String read(List<String> keys) {
      for (final key in keys) {
        final value = json[key];
        if (value == null) {
          continue;
        }
        final text = value.toString().trim();
        if (text.isNotEmpty && text.toLowerCase() != 'null') {
          return text;
        }
      }
      return '';
    }

    DateTime? readDate(String key) {
      final raw = json[key]?.toString().trim() ?? '';
      if (raw.isEmpty || raw.toLowerCase() == 'null') {
        return null;
      }
      return DateTime.tryParse(raw);
    }

    return UserProfile(
      userId: read(const ['userId', 'id']),
      phoneNumber: read(const ['phoneNumber', 'phone']),
      username: read(const ['username', 'userName']),
      fullName: read(const ['fullName', 'name']),
      email: read(const ['email', 'mail']),
      village: read(const ['village', 'city']),
      addressLine1: read(const ['addressLine1', 'address', 'address1']),
      addressLine2: read(const ['addressLine2', 'address2']),
      taluka: read(const ['taluka']),
      district: read(const ['district']),
      state: read(const ['state']),
      pincode: read(const ['pincode', 'pinCode', 'postalCode']),
      role: read(const ['role']),
      createdAt: readDate('createdAt'),
      active: json['active'] == true,
    );
  }
}

class UserProfileUpdateRequest {
  const UserProfileUpdateRequest({
    required this.fullName,
    required this.email,
    required this.village,
    required this.addressLine1,
    required this.addressLine2,
    required this.taluka,
    required this.district,
    required this.state,
    required this.pincode,
  });

  final String fullName;
  final String email;
  final String village;
  final String addressLine1;
  final String addressLine2;
  final String taluka;
  final String district;
  final String state;
  final String pincode;

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName.trim(),
      'email': email.trim(),
      'village': village.trim(),
      'addressLine1': addressLine1.trim(),
      'addressLine2': addressLine2.trim(),
      'taluka': taluka.trim(),
      'district': district.trim(),
      'state': state.trim(),
      'pincode': pincode.trim(),
    };
  }
}

class UserProfilePasswordUpdateRequest {
  const UserProfilePasswordUpdateRequest({
    required this.currentPassword,
    required this.newPassword,
  });

  final String currentPassword;
  final String newPassword;

  Map<String, dynamic> toJson() {
    return {'currentPassword': currentPassword, 'newPassword': newPassword};
  }
}

class UserProfileService {
  UserProfileService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<UserProfile> getProfile({required String bearerToken}) async {
    final response = await _apiClient.get(
      ApiEndpoints.userProfile,
      bearerToken: bearerToken,
      showGlobalLoader: false,
    );

    if (!response.isSuccess) {
      throw ApiException(
        _extractMessage(response.data) ?? 'Unable to load profile.',
        statusCode: response.statusCode,
      );
    }

    final data = response.data;
    if (data is Map<String, dynamic>) {
      return UserProfile.fromJson(data);
    }

    throw const ApiException('Invalid profile response.');
  }

  Future<void> updateProfile({
    required String bearerToken,
    required UserProfileUpdateRequest request,
  }) async {
    final response = await _apiClient.put(
      ApiEndpoints.userProfile,
      bearerToken: bearerToken,
      body: request.toJson(),
    );

    if (response.isSuccess) {
      return;
    }

    throw ApiException(
      _extractMessage(response.data) ?? 'Unable to update profile.',
      statusCode: response.statusCode,
    );
  }

  Future<void> updatePassword({
    required String bearerToken,
    required UserProfilePasswordUpdateRequest request,
  }) async {
    final response = await _apiClient.put(
      ApiEndpoints.userProfilePassword,
      bearerToken: bearerToken,
      body: request.toJson(),
    );

    if (response.isSuccess) {
      return;
    }

    throw ApiException(
      _extractMessage(response.data) ?? 'Unable to change password.',
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
