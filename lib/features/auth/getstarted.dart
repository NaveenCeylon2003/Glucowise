import 'package:flutter/material.dart';

class Start extends StatelessWidget {
  const Start({super.key}); // Added constructor with key for consistency

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.purple.withOpacity(0.8),
              Colors.deepPurple.withOpacity(0.8)
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated Logo/Title Section
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 1000),
                    curve: Curves.easeInOut,
                    width: 300,
                    child: Column(
                      children: [
                        const Icon(
                          Icons.account_circle,
                          size: 100,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          "Welcome to GlucoWise",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 5),
                        Text(
                          "Your journey to better health starts here",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.8),
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 60),

                  // Login Button
                  _buildActionButton(
                    context,
                    "Login",
                    Colors.purpleAccent,
                    Icons.login,
                    () => Navigator.pushNamed(context, "login"),
                  ),
                  const SizedBox(height: 20),

                  // Sign Up Button
                  _buildActionButton(
                    context,
                    "Sign Up",
                    Colors.deepPurple,
                    Icons.person_add,
                    () => Navigator.pushNamed(context, "signup"),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Helper method to build action buttons
  Widget _buildActionButton(
    BuildContext context,
    String label,
    Color color,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      width: 250,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white, size: 24),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
          elevation: 5,
          shadowColor: Colors.black.withOpacity(0.3),
        ),
      ),
    );
  }
}
