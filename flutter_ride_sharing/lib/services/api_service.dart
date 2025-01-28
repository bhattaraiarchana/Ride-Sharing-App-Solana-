import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl; // Base URL for the API

  ApiService({required this.baseUrl});

  /// POST request method
  Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    final uri = Uri.parse(baseUrl).resolve(endpoint); // Properly handle URL paths
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    );
    return _processResponse(response);
  }

  /// GET request method
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
