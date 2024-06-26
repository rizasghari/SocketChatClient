class WhiteboardRequest {
  int conversationId;

  WhiteboardRequest({required this.conversationId});

  factory WhiteboardRequest.fromJson(Map<String, dynamic> json) {
    return WhiteboardRequest(
      conversationId: json['conversation_id'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'conversation_id': conversationId,
    };
  }
}
