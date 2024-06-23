import 'message.dart';
import 'user.dart';

class Conversation {
  final int id;
  final String type;
  final List<User> members;
  final Message? lastMessage;
  final int? unread;

  Conversation({
    required this.id,
    required this.type,
    required this.members,
    this.lastMessage,
    this.unread
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    var membersJson = json['members'] as List;
    List<User> membersList = membersJson.map((i) => User.fromJson(i)).toList();

    return Conversation(
      id: json['id'],
      type: json['type'],
      members: membersList,
      lastMessage: json['last_message'] != null
          ? Message.fromJson(json['last_message'])
          : null,
      unread: json['unread'],
    );
  }
}
