import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'screens/drivermap_screen.dart'; // Driver Map Screen
import 'screens/ridermap_screen.dart'; // Rider Map Screen
import 'screens/login_screen.dart'; // Login Screen
import 'screens/registration_screen.dart'; // Registration Screen

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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
          '/login': (context) => LoginScreen(), // Login Screen Route
          '/register': (context) => RegistrationScreen(), // Registration Screen Route
          '/driverMap': (context) => DriverMapScreen(), // Driver Map Route
          '/riderMap': (context) => RiderMapScreen(), // Rider Map Route
        },
      ),
    );
  }
}
