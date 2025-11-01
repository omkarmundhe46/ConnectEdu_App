// This DTO is sent from Flutter to the event-service
class RegistrationRequestDto {
  final int userId;
  final String college;
  final String mobileNumber;
  final String address;
  final int amount; // Amount in paisa

  RegistrationRequestDto({
    required this.userId,
    required this.college,
    required this.mobileNumber,
    required this.address,
    required this.amount,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'college': college,
      'mobileNumber': mobileNumber,
      'address': address,
      'amount': amount,
    };
  }
}
