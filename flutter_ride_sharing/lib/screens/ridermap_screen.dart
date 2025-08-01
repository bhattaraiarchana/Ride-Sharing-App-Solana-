import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart'; // Import the API service
import '../services/local_storage.dart'; // Import the local_storage.dart file

class RiderMapScreen extends StatefulWidget {
  final ApiService apiService;  // Accept ApiService in the constructor

  const RiderMapScreen({Key? key, required this.apiService}) : super(key: key);

  @override
  _RiderMapScreenState createState() => _RiderMapScreenState();
}

class _RiderMapScreenState extends State<RiderMapScreen> {
  final MapController _mapController = MapController();
  LatLng _currentLocation = LatLng(27.7172, 85.3240); // Default Kathmandu location
  TextEditingController _pickupController = TextEditingController();
  TextEditingController _destinationController = TextEditingController();
  List<String> _destinationSuggestions = [];
  List<LatLng> _routeCoordinates = [];
  String? _riderPublicKey; // Rider's public key
  final String backendUrl = "http://localhost:3000/"; // Backend URL
  bool _isRideCreated = false; // Flag to check if ride is created

  @override
  void initState() {
    super.initState();
    _loadPublicKey(); // Load the rider's public key dynamically
    _getCurrentLocation();
  }

  Future<void> _loadPublicKey() async {
    final data = await getPublicKeyAndUserType();
    if (data['userType'] == 'Rider') {
      setState(() {
        _riderPublicKey = data['publicKey'];
      });
    } else {
      Navigator.of(context).pushReplacementNamed('/driver-map'); // Redirect if not a rider
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _currentLocation = LatLng(position.latitude, position.longitude);
      final response = await http.get(
          Uri.parse(
              "https://nominatim.openstreetmap.org/reverse?lat=${position.latitude}&lon=${position.longitude}&format=json"));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _pickupController.text = data['display_name'] ?? "Unknown location";
        });
      }
      _mapController.move(_currentLocation, 14.0); // Move map to current location
    } catch (e) {
      print("Error fetching location: $e");
    }
  }

  Future<void> _searchSuggestions(String query) async {
    if (query.isEmpty) {
      setState(() {
        _destinationSuggestions = [];
      });
      return;
    }

    try {
      final response = await http.get(
        Uri.parse(
            "https://nominatim.openstreetmap.org/search?q=$query&format=json&addressdetails=1&limit=5"),
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        setState(() {
          _destinationSuggestions =
              data.map((item) => item['display_name'] as String).toList();
        });
      }
    } catch (e) {
      print("Error fetching suggestions: $e");
    }
  }

  Future<void> _fetchRoute(String destination) async {
    try {
      final geocodeResponse = await widget.apiService.get(
        "https://nominatim.openstreetmap.org/search?q=$destination&format=json&limit=1", // Directly pass the URL
      );

      if (geocodeResponse.statusCode == 200) {
        final List geocodeData = jsonDecode(geocodeResponse.body);
        if (geocodeData.isEmpty) {
          throw Exception("Destination not found");
        }

        final destLat = double.parse(geocodeData[0]['lat']);
        final destLon = double.parse(geocodeData[0]['lon']);

        final routeResponse = await widget.apiService.get(
          "https://router.project-osrm.org/route/v1/driving/${_currentLocation.longitude},${_currentLocation.latitude};$destLon,$destLat?overview=full&geometries=geojson", // Directly pass the URL
        );

        if (routeResponse.statusCode == 200) {
          final data = jsonDecode(routeResponse.body);
          final List coordinates = data['routes'][0]['geometry']['coordinates'];
          setState(() {
            _routeCoordinates = coordinates
                .map((coord) => LatLng(coord[1], coord[0]))
                .toList();
          });
        }
      }
    } catch (e) {
      print("Error fetching route: $e");
    }
  }

  Future<void> _createRide(LatLng pickup, LatLng drop, DateTime startTime, DateTime endTime) async {
    if (_riderPublicKey == null) {
      print("Rider public key is not loaded.");
      return;
    }

    try {
      final response = await widget.apiService.post(
        '/create-ride',
        headers: {'Content-Type': 'application/json'},
        body: {
          "riderPublicKey": _riderPublicKey, // Use dynamic public key
          "pickup": {"lat": pickup.latitude, "lng": pickup.longitude},
          "drop": {"lat": drop.latitude, "lng": drop.longitude},
          "startTime": startTime.toIso8601String(),
          "endTime": endTime.toIso8601String(),
        },
      );

      if (response.statusCode == 201) {
        setState(() {
          _isRideCreated = true; // Set flag to show success message
        });
      } else {
        print("Failed to create ride: ${response.body}");
      }
    } catch (e) {
      print("Error creating ride: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Rider Map"),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                TextField(
                  controller: _pickupController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: "Pickup Location",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _destinationController,
                  onChanged: (query) => _searchSuggestions(query),
                  decoration: const InputDecoration(
                    labelText: "Enter Destination",
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          if (_destinationSuggestions.isNotEmpty)
            Expanded(
              child: ListView.builder(
                itemCount: _destinationSuggestions.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(_destinationSuggestions[index]),
                    onTap: () async {
                      _destinationController.text = _destinationSuggestions[index];
                      _destinationSuggestions = []; // Clear suggestions
                      await _fetchRoute(_destinationController.text);
                    },
                  );
                },
              ),
            ),
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
                        Icons.location_pin,
                        color: Colors.blue,
                        size: 40,
                      ),
                    ),
                  ],
                ),
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routeCoordinates,
                      strokeWidth: 4.0,
                      color: Colors.red,
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_isRideCreated)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                "Ride Created Successfully!",
                style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: () async {
                await _createRide(
                  _currentLocation,
                  _routeCoordinates.isNotEmpty ? _routeCoordinates.last : _currentLocation,
                  DateTime.now(),
                  DateTime.now().add(const Duration(minutes: 30)),
                );
              },
              child: const Text("Create Ride"),
            ),
          ),
        ],
      ),
    );
  }
}
