import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'registration_screen.dart';
import '../services/api_service.dart'; // Import ApiService

class HomeScreen extends StatelessWidget {
  final ApiService apiService; // Accept ApiService

  // Constructor to accept apiService
  const HomeScreen({Key? key, required this.apiService}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Ride Sharing")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LoginScreen(apiService: apiService), // Pass apiService to LoginScreen
                  ),
                );
              },
              child: Text("Login"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RegistrationScreen(apiService: apiService), // Pass apiService to RegisterScreen
                  ),
                );
              },
              child: Text("Register"),
            ),
          ],
        ),
      ),
    );
  }
}
