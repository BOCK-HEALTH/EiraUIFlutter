// registration_screen.dart (UPDATED FOR JWT AUTH)

import 'package:flutter/material.dart';
import 'package:flutter_application_1/api_service.dart'; // --- IMPORT YOUR API SERVICE ---

// --- THEME AND STYLING ---
const Color kEiraYellow = Color(0xFFFDB821);
const Color kEiraText = Color(0xFF343541);
const Color kEiraTextSecondary = Color(0xFF6E6E80);
const Color kEiraBackground = Color(0xFFFFFFFF);

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final ApiService _apiService = ApiService(); // --- USE APISERVICE, NOT FIREBASE ---
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // --- REPLACED FIREBASE REGISTER WITH API SERVICE REGISTER ---
  Future<void> _register() async {
    if (_passwordController.text.trim() != _confirmPasswordController.text.trim()) {
      _showSnackBar('Passwords do not match.', Colors.red);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Call the register method from your ApiService
      await _apiService.register(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        name: _usernameController.text.trim(),
      );

      // If registration is successful, show a success message and go back to the login screen
      if (mounted) {
        _showSnackBar('Registration successful! Please login.', Colors.green);
        // Wait a moment before popping so the user can see the message
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.of(context).pop();
          }
        });
      }
    } catch (e) {
      // The ApiService will throw an exception with the error message from the server
      _showSnackBar(e.toString().replaceFirst('Exception: ', ''), Colors.red);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // --- THE UI REMAINS THE SAME ---
    // (Your existing build method code goes here, no changes needed to the widgets)
    return Scaffold(
      backgroundColor: kEiraBackground,
      appBar: AppBar(
        backgroundColor: kEiraBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kEiraText),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            width: MediaQuery.of(context).size.width > 600 ? 400 : MediaQuery.of(context).size.width * 0.9,
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: kEiraBackground,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/Eira.png', // Ensure this asset is in your pubspec.yaml
                  width: 120,
                  height: 120,
                ),
                const SizedBox(height: 24),
                const Text(
                  "Register",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: kEiraText,
                    fontFamily: 'Roboto',
                  ),
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _usernameController, // Username field
                  keyboardType: TextInputType.text,
                  decoration: InputDecoration(
                    hintText: "Username",
                    hintStyle: TextStyle(color: kEiraTextSecondary.withOpacity(0.7), fontFamily: 'Roboto'),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  ),
                  style: const TextStyle(fontFamily: 'Roboto', color: kEiraText),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: "Email",
                    hintStyle: TextStyle(color: kEiraTextSecondary.withOpacity(0.7), fontFamily: 'Roboto'),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  ),
                  style: const TextStyle(fontFamily: 'Roboto', color: kEiraText),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: "Password",
                    hintStyle: TextStyle(color: kEiraTextSecondary.withOpacity(0.7), fontFamily: 'Roboto'),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  ),
                  style: const TextStyle(fontFamily: 'Roboto', color: kEiraText),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: "Confirm Password",
                    hintStyle: TextStyle(color: kEiraTextSecondary.withOpacity(0.7), fontFamily: 'Roboto'),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  ),
                  style: const TextStyle(fontFamily: 'Roboto', color: kEiraText),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kEiraYellow,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 3,
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            "Register",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Roboto',
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () {
                    if (!_isLoading) {
                      Navigator.of(context).pop(); // Go back to login screen
                    }
                  },
                  child: Text.rich(
                    TextSpan(
                      text: "Already have an account? ",
                      style: TextStyle(
                        color: kEiraTextSecondary,
                        fontSize: 14,
                        fontFamily: 'Roboto',
                      ),
                      children: [
                        TextSpan(
                          text: "Login",
                          style: TextStyle(
                            color: kEiraYellow,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Roboto',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}