class User {
  final String publicKey;
  final String userType;
  final String name;
  final String contact;

  User({
    required this.publicKey,
    required this.userType,
    required this.name,
    required this.contact,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      publicKey: json['publicKey'],
      userType: json['userType'],
      name: json['name'],
      contact: json['contact'],
    );
  }
}
