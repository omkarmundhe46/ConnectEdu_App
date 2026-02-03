class ChatMessageModel {
  final String content;
  final String sender; // "USER" or "BOT"
  final DateTime timestamp;

  ChatMessageModel({
    required this.content,
    required this.sender,
    required this.timestamp,
  });

  // 1. FIXED: Named 'fromJson' to match your Repository call
  // This handles the immediate response: { "message": "..." }
  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      content: json['message'] ?? '',
      sender: 'BOT', // Immediate responses are always from the Bot
      timestamp: DateTime.now(),
    );
  }

  // 2. This handles the History list items: { "message": "...", "sender": "...", "createdAt": "..." }
  factory ChatMessageModel.fromHistoryJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      content: json['message'] ?? '',
      sender: json['sender'] ?? 'BOT',
      timestamp: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }
}