import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import for User
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../services/auth_service.dart';
import 'auth_widgets.dart';
import '../dashboard/dashboard_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  AuthScreenState createState() => AuthScreenState();
}

class AuthScreenState extends State<AuthScreen> {
  final AuthService _authService = AuthService();
  bool _isSignUp = false;

  // Handle Google Sign-In callback
  void _handleGoogleSignIn(User? user) {
    if (!mounted) return;
    if (user != null) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const GorlfDashboard()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Google Sign-In failed')));
    }
  }

  Future<void> _handleEmailAuth(String email, String password, String? displayName) async {
    if (!mounted) return;
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    User? user;
    if (_isSignUp) {
      if (displayName == null) return; // Prevent null passing
      user = await _authService.signUpWithEmail(email, password, displayName);
    } else {
      user = await _authService.signInWithEmail(email, password);
    }

    if (!mounted) return;
    if (user != null) {
      navigator.pushReplacement(MaterialPageRoute(builder: (_) => const GorlfDashboard()));
    } else {
      scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Authentication failed')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueAccent, Colors.lightBlue],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _isSignUp ? 'Sign Up' : 'Sign In',
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                    ),
                    const SizedBox(height: 24),
                    AuthForm(
                      isSignUp: _isSignUp,
                      onSubmit: _handleEmailAuth,
                    ),
                    const SizedBox(height: 16),
                    // Replace custom Google button with renderGoogleSignInButton
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const FaIcon(FontAwesomeIcons.google, color: Colors.redAccent),
                        const SizedBox(width: 8),
                        _authService.renderGoogleSignInButton(onSignedIn: _handleGoogleSignIn),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => setState(() => _isSignUp = !_isSignUp),
                      child: Text(
                        _isSignUp ? 'Already have an account? Sign In' : 'Need an account? Sign Up',
                        style: const TextStyle(color: Colors.blueAccent),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}