import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthProvider extends ChangeNotifier {
  bool _isAuthenticated = false; // Tracks if the user is logged in
  String _userType = ""; // Tracks user type: "Driver" or "Rider"
  String? _token; // Stores the authentication token

  final String backendUrl = "http://localhost:3000"; // Backend URL

  bool get isAuthenticated => _isAuthenticated; // Getter for authentication status
  String get userType => _userType; // Getter for user type
  String? get token => _token; // Getter for token

  // Login logic with backend
  Future<void> login(String usernameOrNumber, String password) async {
    try {
      final url = Uri.parse("${backendUrl}login");
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "username": usernameOrNumber,
          "password": password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _isAuthenticated = true;
        _userType = data['userType'];
        _token = data['token'];

        // Save token and user data to local storage
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', _token!);
        await prefs.setString('userType', _userType);

        notifyListeners(); // Notify listeners of changes
      } else {
        throw Exception("Login failed: ${response.body}");
      }
    } catch (e) {
      _isAuthenticated = false;
      _userType = "";
      _token = null;
      notifyListeners();
      rethrow;
    }
  }

  // Logout logic
  Future<void> logout() async {
    _isAuthenticated = false;
    _userType = "";
    _token = null;

    // Clear local storage
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    notifyListeners(); // Notify listeners of changes
  }

  // Check if user is already authenticated
  Future<void> checkAuthStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final storedToken = prefs.getString('jwt_token');
    final storedUserType = prefs.getString('userType');

    if (storedToken != null && storedUserType != null) {
      _isAuthenticated = true;
      _userType = storedUserType;
      _token = storedToken;
    } else {
      _isAuthenticated = false;
      _userType = "";
      _token = null;
    }

    notifyListeners(); // Notify listeners of changes
  }
}
