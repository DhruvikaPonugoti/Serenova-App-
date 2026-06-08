import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login.dart';
import '../services/sound.dart';

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final nameController = TextEditingController();

  bool _obscurePassword = true;

  void signupUser(BuildContext context) async {
  try {
    // ✅ AUTH (CRITICAL)
    UserCredential userCredential =
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: emailController.text.trim(),
      password: passwordController.text.trim(),
    );

    final user = userCredential.user;

    if (user == null) {
      throw Exception("User creation failed");
    }

    // 🔹 OPTIONAL: display name (DO NOT FAIL SIGNUP)
    try {
      if (nameController.text.trim().isNotEmpty) {
        await user.updateDisplayName(nameController.text.trim());
      }
    } catch (e) {
      debugPrint("Display name update failed: $e");
    }

    // 🔹 OPTIONAL: Firestore save
    try {
      await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .set({
        "uid": user.uid,
        "name": nameController.text.trim(),
        "email": user.email,
        "createdAt": Timestamp.now(),
      });
    } catch (e) {
      debugPrint("Firestore save failed: $e");
    }

    // ✅ SUCCESS MESSAGE
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Signup successful!"),
        backgroundColor: Colors.green.shade700,
        duration: const Duration(seconds: 2),
      ),
    );

    await Future.delayed(const Duration(seconds: 2));

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const Login()),
    );
  } on FirebaseAuthException catch (e) {
    String msg = "Signup failed";

    if (e.code == 'email-already-in-use') {
      msg = "This email is already registered";
    } else if (e.code == 'weak-password') {
      msg = "Password is too weak";
    } else if (e.code == 'invalid-email') {
      msg = "Invalid email address";
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red.shade900,
      ),
    );
  } catch (e) {
    // ❗ ONLY truly unexpected errors land here
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Unexpected error: $e"),
        backgroundColor: Colors.red.shade900,
      ),
    );
  }
}



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 🌄 Background Image
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/pic6.jpeg'),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // 🔲 Dark overlay
          Container(color: Colors.black.withAlpha((0.4 * 255).round())),

          // 📝 Signup UI
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.person_add_alt_1,
                    size: 50,
                    color: Color(0xFF00FF41),
                  ),
                  const SizedBox(height: 20),

                  const Text(
                    "Create Account",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),

                  const Text(
                    "Sign up to get started",
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 40),
                  // Name
                  TextField(
                    controller: nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: "Name",
                      labelStyle: TextStyle(
                        color: Colors.white70.withOpacity(0.7),
                      ),
                      filled: true,
                      fillColor: Colors.black.withAlpha((0.5 * 255).round()),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF00FF41),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Email
                  TextField(
                    controller: emailController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: "Email",
                      labelStyle: TextStyle(
                        color: Colors.white70.withOpacity(0.7),
                      ),
                      filled: true,
                      fillColor: Colors.black.withAlpha((0.5 * 255).round()),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF00FF41),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Password
                  TextField(
                    controller: passwordController,
                    obscureText: _obscurePassword,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: "Password",
                      labelStyle: TextStyle(
                        color: Colors.white70.withOpacity(0.7),
                      ),
                      filled: true,
                      fillColor: Colors.black.withAlpha((0.5 * 255).round()),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.white70,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),

                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF00FF41),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Signup Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        signupUser(context);
                        Sound.playTap();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00FF41),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Signup",
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                  Row(
                    children: const [
                      Expanded(
                        child: Divider(
                          color: Color.fromARGB(255, 255, 255, 255),
                          thickness: 1,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          "OR",
                          style: TextStyle(
                            color: Color.fromARGB(255, 255, 255, 255),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: Color.fromARGB(255, 255, 255, 255),
                          thickness: 1,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),
                  // Back to Login
                  TextButton(
                    onPressed: () {
                      Sound.playTap();
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => Login()),
                      );
                    },
                    child: const Text(
                      "Already have an account? Login",
                      style: TextStyle(color: Color(0xFF00FF41), fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
