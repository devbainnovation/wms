class AuthSession {
  const AuthSession({
    required this.token,
    required this.role,
    required this.userId,
    required this.sessionId,
  });

  final String token;
  final String role;
  final String userId;
  final String sessionId;

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      token: (json['token'] ?? '').toString(),
      role: (json['role'] ?? '').toString(),
      userId: (json['userId'] ?? '').toString(),
      sessionId: (json['sessionId'] ?? '').toString(),
    );
  }

  bool get isValid =>
      token.isNotEmpty &&
      role.isNotEmpty &&
      userId.isNotEmpty &&
      sessionId.isNotEmpty;
}

class RememberedAuthData {
  const RememberedAuthData({
    required this.username,
    required this.password,
    required this.token,
    required this.role,
    required this.userId,
    required this.sessionId,
    required this.rememberMe,
  });

  final String username;
  final String password;
  final String token;
  final String role;
  final String userId;
  final String sessionId;
  final bool rememberMe;
}

class AuthApiException implements Exception {
  const AuthApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}
