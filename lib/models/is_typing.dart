class IsTyping {
  final bool typingStatus;
  final int userId;

  IsTyping({
    required this.typingStatus,
    required this.userId,
  });

  Map<String, dynamic> toMap() {
    return {
      'typing_status': typingStatus,
      'user_id': userId,
    };
  }

  factory IsTyping.fromJson(Map<String, dynamic> json) {
    return IsTyping(
      typingStatus: json['typing_status'],
      userId: json['user_id'],
    );
  }
}