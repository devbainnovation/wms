import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wms/core/services/push_notification_service.dart';

final pushNotificationServiceProvider = Provider<PushNotificationService>((
  ref,
) {
  return PushNotificationService();
});

final pushNotificationInitProvider = FutureProvider<void>((ref) async {
  await ref.read(pushNotificationServiceProvider).initialize();
});

final fcmTokenProvider = FutureProvider<String?>((ref) async {
  final service = ref.read(pushNotificationServiceProvider);
  return service.getToken();
});
