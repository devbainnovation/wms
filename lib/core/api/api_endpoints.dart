class ApiEndpoints {
  ApiEndpoints._();

  static const String authLogin = '/api/auth/login';
  static const String authSendOtp = '/api/auth/send-otp';
  static const String authVerifyOtp = '/api/auth/verify-otp';
  static const String adminDevices = '/api/admin/devices';

  static String authLogout(String sessionId) => '/api/auth/logout/$sessionId';
  static String adminDeviceById(String id) => '/api/admin/devices/$id';
}
