import 'package:socket_chat_client/models/whiteboard/api/sub_drawn.dart';

class Drawn {
  final int id;
  final int whiteboardId;
  final int drawerUserId;
  List<SubDrawn>? subDrawns;

  Drawn(
      {required this.id,
      required this.whiteboardId,
      required this.drawerUserId,
      this.subDrawns});

  factory Drawn.fromJson(Map<String, dynamic> json) {
    return Drawn(
      id: json['ID'],
      whiteboardId: json['whiteboard_id'],
      drawerUserId: json['drawer_user_id'],
      subDrawns: json['sub_drawns'] != null
          ? (json['sub_drawns'] as List)
              .map((i) => SubDrawn.fromJson(i))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
        'ID': id,
        'whiteboard_id': whiteboardId,
        'drawer_user_id': drawerUserId,
        'sub_drawns': subDrawns
      };

  @override
  String toString() {
    return 'Drawn(id: $id, '
        'whiteboardId: $whiteboardId, '
        'drawerUserId: $drawerUserId, '
        'subDrawns: ${subDrawns?.length})';
  }
}
