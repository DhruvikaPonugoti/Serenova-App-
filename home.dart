import 'package:flutter/material.dart';
import '../services/music.dart';
import '../services/sound.dart';
import 'instructions.dart';
import 'garden.dart';
import 'dashboard.dart';
import 'journal.dart';
import 'games.dart';
import 'settings.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  void initState() {
    super.initState();
    // 🎵 Start background music when Home opens
    Music.play();
  }
  
  void _go(BuildContext context, Widget page) {
    Sound.playTap();
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }
  bool _showInstructions = false;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // 🖼️ BACKGROUND IMAGE
          SizedBox(
            width: size.width,
            height: size.height,
            child: Image.asset("assets/home.png", fit: BoxFit.cover),
          ),

          // 🔘 MY GARDEN
          _BoardButton(
            top: size.height * 0.27,
            onTap: () => _go(context, const Garden()),
          ),

          // 🔘 DASHBOARD
          _BoardButton(
            top: size.height * 0.35,
            onTap: () => _go(context, const Dashboard()),
          ),

          // 🔘 JOURNAL
          _BoardButton(
            top: size.height * 0.465,
            onTap: () => _go(context, const Journal()),
          ),

          // 🔘 GAMES
          _BoardButton(
            top: size.height * 0.56,
            onTap: () => _go(context, const Games()),
          ),

          // 🔘 SETTINGS
          _BoardButton(
            top: size.height * 0.67,
            onTap: () => _go(context, const Settings()),
          ),

          // ℹ️ INFO BUTTON
          Positioned(
            top: 40,
            right: 20,
            child: GestureDetector(
              onTap: () {
                Sound.playTap();
                setState(() {
                  _showInstructions = true;
                });
              },
              child: Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(shape: BoxShape.circle),
                child: Center(
                  child: Image.asset(
                    "assets/info.png",
                    width: 46,
                    height: 46,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),

          // 🧠 INSTRUCTIONS OVERLAY (LAST — ON TOP)
          if (_showInstructions)
            Instructions(
              onClose: () {
                setState(() {
                  _showInstructions = false;
                });
              },
            ),
        ],
      ),
    );
  }
}

/// 🎯 Invisible Tap Zone for Wooden Boards
class _BoardButton extends StatelessWidget {
  final double top;
  final VoidCallback onTap;

  const _BoardButton({required this.top, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: 74,
      right: 74,
      height: 62,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          color: Colors.transparent, // invisible clickable area
        ),
      ),
    );
  }
}
