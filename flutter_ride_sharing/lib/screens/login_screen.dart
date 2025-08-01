import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart'; // Correct API service path
import 'forgotpassword_screen.dart';
import 'ridermap_screen.dart';
import 'drivermap_screen.dart';
import 'registration_screen.dart';

class LoginScreen extends StatefulWidget {
  final ApiService apiService;

  const LoginScreen({Key? key, required this.apiService}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  // Method to save publicKey and userType to SharedPreferences
  Future<void> savePublicKeyAndUserType(String publicKey, String userType) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('publicKey', publicKey);
    await prefs.setString('userType', userType);
  }

  Future<void> _login() async {
    final usernameOrNumber = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (usernameOrNumber.isEmpty || password.isEmpty) {
      _showErrorDialog('Please fill in both fields.');
      return;
    }

    try {
      final response = await widget.apiService.post('/login', body: {
        "username": usernameOrNumber,
        "password": password,
      });

      final token = response['token'];
      final userType = response['userType'];
      final publicKey = response['publicKey'] ?? '';

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('jwt_token', token);

      // Save the public key and user type locally
      await savePublicKeyAndUserType(publicKey, userType);

      if (userType == 'Rider') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => RiderMapScreen(apiService: widget.apiService),
          ),
        );
      } else if (userType == 'Driver') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => DriverMapScreen(apiService: widget.apiService),
          ),
        );
      } else {
        _showErrorDialog('Unknown user type.');
      }
    } catch (e) {
      _showErrorDialog(e.toString());
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Ride Sharing App",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: "Username or Contact",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: "Password",
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: _togglePasswordVisibility,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ForgotPasswordScreen(),
                    ),
                  );
                },
                child: const Text("Forgot Password?"),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _login,
              child: const Text("Log In"),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RegistrationScreen(apiService: widget.apiService),
                  ),
                );
              },
              child: const Text("Don't have an account? Register"),
            ),
          ],
        ),
      ),
    );
  }
}
