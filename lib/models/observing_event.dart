import 'observing_payload.dart';

class ObservingEvent {
  final String event;
  final ObservingPayload payload;

  ObservingEvent({
    required this.event,
    required this.payload,
  });

  Map<String, dynamic> toMap() {
    return {
      'event': event,
      'payload': payload.toMap(),
    };
  }

  factory ObservingEvent.fromJson(Map<String, dynamic> json) {
    return ObservingEvent(
      event: json['event'],
      payload: ObservingPayload.fromJson(json['payload']),
    );
  }
}