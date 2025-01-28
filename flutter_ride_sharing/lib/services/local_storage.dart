import 'package:shared_preferences/shared_preferences.dart';

/// Save the public key and user type to shared preferences
Future<void> savePublicKeyAndUserType(String publicKey, String userType) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('publicKey', publicKey); // Save the public key
  await prefs.setString('userType', userType);   // Save the user type (Driver or Rider)
}

/// Retrieve the public key and user type from shared preferences
Future<Map<String, String?>> getPublicKeyAndUserType() async {
  final prefs = await SharedPreferences.getInstance();
  return {
    'publicKey': prefs.getString('publicKey'),
    'userType': prefs.getString('userType'),
  };
}
