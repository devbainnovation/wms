class WeatherData {
  const WeatherData({
    required this.city,
    required this.temperatureCelsius,
    required this.condition,
    required this.iconCode,
  });

  final String city;
  final int temperatureCelsius;
  final String condition;
  final String iconCode;
}

abstract class WeatherService {
  Future<WeatherData> getCurrentWeather({required String city});
}

class MockWeatherService implements WeatherService {
  @override
  Future<WeatherData> getCurrentWeather({required String city}) async {
    await Future<void>.delayed(const Duration(milliseconds: 450));

    // Replace with real API call integration later.
    return WeatherData(
      city: city,
      temperatureCelsius: 28,
      condition: 'Partly Cloudy',
      iconCode: 'partly_cloudy',
    );
  }
}
