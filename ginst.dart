import 'package:flutter/material.dart';
import 'dart:ui';
import '../services/sound.dart';

class Instructions extends StatefulWidget {
  final VoidCallback onClose;
  final String game; // which game opened it

  const Instructions({
    super.key,
    required this.onClose,
    required this.game,
  });

  @override
  State<Instructions> createState() => _InstructionsState();
}

class _InstructionsState extends State<Instructions> {
  int _currentIndex = 0;

  // 🔹 Pick images based on game
  List<String> get _foregroundImages {
    switch (widget.game) {
      case "mmatch":
        return [
          "assets/mmin1.png",
          "assets/mmin2.png",
        ];

      case "crossword":
        return [
          "assets/cin1.png",
          "assets/cin2.png",
        ];

      default: // mindfulness
        return [
          "assets/min.png",
        ];
    }
  }

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
          // 🌫️ Blur whatever game is behind
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              width: size.width,
              height: size.height,
              color: Colors.black.withOpacity(0.45),
            ),
          ),

          // 🖼️ Instruction image
          Center(
            child: Image.asset(
              _foregroundImages[_currentIndex],
              fit: BoxFit.contain,
              width: size.width * 0.85,
            ),
          ),

          // ⬅️ Back arrow
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
                child: Image.asset(
                  "assets/left.png",
                  width: 52,
                  height: 52,
                ),
              ),
            ),

          // ➡️ Next / Close
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
