import '../api/drawing_paint.dart';
import '../api/point.dart';

class WhiteboardPayload {
  int? subDrawnId;
  int drawnId;
  int whiteboardId;
  int drawerUserId;
  DrawingPaint paint;
  List<Point> points;

  WhiteboardPayload(
      {this.subDrawnId,
      required this.whiteboardId,
      required this.drawerUserId,
      required this.drawnId,
      required this.paint,
      required this.points});

  factory WhiteboardPayload.fromJson(Map<String, dynamic> json) {
    return WhiteboardPayload(
        subDrawnId: json['ID'],
        whiteboardId: json['whiteboard_id'],
        drawerUserId: json['drawer_user_id'],
        drawnId: json['drawn_id'],
        paint: DrawingPaint.fromJson(json['paint']),
        points:
            (json['points'] as List).map((i) => Point.fromJson(i)).toList());
  }

  Map<String, dynamic> toMap() {
    return {
      'ID': subDrawnId,
      'whiteboard_id': whiteboardId,
      'drawer_user_id': drawerUserId,
      'drawn_id': drawnId,
      'paint': paint.toMap(),
      'points': points.map((i) => i.toMap()).toList(),
    };
  }

  @override
  String toString() {
    return 'WhiteboardPayload(subDrawnId: $subDrawnId, '
        'whiteboardId: $whiteboardId, '
        'drawnId: $drawnId, paint: ${paint.toString()}, '
        'drawerUserId: $drawerUserId, points: ${points.length})';
  }
}
