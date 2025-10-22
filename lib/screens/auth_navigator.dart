import 'package:flutter/material.dart';
import 'package:connectedu_app/screens/login_screen.dart';
import 'package:connectedu_app/screens/signup_screen.dart';

class AuthNavigator extends StatefulWidget {
  const AuthNavigator({super.key});

  @override
  State<AuthNavigator> createState() => _AuthNavigatorState();
}

class _AuthNavigatorState extends State<AuthNavigator> {
  bool _showLoginPage = true;

  void _togglePage() {
    setState(() {
      _showLoginPage = !_showLoginPage;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showLoginPage) {
      return LoginScreen(onSignUpTapped: _togglePage);
    } else {
      return SignUpScreen(onSignInTapped: _togglePage);
    }
  }
}
