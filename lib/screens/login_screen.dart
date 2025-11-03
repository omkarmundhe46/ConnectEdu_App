import 'package:connectedu_app/screens/verification_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:connectedu_app/bloc/auth_bloc.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onSignUpTapped;
  const LoginScreen({super.key, required this.onSignUpTapped});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;

  void _login() {
    final email = _emailController.text;
    final password = _passwordController.text;
    if (email.isNotEmpty && password.isNotEmpty) {
      context.read<AuthBloc>().add(LoggedIn(email: email, password: password));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {



          if (state is AuthFailure) {
            final error = state.error;

            // Check for the specific verification error
            if (error.contains("not verified")) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(error), backgroundColor: Colors.orange),
              );
              // Redirect to verification screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => VerificationScreen(email: _emailController.text),
                ),
              );
            } else {
              // Show a generic login error
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(error), backgroundColor: Colors.red),
              );
            }
          }
        },
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App Logo (You can replace this with your actual logo asset)
                  const Icon(Icons.school, size: 80, color: Color(0xFF4A55A2)),
                  const SizedBox(height: 16),
                  const Text(
                    'EventHub', // As per your design
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  const Text(
                    'Sign in',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),

                  // Email Field
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      hintText: 'abc@email.com',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),

                  // Password Field
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

                  // Remember Me & Forgot Password
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Switch(
                            value: _rememberMe,
                            onChanged: (value) => setState(() => _rememberMe = value),
                            activeColor: Theme.of(context).colorScheme.primary,
                          ),
                          const Text('Remember Me'),
                        ],
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text('Forgot Password?'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Sign In Button
                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      if (state is AuthLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      return ElevatedButton(
                        onPressed: _login,
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('SIGN IN'),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward),
                          ],
                        ),
                      );
                    },
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

                  // Social Logins (Placeholder functionality)
                  _buildSocialLoginButton(
                      'Login with Google',
                      'assets/images/google_logo.png', // You'll need to add this asset
                      isDarkMode
                  ),
                  const SizedBox(height: 16),
                  _buildSocialLoginButton(
                      'Login with Facebook',
                      'assets/images/facebook_logo.png', // You'll need to add this asset
                      isDarkMode
                  ),

                  const SizedBox(height: 48),

                  // Don't have an account?
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account?"),
                      TextButton(
                        onPressed: widget.onSignUpTapped,
                        child: const Text('Sign up'),
                      ),
                    ],
                  ),
                ],
              ),
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

