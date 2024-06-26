import 'drawn_response.dart';

class WhiteboardResponse {
  int id;
  int conversationId;
  int creatorUserId;
  List<DrawnResponse>? drawns;

  WhiteboardResponse(
      {required this.id,
      required this.conversationId,
      required this.creatorUserId,
      this.drawns});

  factory WhiteboardResponse.fromJson(Map<String, dynamic> json) {
    return WhiteboardResponse(
      id: json['ID'],
      conversationId: json['conversation_id'],
      creatorUserId: json['creator_user_id'],
      drawns: json['drawns'] != null
          ? (json['drawns'] as List).map((i) => DrawnResponse.fromJson(i)).toList()
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
