import 'whiteboard_payload.dart';

class WhiteboardEvent {
  String event;
  WhiteboardPayload payload;

  WhiteboardEvent({required this.event, required this.payload});

  factory WhiteboardEvent.fromJson(Map<String, dynamic> json) {
    return WhiteboardEvent(
      event: json['event'],
      payload: WhiteboardPayload.fromJson(json['payload']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'event': event,
      'payload': payload.toMap(),
    };
  }
}
