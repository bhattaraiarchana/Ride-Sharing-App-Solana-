import 'package:flutter/material.dart';
import '../services/api_service.dart'; // Import ApiService
import '../services/local_storage.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({Key? key}) : super(key: key);

  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _bikeNumberController = TextEditingController();
  final TextEditingController _licenseNumberController = TextEditingController();
  String userType = 'Rider'; // Default user type
  final ApiService apiService = ApiService(baseUrl: "http://localhost:3000"); // Base URL for backend

  /// Register User
  Future<void> _register() async {
    final name = _nameController.text.trim();
    final contact = _contactController.text.trim();
    final password = _passwordController.text.trim();
    final bikeNumber = _bikeNumberController.text.trim();
    final licenseNumber = _licenseNumberController.text.trim();

    // Validate form fields
    if (name.isEmpty || contact.isEmpty || password.isEmpty) {
      _showErrorDialog('Please fill in all required fields.');
      return;
    }
    if (userType == 'Driver' && (bikeNumber.isEmpty || licenseNumber.isEmpty)) {
      _showErrorDialog('Please provide bike number and license number for drivers.');
      return;
    }

    // Prepare API request body
    final body = {
      "name": name,
      "contact": contact,
      "password": password,
      "userType": userType,
      if (userType == 'Driver') "bikeNumber": bikeNumber,
      if (userType == 'Driver') "licenseNumber": licenseNumber,
    };

    try {
      // Call the API using ApiService
      final response = await apiService.post('/register', body);
      print("Registration successful: $response");

      // Save public key and user type locally (if applicable)
      await savePublicKeyAndUserType(response['publicKey'], userType);

      // Navigate to login or home
      Navigator.pop(context); // Go back to the previous screen
    } catch (error) {
      print("Registration failed: $error");
      _showErrorDialog("Registration failed. Please try again.");
    }
  }

  /// Show error dialog
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
      appBar: AppBar(title: const Text("Register")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Register as:", style: TextStyle(fontSize: 16)),
              DropdownButton<String>(
                value: userType,
                onChanged: (String? value) {
                  setState(() {
                    userType = value!;
                  });
                },
                items: const [
                  DropdownMenuItem(value: "Rider", child: Text("Rider")),
                  DropdownMenuItem(value: "Driver", child: Text("Driver")),
                ],
              ),
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
              if (userType == 'Driver') ...[
                TextField(
                  controller: _bikeNumberController,
                  decoration: const InputDecoration(labelText: "Bike Number"),
                ),
                TextField(
                  controller: _licenseNumberController,
                  decoration: const InputDecoration(labelText: "License Number"),
                ),
              ],
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _register,
                child: const Text("Register"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
