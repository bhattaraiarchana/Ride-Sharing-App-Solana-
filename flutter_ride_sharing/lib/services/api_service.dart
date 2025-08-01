import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl; // Base URL for the API

  ApiService({required this.baseUrl});

  /// Refactored POST request method (with headers and body as named parameters)
  Future<dynamic> post(String endpoint, {Map<String, String>? headers, Object? body}) async {
    final uri = Uri.parse(baseUrl).resolve(endpoint); // Properly handle URL paths
    final response = await http.post(
      uri,
      headers: headers ?? {'Content-Type': 'application/json'}, // Default header if none provided
      body: body != null ? jsonEncode(body) : null, // Convert body to JSON if it exists
    );
    return _processResponse(response);
  }

  /// New POST request method (with headers and body as named parameters)
  Future<http.Response> postWithHeadersAndBody(String endpoint, {Map<String, String>? headers, Object? body}) async {
    final uri = Uri.parse(baseUrl).resolve(endpoint); // Resolve URL path
    final response = await http.post(
      uri,
      headers: headers ?? {'Content-Type': 'application/json'},
      body: body != null ? jsonEncode(body) : null, // Convert body to JSON if it exists
    );
    return response;
  }

  /// Existing GET request method
  Future<dynamic> get(String endpoint) async {
    final uri = Uri.parse(baseUrl).resolve(endpoint); // Properly handle URL paths
    final response = await http.get(uri);
    return _processResponse(response);
  }

  /// Process the API response
  dynamic _processResponse(http.Response response) {
    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception(
        "Error: ${response.statusCode}\nResponse: ${response.body}",
      );
    }
  }
}
