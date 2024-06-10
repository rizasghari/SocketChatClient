class Message {
  final int id;
  final String content;
  final int conversationId;
  final int senderId;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? seenAt;
  final DateTime? deletedAt;

  Message({
    required this.id,
    required this.content,
    required this.conversationId,
    required this.senderId,
    required this.createdAt,
    this.updatedAt,
    this.seenAt,
    this.deletedAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['ID'],
      content: json['content'],
      conversationId: json['conversation_id'],
      senderId: json['sender_id'],
      createdAt: DateTime.parse(json['CreatedAt']),
      updatedAt: json['UpdatedAt'] != null ? DateTime.parse(json['UpdatedAt']) : null,
      seenAt: json['seen_at'] != null ? DateTime.parse(json['seen_at']) : null,
      deletedAt: json['DeletedAt'] != null ? DateTime.parse(json['DeletedAt']) : null,
    );
  }
}
