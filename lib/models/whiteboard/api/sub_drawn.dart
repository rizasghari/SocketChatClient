import 'drawing_paint.dart';

import '../api/point.dart';

class SubDrawn {
  int? id;
  final int drawnId;
  final List<Point> points;
  final DrawingPaint paint;

  SubDrawn(
      {this.id,
      required this.drawnId,
      required this.points,
      required this.paint});

  factory SubDrawn.fromJson(Map<String, dynamic> json) {
    return SubDrawn(
        id: json['ID'],
        drawnId: json['drawn_id'],
        points: json['points'],
        paint: DrawingPaint.fromJson(json['paint']));
  }

  Map<String, dynamic> toMap() {
    return {
      'ID': id,
      'drawn_id': drawnId,
      'points': points,
      'paint': paint.toMap()
    };
  }

  @override
  String toString() {
    return 'SubDrawn{id: $id, drawnId: $drawnId, points: $points.length, paint: $paint}';
  }
}
