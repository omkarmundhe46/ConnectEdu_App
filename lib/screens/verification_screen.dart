import 'package:connectedu_app/repositories/auth_repository.dart';
import 'package:connectedu_app/screens/auth_navigator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_otp_text_field/flutter_otp_text_field.dart';

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

    if (_currentOtp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter all 6 digits.'), backgroundColor: Colors.orange),
      );
      return;
    }


    setState(() {
      _isVerifying = true;
    });

    final authRepo = context.read<AuthRepository>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      await authRepo.verifyOtp(email: widget.email, otp: otp);

      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Verification Successful! Please log in.'), backgroundColor: Colors.green),
      );

      if (mounted) {
        Navigator.of(context).pop(true);
      }


    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error: ${e.toString().replaceFirst("Exception: ", "")}'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isVerifying = false;
        });
      }
    }
  }

  void _onResend(BuildContext context) async {
    setState(() {
      _isResending = true;
    });

    final authRepo = context.read<AuthRepository>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      await authRepo.resendOtp(email: widget.email);
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('A new code has been sent to your email.'), backgroundColor: Colors.blue),
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error: ${e.toString().replaceFirst("Exception: ", "")}'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final double screenWidth = MediaQuery.of(context).size.width;
    final double padding = 24.0 * 2;
    final double margin = 4.0 * 2;
    final int numberOfFields = 6;

    final double fieldWidth = (screenWidth - padding) / numberOfFields - (margin);


    return Scaffold(
      appBar: AppBar(
        title: const Text('Email Verification'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Verify your email',
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'A 6-digit verification code has been sent to\n${widget.email}',
                style: theme.textTheme.bodyLarge?.copyWith(color: theme.hintColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),


              OtpTextField(
                numberOfFields: numberOfFields,
                showFieldAsBox: true,
                fieldWidth: fieldWidth,
                margin: const EdgeInsets.symmetric(horizontal: 4.0), // Use the margin

                // Style properties are passed directly
                enabledBorderColor: theme.colorScheme.outline,
                focusedBorderColor: theme.colorScheme.primary,
                disabledBorderColor: theme.colorScheme.outline.withOpacity(0.5),
                filled: true,
                fillColor: theme.colorScheme.surfaceVariant,

                // 'styles' takes a List of TextStyles
                styles: List.generate(numberOfFields, (index) {
                  return theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  );
                }),

                onCodeChanged: (String code) {
                  _currentOtp = code;
                },
                onSubmit: (String verificationCode) {
                  _currentOtp = verificationCode;
                  _onVerify(context, verificationCode);
                },
              ),


              const SizedBox(height: 48),

              // Verify Button
              _isVerifying
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                onPressed: () {
                  _onVerify(context, _currentOtp);
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('VERIFY', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 24),

              // Resend Code Button
              _isResending
                  ? const Center(child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)))
                  : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Didn't receive the code?", style: TextStyle(color: theme.hintColor)),
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