import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:g21285878naveen/features/home/home.dart'; // For navigation back to HomepageState

class ChangeEmailScreen extends StatefulWidget {
  const ChangeEmailScreen({super.key});

  @override
  _ChangeEmailScreenState createState() => _ChangeEmailScreenState();
}

class _ChangeEmailScreenState extends State<ChangeEmailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  // Function to handle email change
  Future<void> _changeEmail(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        User? user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("No user is signed in.")),
          );
          return;
        }

        String newEmail = _emailController.text.trim();

        // Step 1: Send verification email to the new email address
        await user.verifyBeforeUpdateEmail(newEmail);

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "A verification email has been sent to your new email address. Please verify it to complete the change.",
            ),
            duration: Duration(seconds: 5),
          ),
        );

        // Step 2: Wait for user to verify (handled by Firebase automatically)
        // Once verified, Firebase updates the email, but we can listen for changes if needed

        // Step 3: Update Firestore (optional, if you store email there)
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
          {'email': newEmail},
          SetOptions(merge: true),
        );

        // Navigate back to Profile or Home after initiating the change
        HomepageState? homepageState = context.findAncestorStateOfType<HomepageState>();
        homepageState?.setState(() => homepageState.myIndex = 2); // Back to ProfilePage

      } on FirebaseAuthException catch (e) {
        String errorMessage;
        switch (e.code) {
          case 'email-already-in-use':
            errorMessage = "This email is already in use by another account.";
            break;
          case 'invalid-email':
            errorMessage = "The email address is invalid.";
            break;
          case 'requires-recent-login':
            errorMessage = "Please re-sign in and try again.";
            break;
          default:
            errorMessage = "An error occurred: ${e.message}";
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("An unexpected error occurred: $e")),
        );
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Change Email"),
        backgroundColor: Colors.blueAccent,
      ),
      body: Center(
        child: Container(
          width: 300,
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Change Email",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                Text(
                  "Current Email: ${FirebaseAuth.instance.currentUser?.email ?? 'Not signed in'}",
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: "New Email",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please enter a new email address.";
                    }
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                      return "Please enter a valid email address.";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                  onPressed: () => _changeEmail(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  ),
                  child: const Text(
                    "Change Email",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    HomepageState? homepageState = context.findAncestorStateOfType<HomepageState>();
                    homepageState?.setState(() => homepageState.myIndex = 2); // Back to ProfilePage
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  ),
                  child: const Text(
                    "Back",
                    style: TextStyle(color: Colors.white, fontSize: 16),
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