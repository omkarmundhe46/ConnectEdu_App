import 'package:connectedu_app/repositories/auth_repository.dart';
import 'package:connectedu_app/screens/verification_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
class SignUpScreen extends StatefulWidget {
  final VoidCallback onSignInTapped;
  const SignUpScreen({super.key, required this.onSignInTapped});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _departmentController = TextEditingController();

  bool _isLoading = false;

  void _signUp() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Passwords do not match!"), backgroundColor: Colors.red),
      );
      return;
    }
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _departmentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields!"), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Get the repository using context.read
      final authRepository = context.read<AuthRepository>();
      final userEmail = _emailController.text;

      await authRepository.register(
        name: _nameController.text,
        email: userEmail,
        password: _passwordController.text,
        department: _departmentController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Verification code sent! Please check your email."), backgroundColor: Colors.green),
        );

        // We push the VerificationScreen and wait for a result.
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VerificationScreen(email: userEmail),
          ),
        );

        // If the result is 'true', it means verification was successful.
        // We then call the callback to toggle the AuthNavigator to the LoginScreen.
        if (result == true && mounted) {
          widget.onSignInTapped();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Registration failed: ${e.toString()}"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onSignInTapped,
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Sign up',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),

                // Name, Email, Password, Confirm Password Fields...
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    hintText: 'Full name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    hintText: 'abc@email.com',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    hintText: 'Your password',
                    prefixIcon: Icon(Icons.lock_outline),
                    suffixIcon: Icon(Icons.visibility_off_outlined),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _confirmPasswordController,
                  decoration: const InputDecoration(
                    hintText: 'Confirm password',
                    prefixIcon: Icon(Icons.lock_outline),
                    suffixIcon: Icon(Icons.visibility_off_outlined),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _departmentController,
                  decoration: const InputDecoration(
                    hintText: 'Department',
                    prefixIcon: Icon(Icons.business_outlined),
                  ),
                ),

                const SizedBox(height: 24),

                // Sign Up Button
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _signUp,
                        child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('SIGN UP'),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward),
                    ],
                  ),
                      ),
                const SizedBox(height: 32),

                // OR Divider
                const Row(
                  children: [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text('OR'),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 32),

                // Social Logins
                _buildSocialLoginButton(
                    'Login with Google',
                    'assets/images/google_logo.png',
                    isDarkMode
                ),
                const SizedBox(height: 16),
                _buildSocialLoginButton(
                    'Login with Facebook',
                    'assets/images/facebook_logo.png',
                    isDarkMode
                ),

                const SizedBox(height: 48),

                // Already have an account?
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Already have an account?"),
                    TextButton(
                      onPressed: widget.onSignInTapped,
                      child: const Text('Sign in'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialLoginButton(String text, String assetPath, bool isDarkMode) {
    return OutlinedButton.icon(
      icon: Image.asset(assetPath, height: 24),
      onPressed: () {
        // TODO: Implement social login
      },
      label: Text(text),
      style: OutlinedButton.styleFrom(
        foregroundColor: isDarkMode ? Colors.white : Colors.black87,
        padding: const EdgeInsets.symmetric(vertical: 16),
        side: BorderSide(color: isDarkMode ? Colors.white24 : Colors.black12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
