import 'package:flutter/material.dart';
import 'package:flutter_ride_sharing/models/ride_model.dart';
import 'package:flutter_ride_sharing/services/api_service.dart';

class RideProvider extends ChangeNotifier {
  List<Ride> _rides = [];

  List<Ride> get rides => _rides;

  Future<void> fetchRides() async {
    try {
      final apiService = ApiService(baseUrl: "http://localhost:3000");
      final response = await apiService.get('/rides');
      _rides = (response as List).map((ride) => Ride.fromJson(ride)).toList();
      notifyListeners();
    } catch (error) {
      throw error;
    }
  }
}
