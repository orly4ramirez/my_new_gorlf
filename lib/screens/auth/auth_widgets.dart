import 'package:flutter/material.dart';

class AuthForm extends StatefulWidget {
  final bool isSignUp;
  final Function(String, String, String?) onSubmit;

  const AuthForm({super.key, required this.isSignUp, required this.onSubmit});

  @override
  AuthFormState createState() => AuthFormState();
}

class AuthFormState extends State<AuthForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _displayNameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.email),
            ),
            validator: (value) => value!.isEmpty ? 'Enter an email' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            decoration: const InputDecoration(
              labelText: 'Password',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.lock),
            ),
            obscureText: true,
            validator: (value) => value!.length < 6 ? 'Password must be at least 6 characters' : null,
          ),
          if (widget.isSignUp) ...[
            const SizedBox(height: 16),
            TextFormField(
              controller: _displayNameController,
              decoration: const InputDecoration(
                labelText: 'Display Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) => value!.isEmpty ? 'Enter a display name' : null,
            ),
          ],
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                widget.onSubmit(
                  _emailController.text.trim(),
                  _passwordController.text.trim(),
                  widget.isSignUp ? _displayNameController.text.trim() : null,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(widget.isSignUp ? 'Sign Up' : 'Sign In'),
          ),
        ],
      ),
    );
  }
}