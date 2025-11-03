class NotificationLog {
  final int id;
  final String subject;
  final String body; // This contains the HTML content
  final DateTime createdAt;

  NotificationLog({
    required this.id,
    required this.subject,
    required this.body,
    required this.createdAt,
  });

  factory NotificationLog.fromJson(Map<String, dynamic> json) {
    return NotificationLog(
      id: json['id'],
      subject: json['subject'],
      body: json['body'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}