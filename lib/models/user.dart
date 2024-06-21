class User {
  final int id;
  final String firstName;
  final String lastName;
  String? profilePhoto;
  bool? isOnline;
  DateTime? lastSeenAt;

  User({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.profilePhoto,
    this.isOnline,
    this.lastSeenAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      profilePhoto: json['profile_photo'],
      isOnline: json['is_online'],
      lastSeenAt: json['last_seen_at'] != null
          ? DateTime.parse(json['last_seen_at'])
          : null,
    );
  }
}
