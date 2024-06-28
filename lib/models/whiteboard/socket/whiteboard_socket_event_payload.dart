import '../api/point.dart';

class WhiteboardSocketEventPayload {
  int id;
  int whiteboardId;
  int drawerUserId;
  List<Point?>? points;

  WhiteboardSocketEventPayload(
      {required this.id, required this.whiteboardId, required this.drawerUserId, this.points});

  factory WhiteboardSocketEventPayload.fromJson(Map<String, dynamic> json) {
    return WhiteboardSocketEventPayload(
      id: json['id'],
      whiteboardId: json['whiteboard_id'],
      drawerUserId: json['drawer_user_id'],
      points: json['points'] != null
          ? (json['points'] as List).map((i) => Point.fromJson(i)).toList()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'whiteboard_id': whiteboardId,
      'drawer_user_id': drawerUserId,
      'points': points?.map((i) => i?.toMap()).toList(),
    };
  }

  @override
  String toString() {
    return 'WhiteboardSocketEventPayload(whiteboardId: $whiteboardId, '
        'drawerUserId: $drawerUserId, points: ${points?.length})';
  }
}
