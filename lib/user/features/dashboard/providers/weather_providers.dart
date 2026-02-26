import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wms/user/features/dashboard/services/weather_service.dart';

const _defaultCity = 'Ahmedabad';

final weatherServiceProvider = Provider<WeatherService>((ref) {
  return MockWeatherService();
});

final currentWeatherProvider = FutureProvider.autoDispose<WeatherData>((ref) {
  final service = ref.watch(weatherServiceProvider);
  return service.getCurrentWeather(city: _defaultCity);
});
