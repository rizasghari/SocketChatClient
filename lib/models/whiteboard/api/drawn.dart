import 'package:socket_chat_client/models/whiteboard/api/point.dart';

class Drawn {
  final int? id;
  final int whiteboardId;
  final int drawerUserId;
  List<Point?>? points;

  Drawn(
      {this.id,
      required this.whiteboardId,
      required this.drawerUserId,
      this.points});

  factory Drawn.fromJson(Map<String, dynamic> json) {
    return Drawn(
      id: json['ID'],
      whiteboardId: json['whiteboard_id'],
      drawerUserId: json['drawer_user_id'],
      points: json['points'] != null
          ? (json['points'] as List).map((i) => Point.fromJson(i)).toList()
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
        'ID': id,
        'whiteboard_id': whiteboardId,
        'drawer_user_id': drawerUserId,
        'points': points
      };

  @override
  String toString() {
    return 'Drawn(id: $id, whiteboardId: $whiteboardId, drawerUserId: $drawerUserId, points: ${points?.length})';
  }
}
