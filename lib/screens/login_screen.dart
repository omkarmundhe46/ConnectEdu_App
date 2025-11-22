import 'package:connectedu_app/screens/forgot_password_screen.dart';
import 'package:connectedu_app/screens/verification_screen.dart';
import 'package:connectedu_app/services/secure_storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:connectedu_app/bloc/auth_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onSignUpTapped;
  const LoginScreen({super.key, required this.onSignUpTapped});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _rememberMe = false;

   //  for remember me logic
  @override
  void initState() {
    super.initState();
    // --- 1. LOAD SAVED EMAIL ON START ---
    _loadSavedEmail();
  }

  Future<void> _loadSavedEmail() async {
    final storage = context.read<SecureStorageService>();
    final savedEmail = await storage.getEmail();
    if (savedEmail != null && savedEmail.isNotEmpty) {
      setState(() {
        _emailController.text = savedEmail;
        _rememberMe = true; // Check the box if we found an email
      });
    }
  }

  void _login() {
    final email = _emailController.text;
    final password = _passwordController.text;

    if (email.isNotEmpty && password.isNotEmpty) {
      // --- 2. HANDLE REMEMBER ME LOGIC ---
      final storage = context.read<SecureStorageService>();
      if (_rememberMe) {
        storage.saveEmail(email);
      } else {
        storage.deleteEmail();
      }

      context.read<AuthBloc>().add(LoggedIn(email: email, password: password));
    }
  }


  Future<void> _loginWithGoogle() async {
    // This is the URL of YOUR backend, not Google's
    // final Uri url = Uri.parse('http://localhost:8080/oauth2/authorization/google');      //  Android Emulator IP
    final Uri url = Uri.parse('https://toniest-wilda-unfabulously.ngrok-free.dev/oauth2/authorization/google');      //  Android Emulator IP

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch browser. Please try again.'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _loginWithFacebook() async {
    // Use localhost for the emulator (after running 'adb reverse tcp:8080 tcp:8080')
    final Uri url = Uri.parse('https://toniest-wilda-unfabulously.ngrok-free.dev/oauth2/authorization/facebook');

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch browser. Please try again.'), backgroundColor: Colors.red),
        );
      }
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
                  Image.asset(
                    Theme.of(context).brightness == Brightness.dark
                        ? 'assets/images/logo2.png' // Light logo for dark mode
                        : 'assets/images/logo1.png', // Dark logo for light mode
                    width: 130,
                    height: 130,
                    fit: BoxFit.contain,
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
                    obscureText: !_isPasswordVisible,
                    decoration: InputDecoration(
                      hintText: 'Your password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                    ),
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
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                          );
                        },
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
                    isDarkMode,
                    _loginWithGoogle,
                  ),
                  const SizedBox(height: 16),
                  _buildSocialLoginButton(
                    'Login with Facebook',
                    'assets/images/facebook_logo.png', // You'll need to add this asset
                    isDarkMode,
                    _loginWithFacebook,
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

  Widget _buildSocialLoginButton(String text, String assetPath, bool isDarkMode, VoidCallback onPressed) {
    return OutlinedButton.icon(
      icon: Image.asset(assetPath, height: 24),
      onPressed: onPressed,
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