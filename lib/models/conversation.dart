class Conversation {
  final int id;
  final String type;
  final String name;
  final List<Member> members;

  Conversation({
    required this.id,
    required this.type,
    required this.name,
    required this.members,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    var membersJson = json['members'] as List;
    List<Member> membersList = membersJson.map((i) => Member.fromJson(i)).toList();

    return Conversation(
      id: json['id'],
      type: json['type'],
      name: json['name'],
      members: membersList,
    );
  }
}

class Member {
  final int id;
  final String firstName;
  final String lastName;
  final String? profilePhoto;
  final bool isOnline;
  final String? lastSeen;

  Member({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.profilePhoto,
    required this.isOnline,
    this.lastSeen,
  });

  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      id: json['id'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      profilePhoto: json['profile_photo'],
      isOnline: json['is_online'],
      lastSeen: json['last_seen'],
    );
  }
}
