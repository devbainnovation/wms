class ApiResponse {
  const ApiResponse({
    required this.statusCode,
    required this.data,
    required this.headers,
  });

  final int statusCode;
  final dynamic data;
  final Map<String, String> headers;

  bool get isSuccess => statusCode >= 200 && statusCode < 300;

  Map<String, dynamic>? get dataAsMap {
    final value = data;
    if (value is Map<String, dynamic>) {
      return value;
    }
    return null;
  }
}
