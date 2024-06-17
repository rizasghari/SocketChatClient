class User {
  final int id;
  final String firstName;
  final String lastName;
  String? profilePhoto;

  User({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.profilePhoto,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      profilePhoto: json['profile_photo'],
    );
  }
}
