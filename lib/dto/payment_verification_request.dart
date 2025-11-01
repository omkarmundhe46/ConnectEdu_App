// This DTO is sent from Flutter to the payment-service to verify payment
class RegistrationData {
  final int userId;
  final int eventId;
  final String college;
  final String mobileNumber;
  final String address;

  RegistrationData({
    required this.userId,
    required this.eventId,
    required this.college,
    required this.mobileNumber,
    required this.address,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'eventId': eventId,
      'college': college,
      'mobileNumber': mobileNumber,
      'address': address,
    };
  }
}

class PaymentVerificationRequest {
  final String razorpayOrderId;
  final String razorpayPaymentId;
  final String razorpaySignature;
  final RegistrationData registrationData;

  PaymentVerificationRequest({
    required this.razorpayOrderId,
    required this.razorpayPaymentId,
    required this.razorpaySignature,
    required this.registrationData,
  });

  Map<String, dynamic> toJson() {
    return {
      'razorpayOrderId': razorpayOrderId,
      'razorpayPaymentId': razorpayPaymentId,
      'razorpaySignature': razorpaySignature,
      'registrationData': registrationData.toJson(),
    };
  }
}
