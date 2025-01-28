import 'package:flutter/material.dart';
import '../services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _contactController = TextEditingController();
  final _passwordController = TextEditingController();
  String _userType = 'Rider'; // Default user type

  void _register() async {
    try {
final apiService = ApiService(baseUrl: "http://localhost:3000/");      final response = await apiService.post('/register', {
        'name': _nameController.text.trim(),
        'contact': _contactController.text.trim(),
        'password': _passwordController.text.trim(),
        'userType': _userType,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response['message'] ?? 'Registration successful!')),
      );
      Navigator.pop(context); // Return to login
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true, // Center the title
        title: const Text("Ride Sharing"), // Title in the center
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: "Name"),
            ),
            TextField(
              controller: _contactController,
              decoration: const InputDecoration(labelText: "Contact"),
            ),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Password"),
            ),
            DropdownButton<String>(
              value: _userType,
              items: ['Driver', 'Rider'].map((String userType) {
                return DropdownMenuItem(value: userType, child: Text(userType));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _userType = value!;
                });
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _register,
              child: const Text("Register"),
            ),
          ],
        ),
      ),
    );
  }
}
