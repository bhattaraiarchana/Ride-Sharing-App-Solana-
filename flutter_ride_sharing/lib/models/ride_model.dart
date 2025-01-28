class Ride {
  final String rideId;
  final String status;
  final double fare;
  final Map<String, double> pickup;
  final Map<String, double> drop;

  Ride({
    required this.rideId,
    required this.status,
    required this.fare,
    required this.pickup,
    required this.drop,
  });

  factory Ride.fromJson(Map<String, dynamic> json) {
    return Ride(
      rideId: json['rideId'],
      status: json['status'],
      fare: json['fare'].toDouble(),
      pickup: Map<String, double>.from(json['pickup']),
      drop: Map<String, double>.from(json['drop']),
    );
  }
}
