class ApiEndpoints {
  ApiEndpoints._();

  static const String authLogin = '/api/auth/login';
  static const String authSendOtp = '/api/auth/send-otp';
  static const String authVerifyOtp = '/api/auth/verify-otp';
  static const String adminDevices = '/api/admin/devices';
  static const String adminCustomers = '/api/admin/customers';
  static const String adminUnassignedDevices = '/api/admin/devices/unassigned';
  static const String adminSystemDashboard = '/api/admin/system/dashboard';
  static const String customerUsers = '/api/customer/users';
  static const String customerDevices = '/api/customer/devices';
  static const String customerManualTriggers = '/api/customer/manual-triggers';

  static String authLogout(String sessionId) => '/api/auth/logout/$sessionId';
  static String adminDeviceById(String id) => '/api/admin/devices/$id';
  static String adminCustomerById(String id) => '/api/admin/customers/$id';
  static String adminCustomerDevices(String id) =>
      '/api/admin/customers/$id/devices';
  static String customerUserById(String userId) =>
      '/api/customer/users/$userId';
  static String customerUserPermissions(String userId) =>
      '/api/customer/users/$userId/permissions';
  static String adminDeviceComponents(String id) =>
      '/api/admin/devices/$id/components';
  static String adminDeviceComponentById(String id, String compId) =>
      '/api/admin/devices/$id/components/$compId';
}
