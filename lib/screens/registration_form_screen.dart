import 'package:connectedu_app/bloc/event_detail_bloc.dart';
import 'package:connectedu_app/bloc/event_detail_event.dart';
import 'package:connectedu_app/models/event.dart';
import 'package:connectedu_app/models/user.dart';
import 'package:connectedu_app/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:connectedu_app/dto/registration_request_dto.dart';
import 'package:connectedu_app/dto/order_response.dart';
import 'package:connectedu_app/dto/payment_verification_request.dart';
import 'package:flutter/foundation.dart'; // For debugPrint

// TODO: Add this import when you add the Razorpay package
// import 'package:razorpay_flutter/razorpay_flutter.dart';

class RegistrationFormScreen extends StatefulWidget {
  final Event event;
  final User currentUser;

  const RegistrationFormScreen({
    super.key,
    required this.event,
    required this.currentUser,
  });

  @override
  State<RegistrationFormScreen> createState() => _RegistrationFormScreenState();
}

class _RegistrationFormScreenState extends State<RegistrationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _collegeController = TextEditingController();
  final _mobileController = TextEditingController();
  final _addressController = TextEditingController();

  bool _isLoading = false;

  // TODO: Uncomment these when you add the Razorpay package
  // late Razorpay _razorpay;

  @override
  void initState() {
    super.initState();
    // TODO: Initialize Razorpay
    // _razorpay = Razorpay();
    // _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    // _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    // _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _collegeController.dispose();
    _mobileController.dispose();
    _addressController.dispose();
    // _razorpay.clear(); // Clear Razorpay listeners
    super.dispose();
  }

  // --- Placeholder for Razorpay success handler ---
  // void _handlePaymentSuccess(PaymentSuccessResponse response) {
  //   debugPrint('Payment Successful: ${response.paymentId}');
  //   _verifyPaymentOnBackend(
  //     response.orderId!,
  //     response.paymentId!,
  //     response.signature!,
  //     // Pass the registration data that was collected before payment
  //   );
  // }

  // --- Placeholder for Razorpay error handler ---
  // void _handlePaymentError(PaymentFailureResponse response) {
  //    debugPrint('Payment Error: ${response.code} - ${response.message}');
  //    if (mounted) {
  //      setState(() => _isLoading = false);
  //      ScaffoldMessenger.of(context).showSnackBar(
  //        SnackBar(content: Text('Payment Failed: ${response.message}'), backgroundColor: Colors.red),
  //      );
  //    }
  // }

  // void _handleExternalWallet(ExternalWalletResponse response) {
  //    debugPrint('External Wallet: ${response.walletName}');
  // }

  Future<void> _submitRegistration() async {
    if (!_formKey.currentState!.validate()) {
      return; // Form is invalid
    }

    setState(() => _isLoading = true);

    // Create the DTO with the form data
    final registrationData = RegistrationRequestDto(
      userId: widget.currentUser.id,
      college: _collegeController.text,
      mobileNumber: _mobileController.text,
      address: _addressController.text,
      amount: 10000, // TODO: Replace with event.price from backend
    );

    final apiService = context.read<ApiService>();

    try {
      // 1. Create the payment order on your backend
      debugPrint('Creating payment order...');
      final orderResponse = await apiService.dio.post(
        '/api/clubs/${widget.event.clubId}/events/${widget.event.id}/register',
        data: registrationData.toJson(),
      );

      final order = OrderResponse.fromJson(orderResponse.data);
      debugPrint('Order created: ${order.orderId}');

      // 2. Open the Razorpay checkout
      // TODO: Replace this MOCK with real Razorpay logic
      _openRazorpayCheckout_Mock(order, registrationData);

    } catch (e) {
      debugPrint('Error starting registration: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // --- This is where Razorpay checkout is called ---
  void _openRazorpayCheckout_Mock(OrderResponse order, RegistrationRequestDto regData) {
    // --- THIS IS A MOCKUP for testing without the Razorpay SDK ---
    debugPrint('Opening Razorpay Checkout (MOCK)');

    // Simulate a successful payment for testing
    String mockPaymentId = 'pay_mock_${DateTime.now().millisecondsSinceEpoch}';
    String mockSignature = 'mock_signature'; // This will fail verification if you haven't bypassed it

    _verifyPaymentOnBackend(
        order.orderId,
        mockPaymentId,
        mockSignature,
        RegistrationData( // Create the DTO for verification
          userId: regData.userId,
          eventId: widget.event.id,
          college: regData.college,
          mobileNumber: regData.mobileNumber,
          address: regData.address,
        )
    );
  }

  // --- This verifies the payment with your backend ---
  Future<void> _verifyPaymentOnBackend(String orderId, String paymentId, String signature, RegistrationData regData) async {
    debugPrint('Verifying payment with backend...');
    final apiService = context.read<ApiService>();

    final verificationRequest = PaymentVerificationRequest(
      razorpayOrderId: orderId,
      razorpayPaymentId: paymentId,
      razorpaySignature: signature,
      registrationData: regData,
    );

    try {
      final response = await apiService.dio.post(
        '/api/payments/verify',
        data: verificationRequest.toJson(),
      );

      if (response.statusCode == 200 && mounted) {
        debugPrint('Verification successful!');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration Successful!'), backgroundColor: Colors.green),
        );

        // Tell the EventDetailsBloc to refresh its state
        context.read<EventDetailBloc>().add(RefreshDetails());

        // Pop back to the event details screen
        Navigator.of(context).pop();
      } else {
        throw Exception('Payment verification failed: ${response.statusMessage}');
      }
    } catch (e) {
      debugPrint('Error verifying payment: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Verification Error: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Register for ${widget.event.name}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Please fill in your details to register.',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 24),
              // Form fields
              TextFormField(
                controller: _collegeController,
                decoration: const InputDecoration(
                  labelText: 'College Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.school_outlined),
                ),
                validator: (value) => (value == null || value.isEmpty) ? 'Please enter your college name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _mobileController,
                decoration: const InputDecoration(
                  labelText: 'Mobile Number',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter your mobile number';
                  if (value.length != 10) return 'Must be 10 digits';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.home_outlined),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
                validator: (value) => (value == null || value.isEmpty) ? 'Please enter your address' : null,
              ),
              const SizedBox(height: 32),
              // Submit Button
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                ElevatedButton(
                  onPressed: _submitRegistration,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Proceed to Pay (₹100.00)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)), // TODO: Use dynamic price
                ),
            ],
          ),
        ),
      ),
    );
  }
}

