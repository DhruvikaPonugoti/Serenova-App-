import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:confetti/confetti.dart';
import 'ginst.dart';
import '../services/sound.dart';

class MemoryMatch extends StatefulWidget {
  const MemoryMatch({super.key});

  @override
  State<MemoryMatch> createState() => _MemoryMatchState();
}

class _MemoryMatchState extends State<MemoryMatch> {
  final List<String> allQuotes = [
    "Failure is success in progress",
    "Every day is a second chance",
    "Small steps lead to big changes",
    "Your mind is powerful",
    "Peace begins with a smile",
    "You are stronger than you think",
    "Progress, not perfection",
    "Happiness is a choice",
    "Difficult roads lead to beautiful places",
    "Trust yourself",
  ];

  late List<String> cards;
  late List<bool> revealed;
  late List<bool> matched;
  late ConfettiController _confettiController;
  bool showInstructions = false;

  String displayedQuote = "Tap a wooden block 🌱";

  int first = -1;
  int second = -1;
  int moves = 0;
  bool busy = false;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));
    startGame();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void startGame() {
    allQuotes.shuffle();
    final selected = allQuotes.take(10).toList();

    cards = [...selected, ...selected]..shuffle(Random());
    revealed = List.generate(20, (_) => false);
    matched = List.generate(20, (_) => false);

    displayedQuote = "Tap a wooden block 🌱";
    first = -1;
    second = -1;
    moves = 0;
    busy = false;

    setState(() {});
  }

  void onCardTap(int index) async {
    if (revealed[index] || matched[index] || busy) return;

    setState(() {
      moves++;
      revealed[index] = true;
      displayedQuote = cards[index];
    });

    if (first == -1) {
      first = index;
    } else {
      second = index;
      busy = true;

      await Future.delayed(const Duration(milliseconds: 700));

      if (cards[first] == cards[second]) {
        setState(() {
          matched[first] = true;
          matched[second] = true;
        });
      } else {
        setState(() {
          revealed[first] = false;
          revealed[second] = false;
        });
      }

      first = -1;
      second = -1;
      busy = false;

      if (matched.every((e) => e)) {
        _confettiController.play();
        showWinDialog();
      }
    }
  }

  void showWinDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("You Won ✅!", textAlign: TextAlign.center),
        content: Text("Total moves: $moves", textAlign: TextAlign.center),
        actionsPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Sound.playTap();
                    Navigator.pop(context);
                    Navigator.pop(context, true);
                  },
                  child: Container(
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.green.shade300),
                    ),
                    child: Text(
                      "Quit",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.green.shade800,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Sound.playTap();
                    Navigator.pop(context);
                    startGame();
                  },
                  child: Container(
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.green.shade400, Colors.green.shade700],
                      ),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Text(
                      "Play Again",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;
    final scale = width / 393;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset("assets/mmback.jpg", fit: BoxFit.cover),
          ),

          ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            gravity: 0.2,
            emissionFrequency: 0.05,
            numberOfParticles: 30,
          ),

          Positioned(
            top: height * 0.03,
            left: width * 0.04,
            child: GestureDetector(
              onTap: () {
                Sound.playTap();
                Navigator.pop(context);
              },
              child: Image.asset(
                "assets/back.png",
                width: width * 0.15,
                height: height * 0.07,
              ),
            ),
          ),

          Positioned(
            top: height * 0.03,
            right: width * 0.06,
            child: GestureDetector(
              onTap: () {
                Sound.playTap();
                setState(() {
                  showInstructions = true;
                });
              },
              child: Image.asset(
                "assets/info.png",
                width: width * 0.12,
                height: width * 0.12,
              ),
            ),
          ),

          Padding(
            padding: EdgeInsets.fromLTRB(
              width * 0.08,
              height * 0.28,
              width * 0.08,
              0,
            ),
            child: Column(
              children: [
                Text(
                  "Moves: $moves",
                  style: TextStyle(
                    fontSize: 20 * scale,
                    fontWeight: FontWeight.w600,
                    color: const Color.fromARGB(255, 114, 71, 10),
                  ),
                ),

                SizedBox(height: height * 0.02),

                SizedBox(
                  height: height * 0.09,
                  child: Center(
                    child: Text(
                      displayedQuote,
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 22 * scale,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: const [
                          Shadow(
                            color: Colors.black54,
                            blurRadius: 6,
                            offset: Offset(1, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                SizedBox(height: height * 0.02),

                // ✅ GRID FIXED TO 4 COLUMNS
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final gridWidth = constraints.maxWidth;

                      return GridView.builder(
                        padding: EdgeInsets.symmetric(
                          horizontal: gridWidth * 0.02,
                          vertical: gridWidth * 0.02,
                        ),
                        gridDelegate:
                            SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4, // ✅ ALWAYS 4
                          crossAxisSpacing: gridWidth * 0.02,
                          mainAxisSpacing: gridWidth * 0.02,
                          childAspectRatio: 1,
                        ),
                        itemCount: 20,
                        itemBuilder: (context, index) {
                          final bool isRevealed = revealed[index];
                          final bool isMatched = matched[index];

                          return GestureDetector(
                            onTap: () => onCardTap(index),
                            child: ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(gridWidth * 0.02),
                              child: Builder(
                                builder: (_) {
                                  if (isMatched) {
                                    return Center(
                                      child: Text(
                                        "🌸",
                                        style: TextStyle(
                                            fontSize: gridWidth * 0.08),
                                      ),
                                    );
                                  }

                                  if (isRevealed) {
                                    return Center(
                                      child: Text(
                                        "🌱",
                                        style: TextStyle(
                                            fontSize: gridWidth * 0.08),
                                      ),
                                    );
                                  }

                                  return Image.asset(
                                    "assets/wb.png",
                                    fit: BoxFit.cover,
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          if (showInstructions)
            Instructions(
              game: "mmatch",
              onClose: () {
                Sound.playTap();
                setState(() {
                  showInstructions = false;
                });
              },
            ),
        ],
      ),
    );
  }
}