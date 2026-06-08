import 'package:flutter/material.dart';
import 'dart:ui';
import '../services/sound.dart';

class Instructions extends StatefulWidget {
  final VoidCallback onClose;

  const Instructions({super.key, required this.onClose});

  @override
  State<Instructions> createState() => _InstructionsState();
}

class _InstructionsState extends State<Instructions> {
  int _currentIndex = 0;

  final List<String> _foregroundImages = [
    "assets/in4.png",
    "assets/in2.png",
    "assets/in1.png",
    "assets/in5.png",
    "assets/in3.png",
  ];

  void _next() {
    if (_currentIndex < _foregroundImages.length - 1) {
      setState(() {
        _currentIndex++;
      });
    } else {
      widget.onClose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bool isLast = _currentIndex == _foregroundImages.length - 1;

    return SizedBox.expand(
      child: Stack(
        children: [
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              width: size.width,
              height: size.height,
              color: Colors.black.withOpacity(0.45),
            ),
          ),

          // 🖼️ FOREGROUND INSTRUCTION IMAGE
          Center(
            child: Image.asset(
              _foregroundImages[_currentIndex],
              fit: BoxFit.contain,
              width: size.width * 0.85,
            ),
          ),

          // ⬅️ BACK ARROW (only if not first)
          if (_currentIndex > 0)
            Positioned(
              left: 48,
              top: size.height * 0.13,
              child: GestureDetector(
                onTap: () {
                  Sound.playTap();
                  setState(() {
                    _currentIndex--;
                  });
                },
                child: Image.asset("assets/left.png", width: 52, height: 52),
              ),
            ),

          // ➡️ NEXT / CLOSE ARROW
          Positioned(
            right: 48,
            top: size.height * 0.13,
            child: GestureDetector(
              onTap: () {
                Sound.playTap();
                _next();
              },
              child: Image.asset(
                isLast ? "assets/close.png" : "assets/right.png",
                width: 52,
                height: 52,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
