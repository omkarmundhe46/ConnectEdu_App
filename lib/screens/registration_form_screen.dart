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
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

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

  late Razorpay _razorpay;

  final String _razorpayKey = dotenv.env['RAZORPAY_KEY'] ?? 'KEY_NOT_FOUND';

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _collegeController.dispose();
    _mobileController.dispose();
    _addressController.dispose();
    _razorpay.clear();
    super.dispose();
  }

  // --- RAZORPAY HANDLERS ---
  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    debugPrint('Payment Successful: ${response.paymentId}');
    // The 'response' contains signature and paymentId. orderId comes from our state.
    // Wait, Razorpay SDK doesn't return order_id in SuccessResponse directly in all versions,
    // but we have it from our _currentOrder.

    if (_currentOrder != null && _currentRegistrationData != null) {
      _verifyPaymentOnBackend(
        _currentOrder!.orderId,
        response.paymentId!,
        response.signature!,
        _currentRegistrationData!,
      );
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    debugPrint('Payment Error: ${response.code} - ${response.message}');
    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment Failed: ${response.message}'), backgroundColor: Colors.red),
      );
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    debugPrint('External Wallet: ${response.walletName}');
    // Usually treat this as success or handle specific wallet logic
  }

  // Temp storage for data needed during verification
  OrderResponse? _currentOrder;
  RegistrationData? _currentRegistrationData;


  Future<void> _submitRegistration() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // 1. Prepare Data
    // Note: Amount isn't needed here for the DTO anymore if the backend calculates it from Event Fee,
    // but we can send 0 or the expected fee. The backend overrides it securely anyway.
    final registrationData = RegistrationRequestDto(
      userId: widget.currentUser.id,
      college: _collegeController.text,
      mobileNumber: _mobileController.text,
      address: _addressController.text,
      amount: 0, // Backend uses event.fee
    );

    // Save for later verification
    _currentRegistrationData = RegistrationData(
      userId: registrationData.userId,
      eventId: widget.event.id,
      college: registrationData.college,
      mobileNumber: registrationData.mobileNumber,
      address: registrationData.address,
    );

    final apiService = context.read<ApiService>();

    try {
      // 2. Call Backend to Create Order
      debugPrint('Creating payment order...');
      final response = await apiService.dio.post(
        '/api/clubs/${widget.event.clubId}/events/${widget.event.id}/register',
        data: registrationData.toJson(),
      );

      final order = OrderResponse.fromJson(response.data);
      _currentOrder = order;

      debugPrint('Order Created: ${order.orderId}, Amount: ${order.amount}');

      // 3. Open Razorpay Checkout
      _openRazorpayCheckout(order);

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

  void _openRazorpayCheckout(OrderResponse order) {
    var options = {
      'key': _razorpayKey,
      'amount': order.amount, // Amount in paise
      'name': 'ConnectEdu',
      'description': 'Registration for ${widget.event.name}',
      'order_id': order.orderId, // This links the payment to the order created on backend
      'prefill': {
        'contact': _mobileController.text,
        'email': widget.currentUser.email,
      },
      'external': {
        'wallets': ['paytm']
      }
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint('Error opening razorpay: $e');
    }
  }

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
        context.read<EventDetailBloc>().add(RefreshDetails());
        Navigator.of(context).pop();
      } else {
        throw Exception('Payment verification failed');
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
      appBar: AppBar(title: Text('Register for ${widget.event.name}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Please fill in your details.', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 24),
            TextFormField(
              controller: _collegeController,
              decoration: const InputDecoration(
                  labelText: 'College Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.school_outlined)
              ),
              // 1. Physically blocks numbers from being typed into the field
              inputFormatters: [
                FilteringTextInputFormatter.deny(RegExp(r'[0-9]')),
              ],
              // 2. Validates the final input (catches copy-pasted numbers or empty fields)
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Required';
                }
                if (RegExp(r'[0-9]').hasMatch(v)) {
                  return 'College name cannot contain numbers';
                }
                return null;
              },
            ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _mobileController,
                decoration: const InputDecoration(labelText: 'Mobile Number', border: OutlineInputBorder(), prefixIcon: Icon(Icons.phone_outlined)),
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) => (v == null || v.length != 10) ? 'Must be 10 digits' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Address', border: OutlineInputBorder(), prefixIcon: Icon(Icons.home_outlined)),
                maxLines: 2,
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 32),

              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                ElevatedButton(
                  onPressed: _submitRegistration,
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: Text(
                    'Pay ₹${widget.event.fee.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}