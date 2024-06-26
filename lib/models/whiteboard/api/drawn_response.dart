import 'package:socket_chat_client/models/whiteboard/api/point_response.dart';

class DrawnResponse {
  int id;
  int whiteboardId;
  int drawerUserId;
  List<PointResponse>? points;

  DrawnResponse({required this.id, required this.whiteboardId, required this.drawerUserId, this.points});

  factory DrawnResponse.fromJson(Map<String, dynamic> json) {
    return DrawnResponse(
      id: json['ID'],
      whiteboardId: json['whiteboard_id'],
      drawerUserId: json['drawer_user_id'],
      points: json['points'] != null
          ? (json['points'] as List).map((i) => PointResponse.fromJson(i)).toList()
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
    'ID': id,
    'whiteboard_id': whiteboardId,
    'drawer_user_id': drawerUserId,
    'points': points
  };

}