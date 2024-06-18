class SocketEvent {
  final String event;
  final dynamic payload;
  final int? conversationId;

  SocketEvent({
    required this.event,
    required this.payload,
    this.conversationId,
  });

  Map<String, dynamic> toMap() {
    return {
      'event': event,
      'payload': payload,
      'conversation_id': conversationId,
    };
  }

  factory SocketEvent.fromJson(Map<String, dynamic> json) {
    return SocketEvent(
      event: json['event'],
      payload: json['payload'],
      conversationId: json['conversation_id'],
    );
  }
}

