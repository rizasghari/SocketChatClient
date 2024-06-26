import '../api/point.dart';

class WhiteboardSocketEventPayload {
  int whiteboardId;
  int drawerUserId;
  List<Point>? points;

  WhiteboardSocketEventPayload({required this.whiteboardId, required this.drawerUserId, this.points});

  factory WhiteboardSocketEventPayload.fromJson(Map<String, dynamic> json) {
    return WhiteboardSocketEventPayload(
      whiteboardId: json['whiteboard_id'],
      drawerUserId: json['drawer_user_id'],
      points: json['points'] != null
          ? (json['points'] as List).map((i) => Point.fromJson(i)).toList()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'whiteboard_id': whiteboardId,
      'drawer_user_id': drawerUserId,
      'points': points
    };
  }
}
