import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../services/local_storage.dart'; // For SharedPreferences

class DriverMapScreen extends StatefulWidget {
  const DriverMapScreen({Key? key}) : super(key: key);

  @override
  _DriverMapScreenState createState() => _DriverMapScreenState();
}

class _DriverMapScreenState extends State<DriverMapScreen> {
  final MapController _mapController = MapController();
  LatLng _currentLocation = LatLng(27.7172, 85.3240); // Default: Kathmandu
  List<Map<String, dynamic>> _availableRides = []; // Ride requests
  Map<String, dynamic>? _currentRide; // Accepted ride details
  final String backendUrl = "http://localhost:3000/"; // Backend URL
  String? _driverPublicKey; // Driver's public key

  @override
  void initState() {
    super.initState();
    _loadPublicKey(); // Load driver's public key dynamically
    _getCurrentLocation();
    _fetchAvailableRides();
  }

  /// Load the driver's public key from local storage
  Future<void> _loadPublicKey() async {
    final data = await getPublicKeyAndUserType();
    if (data['userType'] == 'Driver') {
      setState(() {
        _driverPublicKey = data['publicKey'];
      });
    } else {
      Navigator.of(context).pushReplacementNamed('/rider-map'); // Redirect if not a driver
    }
  }

  /// Fetch the driver's current location and update it on the backend.
  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _currentLocation = LatLng(position.latitude, position.longitude);
      await _updateDriverLocation(); // Update location on the backend
      _mapController.move(_currentLocation, 14.0); // Center map
    } catch (e) {
      print("Error fetching location: $e");
    }
  }

  /// Update the driver's location on the backend.
  Future<void> _updateDriverLocation() async {
    if (_driverPublicKey == null) return;
    try {
      final url = Uri.parse("${backendUrl}update-location");
      await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "driverPublicKey": _driverPublicKey,
          "location": {"lat": _currentLocation.latitude, "lng": _currentLocation.longitude},
        }),
      );
    } catch (e) {
      print("Error updating driver location: $e");
    }
  }

  /// Fetch available ride requests from the backend.
  Future<void> _fetchAvailableRides() async {
    try {
      final url = Uri.parse("${backendUrl}get-available-rides");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List rides = jsonDecode(response.body);
        final enrichedRides = await Future.wait(rides.map((ride) async {
          final rideMap = Map<String, dynamic>.from(ride);
          final pickupName = await _reverseGeocode(rideMap['pickup']['lat'], rideMap['pickup']['lng']);
          final dropName = await _reverseGeocode(rideMap['drop']['lat'], rideMap['drop']['lng']);
          return {...rideMap, 'pickupName': pickupName, 'dropName': dropName};
        }).toList());

        setState(() {
          _availableRides = enrichedRides.cast<Map<String, dynamic>>();
        });
      }
    } catch (e) {
      print("Error fetching available rides: $e");
    }
  }

  /// Perform reverse geocoding to get place names from coordinates
  Future<String> _reverseGeocode(double lat, double lng) async {
    try {
      final url = Uri.parse(
          "https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lng&format=json");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['display_name'] ?? "Unknown location";
      } else {
        return "Unknown location";
      }
    } catch (e) {
      print("Error reverse geocoding: $e");
      return "Unknown location";
    }
  }

  /// Accept a ride request.
  Future<void> _acceptRide(String rideId) async {
    if (_driverPublicKey == null) return;
    try {
      final url = Uri.parse("${backendUrl}accept-ride");
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"rideId": rideId, "driverPublicKey": _driverPublicKey}),
      );

      if (response.statusCode == 200) {
        setState(() {
          _currentRide = _availableRides.firstWhere((ride) => ride['rideId'] == rideId);
          _availableRides.removeWhere((ride) => ride['rideId'] == rideId);
        });
      }
    } catch (e) {
      print("Error accepting ride: $e");
    }
  }

  /// Complete the current ride.
  Future<void> _completeRide() async {
    try {
      final url = Uri.parse("${backendUrl}complete-ride");
      await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"rideId": _currentRide!['rideId']}),
      );
      setState(() {
        _currentRide = null;
      });
    } catch (e) {
      print("Error completing ride: $e");
    }
  }

  /// Cancel the current ride.
  Future<void> _cancelRide() async {
    try {
      final url = Uri.parse("${backendUrl}cancel-ride");
      await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"rideId": _currentRide!['rideId']}),
      );
      setState(() {
        _currentRide = null;
      });
    } catch (e) {
      print("Error cancelling ride: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Driver Map"),
      ),
      body: Column(
        children: [
          // Available Rides List
          if (_currentRide == null)
            Expanded(
              flex: 1,
              child: _availableRides.isNotEmpty
                  ? ListView.builder(
                      itemCount: _availableRides.length,
                      itemBuilder: (context, index) {
                        final ride = _availableRides[index];
                        return ListTile(
                          title: Text("Pickup: ${ride['pickupName']}"),
                          subtitle: Text("Drop: ${ride['dropName']}"),
                          trailing: ElevatedButton(
                            onPressed: () => _acceptRide(ride['rideId']),
                            child: const Text("Accept"),
                          ),
                        );
                      },
                    )
                  : const Center(child: Text("No available rides")),
            ),

          // Accepted Ride Details
          if (_currentRide != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Accepted Ride Details:",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text("Pickup: ${_currentRide!['pickupName']}"),
                  Text("Drop: ${_currentRide!['dropName']}"),
                  Text("Fare: Rs. ${(int.parse(_currentRide!['fare'].toString()) * 132).toString()}"),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        onPressed: _completeRide,
                        child: const Text("Complete Ride"),
                      ),
                      ElevatedButton(
                        onPressed: _cancelRide,
                        child: const Text("Cancel Ride"),
                      ),
                    ],
                  ),
                ],
              ),
            ),

          // Map showing driver's location
          Expanded(
            flex: 2,
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                center: _currentLocation,
                zoom: 14.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                  subdomains: ['a', 'b', 'c'],
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _currentLocation,
                      builder: (ctx) => const Icon(
                        Icons.local_taxi,
                        color: Colors.green,
                        size: 40,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
