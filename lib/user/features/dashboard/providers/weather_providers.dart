import 'package:wms/core/core.dart';
import 'package:wms/user/features/dashboard/providers/user_profile_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wms/user/features/dashboard/services/weather_service.dart';

final weatherServiceProvider = Provider<WeatherService>((ref) {
  final service = OpenMeteoWeatherService();
  ref.onDispose(() {
    service.dispose();
  });
  return service;
});

final currentWeatherProvider = FutureProvider.autoDispose<WeatherData>((
  ref,
) async {
  final profile = await ref.watch(userProfileProvider.future);
  final pincode = profile.pincode.trim();
  if (pincode.isEmpty) {
    throw const ApiException('Pincode is missing in profile.');
  }
  final service = ref.watch(weatherServiceProvider);
  return service.getCurrentWeather(pincode: pincode);
});
