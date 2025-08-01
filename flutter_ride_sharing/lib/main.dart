import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'screens/drivermap_screen.dart'; // Driver Map Screen
import 'screens/ridermap_screen.dart'; // Rider Map Screen
import 'screens/login_screen.dart'; // Login Screen
import 'screens/registration_screen.dart'; // Registration Screen
import 'services/api_service.dart'; // Corrected import path to api_service.dart

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final String baseUrl = 'http://172.22.186.183:3000'; // Use this IP address for backend


  @override
  Widget build(BuildContext context) {
    final ApiService apiService = ApiService(baseUrl: baseUrl);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Ride Sharing',
        theme: ThemeData(primarySwatch: Colors.blue),
        initialRoute: '/login', // Set initial route to login
        routes: {
          '/login': (context) => LoginScreen(apiService: apiService),
          '/register': (context) => RegistrationScreen(apiService: apiService),
          '/driverMap': (context) => DriverMapScreen(apiService: apiService),
          '/riderMap': (context) => RiderMapScreen(apiService: apiService),
        },
      ),
    );
  }
}
