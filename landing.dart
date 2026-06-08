import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login.dart';
import 'signup.dart';
import '../services/sound.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  bool showSecondBg = false;
  bool showAuthBox = false;
  bool startPressed = false;

  void onStartTap() async {
  Sound.playTap();

  setState(() {
    startPressed = true;
  });

  await Future.delayed(const Duration(milliseconds: 120));

  final user = FirebaseAuth.instance.currentUser;

  if (user != null) {
    // 🔐 USER ALREADY LOGGED IN → GO HOME
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const Home()),
    );
  } else {
    // 🚪 NOT LOGGED IN → SHOW AUTH LANDING
    setState(() {
      showSecondBg = true;
    });

    await Future.delayed(const Duration(milliseconds: 300));

    setState(() {
      showAuthBox = true;
    });
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 🌄 BACKGROUND
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(
                  showSecondBg ? 'assets/landing2.png' : 'assets/landing.png',
                ),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // 🌱 START IMAGE
          if (!showSecondBg)
            Center(
              child: GestureDetector(
                onTap: onStartTap,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  transform: startPressed
                      ? (Matrix4.identity()..scale(0.96))
                      : Matrix4.identity(),
                  child: Image.asset('assets/start.png', width: 90),
                ),
              ),
            ),

          // 🌿 CONTENT (MOVED UP + CLEAN)
          if (showAuthBox)
            Center(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 400),
                opacity: showAuthBox ? 1 : 0,
                child: Transform.translate(
                  offset: const Offset(0, -7), // 👈 move UP
                  child: SizedBox(
                    width:
                        MediaQuery.of(context).size.width * 0.6, // 👈 reduced
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ⚪ CIRCLE WITH PLANT
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color.fromARGB(255, 255, 255, 255),
                          ),
                          child: Image.asset(
                            'assets/plant.gif',
                            width: 70,
                            height: 70,
                          ),
                        ),

                        const SizedBox(height: 18),

                        const Text(
                          "SERENOVA",
                          style: TextStyle(
                            fontSize: 31, // 👈 increased
                            fontWeight: FontWeight.bold,
                            letterSpacing: 3,
                            color: Colors.white,
                          ),
                        ),

                        const SizedBox(height: 8),

                        const Text(
                          "A gentle space for your mind to bloom",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15, // 👈 increased
                            color: Color.fromARGB(255, 0, 0, 0),
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 18),

                        Text(
                          "A calming, game-like mental wellness app where your "
                          "emotions grow into a living garden. Journal, play, "
                          "and reflect every day ",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            height: 1.3,
                            color: const Color.fromARGB(255, 253, 253, 253),
                            // fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 26),

                        // LOGIN
                        SizedBox(
                          width: double.infinity,
                          height: 46,
                          child: ElevatedButton(
                            onPressed: () {
                              Sound.playTap();
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => Login()),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromARGB(
                                255,
                                112,
                                71,
                                0,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                            child: const Text(
                              "LOGIN",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // SIGN UP
                        SizedBox(
                          width: double.infinity,
                          height: 46,
                          child: OutlinedButton(
                            onPressed: () {
                              Sound.playTap();
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => Signup()),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.white),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                            child: const Text(
                              "SIGN UP",
                              style: TextStyle(
                                color: Color.fromARGB(255, 0, 0, 0),
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
