import 'whiteboard_socket_event_payload.dart';

class WhiteboardSocketEvent {
  String event;
  WhiteboardSocketEventPayload payload;

  WhiteboardSocketEvent({required this.event, required this.payload});

  factory WhiteboardSocketEvent.fromJson(Map<String, dynamic> json) {
    return WhiteboardSocketEvent(
      event: json['event'],
      payload: WhiteboardSocketEventPayload.fromJson(json['payload']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'event': event,
      'payload': payload.toMap(),
    };
  }
}
