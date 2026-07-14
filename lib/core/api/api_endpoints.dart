class ApiEndpoints {
  ApiEndpoints._();

  static const String authLogin = '/api/auth/login';
  static const String authSendOtp = '/api/auth/send-otp';
  static const String authCheckMobile = '/api/auth/check-mobile';
  static const String authVerifyOtp = '/api/auth/verify-otp';
  static const String adminDevices = '/api/admin/devices';
  static const String adminCustomers = '/api/admin/customers';
  static const String adminUnassignedDevices = '/api/admin/devices/unassigned';
  static const String adminSystemDashboard = '/api/admin/system/dashboard';
  static const String adminTriggerLogs = '/api/admin/trigger-logs';
  static const String customerUsers = '/api/customer/users';
  static const String customerDevices = '/api/customer/devices';
  static const String appDashboard = '/api/app/dashboard';
  static const String appTankLevels = '/api/app/tank-levels';
  static const String customerManualTriggers = '/api/app/control/toggle';
  static const String customerSchedules = '/api/customer/schedules';
  static const String customerMotorSettings =
      '/api/customer/devices/motor-settings';
  static const String appSchedules = '/api/app/schedules';
  static const String userProfile = '/api/user/profile';
  static const String userProfilePassword = '/api/user/profile/password';

  static String authLogout(String sessionId) => '/api/auth/logout/$sessionId';
  static String adminDeviceById(String id) => '/api/admin/devices/$id';
  static String adminDeviceSchedules(String espId) =>
      '/api/admin/devices/$espId/schedules';
  static String adminDeviceUnassign(String espId) =>
      '/api/admin/devices/$espId/unassign';
  static String adminCustomerById(String id) => '/api/admin/customers/$id';
  static String adminCustomerUserById(String userId) =>
      '/api/admin/customers/$userId';
  static String adminCustomerDevices(String id) =>
      '/api/admin/customers/$id/devices';
  static String customerDeviceComponents(String espId) =>
      '/api/customer/devices/$espId/components';
  static String customerDeviceComponentRename(String espId, String compId) =>
      '/api/customer/devices/$espId/components/$compId/rename';
  static String customerUserById(String userId) =>
      '/api/customer/users/$userId';
  static String customerUserPermissions(String userId) =>
      '/api/customer/users/$userId/permissions';
  static String adminDeviceComponents(String id) =>
      '/api/admin/devices/$id/components';
  static String adminDeviceComponentById(String id, String compId) =>
      '/api/admin/devices/$id/components/$compId';
  static String customerComponentSchedules(String componentId) =>
      '/api/customer/components/$componentId/schedules';
  static String appComponentSchedules(String componentId) =>
      '/api/app/components/$componentId/schedules';
  static String appComponentScheduleById(
    String componentId,
    String scheduleId,
  ) => '/api/app/components/$componentId/schedules/$scheduleId';
  static String appScheduleById(String id) => '/api/app/schedules/$id';
  static String appTankHistory(String componentId) =>
      '/api/app/sensor/$componentId/history-compact';
}
