class ObservingPayload {
  final int userId;
  final bool isOnline;
  final DateTime? lastSeenAt;
  ObservingPayload({
    required this.userId,
    required this.isOnline,
    required this.lastSeenAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'is_online': isOnline,
      'last_seen_at': lastSeenAt,
    };
  }

  factory ObservingPayload.fromJson(Map<String, dynamic> json) {
    return ObservingPayload(
      userId: json['user_id'],
      isOnline: json['is_online'],
      lastSeenAt: json['last_seen_at'] != null ? DateTime.parse(json['last_seen_at']) : null,
    );
  }
}