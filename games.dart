import 'package:flutter/material.dart';
import 'word_puzzle.dart';
import 'mmatch.dart';
import 'mindfulness.dart';
import '../services/sound.dart';

class Games extends StatelessWidget {
  const Games({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          /// 🔹 BACKGROUND
          Positioned.fill(
            child: Image.asset("assets/gamesbg.jpg", fit: BoxFit.cover),
          ),

          /// 🔹 BACK BUTTON (MANUAL POSITION)
          Positioned(
            top: 27, // 👈 change Y position
            left: 16, // 👈 change X position
            child: GestureDetector(
              onTap: () {
                Navigator.pop(context);
                Sound.playTap();
              },
              child: Image.asset("assets/back.png", width: 62, height: 52),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                /// 🔹 TITLE IMAGE (FREE SIZE)
                // Padding(
                //   padding: const EdgeInsets.only(top: 40),
                //   child: Image.asset(
                //     "assets/games.png",
                //     height: 50, // 👈 control title height HERE
                //     fit: BoxFit.contain,
                //   ),
                // ),

                const SizedBox(height: 100),

                /// 🔹 SECTION DESCRIPTION IMAGE
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 0,
                    vertical: 0,
                  ),
                  child: Image.asset(
                    "assets/game_para.png", // 👈 your paragraph image
                    height: 190, // 👈 adjust freely
                    fit: BoxFit.contain,
                  ),
                ),

                /// 🔹 GAME LIST
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 30, 20, 0),
                    children: [
                      _gameImageTile(
                        image: "assets/title.png",
                        height: 80, // Crossword height
                        gapBelow: 46,
                        onTap: () {
                          Sound.playTap();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const WordPuzzle(),
                            ),
                          );
                        },
                      ),
                      _gameImageTile(
                        image: "assets/match.png",
                        height: 80, // Memory Match height
                        gapBelow: 66,
                        onTap: () {
                          Sound.playTap();
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => MemoryMatch()),
                          );
                        },
                      ),
                      _gameImageTile(
                        image: "assets/med_title.png",
                        height: 50, // Mindfulness height
                        gapBelow: 0, // no gap after last
                        onTap: () {
                          Sound.playTap();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const Mindfulness(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 🔹 IMAGE TILE WITH INDIVIDUAL HEIGHT + GAP
  Widget _gameImageTile({
    required String image,
    required VoidCallback onTap,
    required double height,
    required double gapBelow,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              height: height, // 👈 IMAGE HEIGHT CONTROL
              width: double.infinity,
              child: Image.asset(image, fit: BoxFit.contain),
            ),
          ),
        ),
        SizedBox(height: gapBelow), // 👈 GAP CONTROL
      ],
    );
  }
}
