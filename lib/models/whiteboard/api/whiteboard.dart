import 'drawn.dart';

class Whiteboard {
  final int id;
  final int conversationId;
  final int creatorUserId;
  List<Drawn>? drawns;

  Whiteboard(
      {required this.id,
      required this.conversationId,
      required this.creatorUserId,
      this.drawns});

  factory Whiteboard.fromJson(Map<String, dynamic> json) {
    return Whiteboard(
      id: json['ID'],
      conversationId: json['conversation_id'],
      creatorUserId: json['creator_user_id'],
      drawns: json['drawns'] != null
          ? (json['drawns'] as List).map((i) => Drawn.fromJson(i)).toList()
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
    'ID': id,
    'conversation_id': conversationId,
    'creator_user_id': creatorUserId,
    'drawns': drawns
  };
}
