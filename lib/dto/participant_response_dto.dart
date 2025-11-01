// This model maps to the ParticipantResponseDto from your event-service
class ParticipantResponseDto {
  final int id;
  final int userId;
  final int eventId;
  final DateTime registeredAt;

  // These fields come from the payment/registration flow
  final String college;
  final String mobileNumber;
  final String address;
  final String paymentId;

  ParticipantResponseDto({
    required this.id,
    required this.userId,
    required this.eventId,
    required this.registeredAt,
    required this.college,
    required this.mobileNumber,
    required this.address,
    required this.paymentId,
  });

  factory ParticipantResponseDto.fromJson(Map<String, dynamic> json) {
    // Handle potential nulls from the backend gracefully
    return ParticipantResponseDto(
      id: json['id'] ?? 0,
      userId: json['userId'] ?? 0,
      eventId: json['eventId'] ?? 0,
      registeredAt: DateTime.parse(json['registeredAt'] ?? DateTime.now().toIso8601String()),
      college: json['college'] ?? '',
      mobileNumber: json['mobileNumber'] ?? '',
      address: json['address'] ?? '',
      paymentId: json['paymentId'] ?? '',
    );
  }
}

