import 'package:connectedu_app/repositories/auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_otp_text_field/flutter_otp_text_field.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final PageController _pageController = PageController();
  final _emailController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String _otp = "";
  bool _isLoading = false;
  // Unused: int _currentStep = 0;

  @override
  void dispose() {
    _pageController.dispose();
    _emailController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Step 1: Send OTP
  Future<void> _sendOtp() async {
    if (_emailController.text.isEmpty || !_emailController.text.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid email.')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      await context.read<AuthRepository>().requestPasswordReset(_emailController.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Code sent! Check your email.'), backgroundColor: Colors.green));
        _nextPage(); // Go to OTP step
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString().replaceFirst("Exception: ", "")}'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Step 2: Verify OTP (Local Check)
  Future<void> _verifyOtp() async {
    if (_otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter the full 6-digit code.')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Call the backend to verify BEFORE moving to the next page
      await context.read<AuthRepository>().verifyResetOtp(
        email: _emailController.text.trim(),
        otp: _otp,
      );

      // If successful (no exception thrown), move to next page
      _nextPage();

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString().replaceFirst("Exception: ", "")}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Step 3: Reset Password
  Future<void> _submitReset() async {
    if (_newPasswordController.text.isEmpty || _newPasswordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password must be at least 6 characters.')));
      return;
    }
    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords do not match.')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      await context.read<AuthRepository>().resetPassword(
        email: _emailController.text.trim(),
        otp: _otp,
        newPassword: _newPasswordController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password reset successful! Please login.'), backgroundColor: Colors.green));
        Navigator.pop(context); // Go back to Login Screen
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString().replaceFirst("Exception: ", "")}'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _nextPage() {
    _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    // setState(() => _currentStep++);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Reset Password")),
      body: SafeArea(
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(), // Disable swiping
          children: [
            _buildEmailStep(),
            _buildOtpStep(),
            _buildNewPasswordStep(),
          ],
        ),
      ),
    );
  }

  // --- Step 1 UI ---
  Widget _buildEmailStep() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("Forgot Password?", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          const Text("Enter your email address to receive a verification code.", textAlign: TextAlign.center),
          const SizedBox(height: 32),
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(labelText: "Email", prefixIcon: Icon(Icons.email_outlined)),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 32),
          _isLoading
              ? const CircularProgressIndicator()
              : ElevatedButton(
            onPressed: _sendOtp,
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16)),
            child: const Text("Send Code"),
          ),
        ],
      ),
    );
  }

  // --- Step 2 UI ---
  Widget _buildOtpStep() {
    final theme = Theme.of(context);

    final double screenWidth = MediaQuery.of(context).size.width;
    final double outerPadding = 24.0 * 2;
    final double perGap = 10.0;
    final double totalGap = perGap * (6 - 1);

    final double available = screenWidth - outerPadding - totalGap;

    final double fieldWidth = (available / 6).clamp(40.0, 64.0);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("Verify Email", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Text("Enter the code sent to ${_emailController.text}", textAlign: TextAlign.center),
          const SizedBox(height: 32),

          OtpTextField(
            numberOfFields: 6,
            fieldWidth: fieldWidth,
            showFieldAsBox: true,
            borderColor: theme.colorScheme.primary,
            focusedBorderColor: theme.colorScheme.primary,

            textStyle: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.brightness == Brightness.dark ? Colors.white : Colors.black,
            ),

            onSubmit: (code) {
              _otp = code;
            },
            onCodeChanged: (code) {
              _otp = code;
            },
          ),

          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _verifyOtp,
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16)),
            child: const Text("Verify"),
          ),
        ],
      ),
    );
  }

  // --- Step 3 UI ---
  Widget _buildNewPasswordStep() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("New Password", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          const Text("Create a new, strong password.", textAlign: TextAlign.center),
          const SizedBox(height: 32),
          TextField(
            controller: _newPasswordController,
            obscureText: true,
            decoration: const InputDecoration(labelText: "New Password", prefixIcon: Icon(Icons.lock_outline)),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _confirmPasswordController,
            obscureText: true,
            decoration: const InputDecoration(labelText: "Confirm Password", prefixIcon: Icon(Icons.lock_outline)),
          ),
          const SizedBox(height: 32),
          _isLoading
              ? const CircularProgressIndicator()
              : ElevatedButton(
            onPressed: _submitReset,
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16)),
            child: const Text("Reset Password"),
          ),
        ],
      ),
    );
  }
}