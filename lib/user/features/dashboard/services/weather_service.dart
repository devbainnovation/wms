import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:wms/core/api/api_exception.dart';

class WeatherData {
  const WeatherData({
    required this.city,
    required this.temperatureCelsius,
    required this.humidityPercent,
    required this.windSpeedKmh,
    required this.condition,
    required this.iconCode,
  });

  final String city;
  final int temperatureCelsius;
  final int humidityPercent;
  final int windSpeedKmh;
  final String condition;
  final String iconCode;
}

abstract class WeatherService {
  Future<WeatherData> getCurrentWeather({required String pincode});
}

class OpenMeteoWeatherService implements WeatherService {
  OpenMeteoWeatherService({http.Client? client})
    : _client = client ?? http.Client(),
      _ownsClient = client == null;

  final http.Client _client;
  final bool _ownsClient;

  static const _geocodingHost = 'geocoding-api.open-meteo.com';
  static const _forecastHost = 'api.open-meteo.com';
  static const _postalPincodeHost = 'api.postalpincode.in';
  static const _nominatimHost = 'nominatim.openstreetmap.org';

  void dispose() {
    if (_ownsClient) {
      _client.close();
    }
  }

  @override
  Future<WeatherData> getCurrentWeather({required String pincode}) async {
    final normalizedPincode = pincode.trim();
    _debugLog('WEATHER profile pincode: "$normalizedPincode"');
    if (normalizedPincode.length != 6 || int.tryParse(normalizedPincode) == null) {
      throw const ApiException('Please enter a valid 6-digit pincode');
    }

    final pincodeInfo = await _fetchPincodeInfo(normalizedPincode);
    final location = await _resolveCoordinates(
      pincode: normalizedPincode,
      pincodeInfo: pincodeInfo,
    );
    final weather = await _fetchForecast(location);
    return weather;
  }

  Future<_PincodeInfo> _fetchPincodeInfo(String pincode) async {
    final uri = Uri.https(_postalPincodeHost, '/pincode/$pincode');
    _debugLog('WEATHER pincode request: $uri');

    final response = await _client.get(
      uri,
      headers: const {'Accept': 'application/json'},
    );
    final body = _decodeJson(response.body);
    _debugLog('WEATHER pincode response status: ${response.statusCode}');
    _debugLog('WEATHER pincode response body: ${_pretty(body)}');
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        _readError(body) ?? 'Failed to fetch pincode details',
        statusCode: response.statusCode,
      );
    }

    if (body is! List || body.isEmpty) {
      throw const ApiException('Invalid pincode response');
    }

    final first = body.first;
    if (first is! Map<String, dynamic>) {
      throw const ApiException('Invalid pincode response');
    }

    final status = (first['Status'] ?? '').toString().trim().toLowerCase();
    final postOfficeList = first['PostOffice'];
    if (status != 'success' ||
        postOfficeList is! List ||
        postOfficeList.isEmpty) {
      throw const ApiException('Invalid pincode or location not found');
    }

    final postOffice = postOfficeList.first;
    if (postOffice is! Map<String, dynamic>) {
      throw const ApiException('Invalid pincode response');
    }

    final info = _PincodeInfo(
      placeName: (postOffice['Name'] ?? '').toString().trim(),
      district: (postOffice['District'] ?? '').toString().trim(),
      state: (postOffice['State'] ?? '').toString().trim(),
    );
    _debugLog(
      'WEATHER pincode resolved: place="${info.placeName}", district="${info.district}", state="${info.state}"',
    );
    return info;
  }

  Future<_WeatherLocation> _resolveCoordinates({
    required String pincode,
    required _PincodeInfo pincodeInfo,
  }) async {
    final queries = <String>[
      '${pincodeInfo.placeName}, ${pincodeInfo.district}, ${pincodeInfo.state}, India',
      '${pincodeInfo.district}, ${pincodeInfo.state}, India',
      '${pincodeInfo.state}, India',
    ];

    for (final query in queries) {
      final result = await _searchOpenMeteo(
        query,
        fallbackCity: pincodeInfo.placeName,
      );
      if (result != null) {
        return result;
      }
    }

    final fallbackResult = await _searchNominatim(
      pincode: pincode,
      district: pincodeInfo.district,
      state: pincodeInfo.state,
      fallbackCity: pincodeInfo.placeName,
    );
    if (fallbackResult != null) {
      return fallbackResult;
    }

    throw const ApiException(
      'Could not find coordinates for this pincode. Try another nearby pincode.',
    );
  }

  Future<_WeatherLocation?> _searchOpenMeteo(
    String query, {
    required String fallbackCity,
  }) async {
    final uri = Uri.https(_geocodingHost, '/v1/search', {
      'name': query,
      'count': '1',
      'countryCode': 'IN',
      'format': 'json',
    });
    _debugLog('WEATHER geocoding request: $uri');

    final response = await _client.get(
      uri,
      headers: const {'Accept': 'application/json'},
    );
    final body = _decodeJson(response.body);
    _debugLog('WEATHER geocoding response status: ${response.statusCode}');
    _debugLog('WEATHER geocoding response body: ${_pretty(body)}');
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return null;
    }

    if (body is! Map<String, dynamic>) {
      return null;
    }

    final results = body['results'];
    if (results is! List || results.isEmpty) {
      return null;
    }

    final first = results.first;
    if (first is! Map<String, dynamic>) {
      return null;
    }

    final latitude = _readDouble(first['latitude']);
    final longitude = _readDouble(first['longitude']);
    if (latitude == null || longitude == null) {
      return null;
    }

    final city = (first['name'] ?? fallbackCity).toString().trim();
    _debugLog(
      'WEATHER geocoding resolved: city="$city", lat=$latitude, lon=$longitude',
    );
    return _WeatherLocation(
      city: city.isEmpty ? fallbackCity : city,
      latitude: latitude,
      longitude: longitude,
    );
  }

  Future<_WeatherLocation?> _searchNominatim({
    required String pincode,
    required String district,
    required String state,
    required String fallbackCity,
  }) async {
    final uri = Uri.https(_nominatimHost, '/search', {
      'q': '$pincode, $district, $state, India',
      'format': 'jsonv2',
      'limit': '1',
    });
    _debugLog('WEATHER nominatim request: $uri');

    final response = await _client.get(
      uri,
      headers: const {
        'User-Agent': 'wms-weather/1.0',
        'Accept': 'application/json',
      },
    );
    final body = _decodeJson(response.body);
    _debugLog('WEATHER nominatim response status: ${response.statusCode}');
    _debugLog('WEATHER nominatim response body: ${_pretty(body)}');
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return null;
    }

    if (body is! List || body.isEmpty) {
      return null;
    }

    final first = body.first;
    if (first is! Map<String, dynamic>) {
      return null;
    }

    final latitude = _readDouble(first['lat']);
    final longitude = _readDouble(first['lon']);
    if (latitude == null || longitude == null) {
      return null;
    }

    _debugLog(
      'WEATHER nominatim resolved: city="$fallbackCity", lat=$latitude, lon=$longitude',
    );
    return _WeatherLocation(
      city: fallbackCity.isEmpty ? district : fallbackCity,
      latitude: latitude,
      longitude: longitude,
    );
  }

  Future<WeatherData> _fetchForecast(_WeatherLocation location) async {
    final uri = Uri.https(_forecastHost, '/v1/forecast', {
      'latitude': location.latitude.toString(),
      'longitude': location.longitude.toString(),
      'current':
          'temperature_2m,relative_humidity_2m,weather_code,is_day,wind_speed_10m',
      'timezone': 'auto',
    });
    _debugLog('WEATHER forecast request: $uri');

    final response = await _client.get(
      uri,
      headers: const {'Accept': 'application/json'},
    );
    final body = _decodeJson(response.body);
    _debugLog('WEATHER forecast response status: ${response.statusCode}');
    _debugLog('WEATHER forecast response body: ${_pretty(body)}');
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        _readError(body) ?? 'Unable to load weather data.',
        statusCode: response.statusCode,
      );
    }

    if (body is! Map<String, dynamic>) {
      throw const ApiException('Invalid weather response.');
    }

    final current = body['current'];
    if (current is! Map<String, dynamic>) {
      throw const ApiException('Current weather data is missing.');
    }

    final temperature = _readDouble(current['temperature_2m']);
    final humidity = _readInt(current['relative_humidity_2m']);
    final windSpeed = _readDouble(current['wind_speed_10m']);
    final weatherCode = _readInt(current['weather_code']);
    final isDay = _readInt(current['is_day']) == 1;
    if (temperature == null ||
        humidity == null ||
        windSpeed == null ||
        weatherCode == null) {
      throw const ApiException('Incomplete weather data received.');
    }

    final descriptor = _mapWeatherCode(weatherCode, isDay: isDay);
    _debugLog(
      'WEATHER mapped forecast: city="${location.city}", temp=${temperature.round()}C, '
      'humidity=$humidity%, wind=${windSpeed.round()}km/h, code=$weatherCode, '
      'condition="${descriptor.condition}", icon="${descriptor.iconCode}"',
    );
    return WeatherData(
      city: location.city,
      temperatureCelsius: temperature.round(),
      humidityPercent: humidity,
      windSpeedKmh: windSpeed.round(),
      condition: descriptor.condition,
      iconCode: descriptor.iconCode,
    );
  }

  dynamic _decodeJson(String rawBody) {
    if (rawBody.trim().isEmpty) {
      return null;
    }
    try {
      return jsonDecode(rawBody);
    } catch (_) {
      return null;
    }
  }

  String? _readError(dynamic body) {
    if (body is! Map<String, dynamic>) {
      return null;
    }
    final message = body['reason'] ?? body['message'] ?? body['error'];
    final text = message?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }

  double? _readDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '');
  }

  int? _readInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '');
  }

  _WeatherDescriptor _mapWeatherCode(int code, {required bool isDay}) {
    switch (code) {
      case 0:
        return _WeatherDescriptor(
          condition: 'Clear Sky',
          iconCode: isDay ? 'sunny' : 'night',
        );
      case 1:
      case 2:
        return _WeatherDescriptor(
          condition: 'Partly Cloudy',
          iconCode: 'partly_cloudy',
        );
      case 3:
        return const _WeatherDescriptor(
          condition: 'Cloudy',
          iconCode: 'cloud',
        );
      case 45:
      case 48:
        return const _WeatherDescriptor(
          condition: 'Foggy',
          iconCode: 'cloud',
        );
      case 51:
      case 53:
      case 55:
      case 56:
      case 57:
      case 61:
      case 63:
      case 65:
      case 66:
      case 67:
      case 80:
      case 81:
      case 82:
        return const _WeatherDescriptor(
          condition: 'Rainy',
          iconCode: 'rain',
        );
      case 71:
      case 73:
      case 75:
      case 77:
      case 85:
      case 86:
        return const _WeatherDescriptor(
          condition: 'Snow',
          iconCode: 'cloud',
        );
      case 95:
      case 96:
      case 99:
        return const _WeatherDescriptor(
          condition: 'Thunderstorm',
          iconCode: 'rain',
        );
      default:
        return const _WeatherDescriptor(
          condition: 'Weather',
          iconCode: 'partly_cloudy',
        );
    }
  }

  void _debugLog(String message) {
    if (kReleaseMode) {
      return;
    }
    debugPrint('WMS.WEATHER $message');
  }

  String _pretty(dynamic body) {
    if (body == null) {
      return '<empty>';
    }
    try {
      const encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(body);
    } catch (_) {
      return body.toString();
    }
  }
}

class _WeatherLocation {
  const _WeatherLocation({
    required this.city,
    required this.latitude,
    required this.longitude,
  });

  final String city;
  final double latitude;
  final double longitude;
}

class _PincodeInfo {
  const _PincodeInfo({
    required this.placeName,
    required this.district,
    required this.state,
  });

  final String placeName;
  final String district;
  final String state;
}

class _WeatherDescriptor {
  const _WeatherDescriptor({required this.condition, required this.iconCode});

  final String condition;
  final String iconCode;
}
