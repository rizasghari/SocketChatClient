class Seen {
  final List<int> messageIds;

  Seen({
    required this.messageIds,
  });

  Map<String, dynamic> toMap() {
    return {
      'message_ids': messageIds,
    };
  }

  factory Seen.fromJson(Map<String, dynamic> json) {
    return Seen(
      messageIds: List.from(json['message_ids']),
    );
  }
}