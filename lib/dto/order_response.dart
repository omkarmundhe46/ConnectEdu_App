// This DTO is received from the payment-service (via event-service)
class OrderResponse {
  final String orderId;
  final int amount;
  final String currency;

  OrderResponse({
    required this.orderId,
    required this.amount,
    required this.currency,
  });

  factory OrderResponse.fromJson(Map<String, dynamic> json) {
    return OrderResponse(
      orderId: json['orderId'] as String,
      amount: json['amount'] as int,
      currency: json['currency'] as String,
    );
  }
}
