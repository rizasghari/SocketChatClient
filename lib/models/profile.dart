class Profile {
  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final String? profilePhoto;

  Profile({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.profilePhoto,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      email: json['email'],
      profilePhoto: json['profile_photo'],
    );
  }
}
