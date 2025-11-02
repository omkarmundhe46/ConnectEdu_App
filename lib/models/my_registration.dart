import 'package:connectedu_app/models/event.dart'; // We can re-use the Event model

class MyRegistration {
  final DateTime registeredAt;
  final String? paymentId;
  final int eventId;
  final int clubId;
  final String eventName;
  final String? eventImageUrl;
  final DateTime eventDate;
  final String eventStatus;

  MyRegistration({
    required this.registeredAt,
    this.paymentId,
    required this.eventId,
    required this.clubId,
    required this.eventName,
    this.eventImageUrl,
    required this.eventDate,
    required this.eventStatus,
  });

  factory MyRegistration.fromJson(Map<String, dynamic> json) {
    return MyRegistration(
      registeredAt: DateTime.parse(json['registeredAt']),
      paymentId: json['paymentId'],
      eventId: json['eventId'],
      clubId: json['clubId'],
      eventName: json['eventName'],
      eventImageUrl: json['eventImageUrl'],
      eventDate: DateTime.parse(json['eventDate']),
      eventStatus: json['eventStatus'],
    );
  }
}