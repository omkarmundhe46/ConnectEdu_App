import 'package:connectedu_app/repositories/auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

class VerificationScreen extends StatefulWidget {
  final String email;
  const VerificationScreen({super.key, required this.email});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  bool _isVerifying = false;
  bool _isResending = false;
  String _currentOtp = "";

  void _onVerify(BuildContext context, String otp) async {
    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter all 6 digits.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isVerifying = true);

    final authRepo = context.read<AuthRepository>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      await authRepo.verifyOtp(email: widget.email, otp: otp);

      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Verification Successful! Please log in.'),
          backgroundColor: Colors.green,
        ),
      );

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(
            'Error: ${e.toString().replaceFirst("Exception: ", "")}',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  void _onResend(BuildContext context) async {
    setState(() => _isResending = true);

    final authRepo = context.read<AuthRepository>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      await authRepo.resendOtp(email: widget.email);

      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('A new code has been sent to your email.'),
          backgroundColor: Colors.blue,
        ),
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(
            'Error: ${e.toString().replaceFirst("Exception: ", "")}',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Email Verification'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Verify your email',
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              Text(
                'A 6-digit verification code has been sent to\n${widget.email}',
                style: theme.textTheme.bodyLarge
                    ?.copyWith(color: theme.hintColor),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),

              /// 🔥 NEW OTP FIELD (Perfect UI)
              PinCodeTextField(
                appContext: context,
                length: 6,

                keyboardType: TextInputType.number,
                autoFocus: true,

                animationType: AnimationType.fade,
                animationDuration: const Duration(milliseconds: 200),

                textStyle: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),

                cursorColor: theme.colorScheme.primary,

                enableActiveFill: true,

                pinTheme: PinTheme(
                  shape: PinCodeFieldShape.box,
                  borderRadius: BorderRadius.circular(8),

                  fieldHeight: 55,
                  fieldWidth: 45,

                  activeFillColor: theme.colorScheme.surface,
                  inactiveFillColor: theme.colorScheme.surface,
                  selectedFillColor: theme.colorScheme.surface,

                  activeColor: theme.colorScheme.primary,
                  selectedColor: theme.colorScheme.primary,
                  inactiveColor: theme.colorScheme.outline,
                ),

                onChanged: (value) {
                  _currentOtp = value;
                },

                onCompleted: (value) {
                  _onVerify(context, value);
                },
              ),

              const SizedBox(height: 40),

              /// VERIFY BUTTON
              _isVerifying
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                onPressed: () {
                  _onVerify(context, _currentOtp);
                },
                style: ElevatedButton.styleFrom(
                  padding:
                  const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'VERIFY',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),

              const SizedBox(height: 24),

              /// RESEND BUTTON
              _isResending
                  ? const Center(
                child: SizedBox(
                  height: 20,
                  width: 20,
                  child:
                  CircularProgressIndicator(strokeWidth: 2),
                ),
              )
                  : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Didn't receive the code?",
                    style: TextStyle(color: theme.hintColor),
                  ),
                  TextButton(
                    onPressed: () => _onResend(context),
                    child: const Text('Resend Code'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}