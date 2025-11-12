class ChatMessage {
  final int id;
  final String content;
  final String? fileUrl;
  final String messageType; // "TEXT", "IMAGE", "FILE"
  final int userId;
  final String userName;
  final DateTime sentAt;

  ChatMessage({
    required this.id,
    required this.content,
    this.fileUrl,
    required this.messageType,
    required this.userId,
    required this.userName,
    required this.sentAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      content: json['content'] ?? '',
      fileUrl: json['fileUrl'],
      messageType: json['messageType'],
      userId: json['userId'],
      userName: json['userName'] ?? 'Unknown User',
      sentAt: DateTime.parse(json['sentAt']),
    );
  }
}