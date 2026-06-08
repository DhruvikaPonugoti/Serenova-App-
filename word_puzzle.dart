import 'dart:math';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import '../services/sound.dart';
import 'ginst.dart';

class WordPuzzle extends StatefulWidget {
  const WordPuzzle({super.key});

  @override
  State<WordPuzzle> createState() => _WordPuzzleState();
}

class _WordPuzzleState extends State<WordPuzzle> {
  static const int gridSize = 15;
  late List<List<Cell>> grid;
  bool puzzleCompleted = false;
  static const int maxAcross = 6;
  static const int maxDown = 6;
  late ConfettiController _confettiController;
  bool isAcrossMode = true; // true = Across, false = Down
  int hintsLeft = 5; // 🔑 max hints per game
  bool showInstructions = false;

  final Random random = Random();

  final Map<String, String> wordBank = {
    "CALM": "A peaceful state of mind",
    "CARE": "Kind attention or concern",
    "PEACE": "Freedom from disturbance",
    "RELAX": "Reduce stress or tension",
    "HEAL": "To recover emotionally",
    "BALANCE": "Mental or emotional stability",
    "TRUST": "Belief in reliability",
    "STRONG": "Mental resilience",
    "GROW": "To develop or improve",
    "FOCUS": "Direct attention",
    "SMILE": "A sign of happiness",
    "REST": "Time to recharge",
    "HOPE": "Belief that things will improve",
    "BREATHE": "A grounding action",
    "MINDFUL": "Present awareness",
    "ENERGY": "Mental vitality",
    "STABLE": "Firm and steady emotionally",
    "SERENE": "Calm and peaceful",
    "PATIENCE": "Ability to stay calm while waiting",
    "GENTLE": "Kind and soothing in nature",
  };

  int clueCounter = 1;
  List<Clue> acrossClues = [];
  List<Clue> downClues = [];

  int? selectedRow;
  int? selectedCol;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    _generateCrossword();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _generateCrossword() {
    hintsLeft = 5;
    grid = List.generate(
      gridSize,
      (_) => List.generate(gridSize, (_) => Cell()),
    );

    acrossClues.clear();
    downClues.clear();
    clueCounter = 1;
    selectedRow = null;
    selectedCol = null;

    final words = wordBank.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));

    final selected = words.take(15).toList();

    _placeFirstWord(selected.first);

    for (var word in selected.skip(1)) {
      _tryPlaceWord(word);
    }

    _numberClues();
    setState(() {});
  }

  void _placeFirstWord(String word) {
    int row = gridSize ~/ 2;
    int col = (gridSize - word.length) ~/ 2;

    for (int i = 0; i < word.length; i++) {
      grid[row][col + i].letter = word[i];
    }
  }

  void _tryPlaceWord(String word) {
    for (int attempt = 0; attempt < 300; attempt++) {
      int r = random.nextInt(gridSize);
      int c = random.nextInt(gridSize);

      if (grid[r][c].letter.isEmpty) continue;

      for (int i = 0; i < word.length; i++) {
        if (word[i] == grid[r][c].letter) {
          if (_canPlace(word, r, c, i, true)) {
            _placeWord(word, r, c, i, true);
            return;
          }
          if (_canPlace(word, r, c, i, false)) {
            _placeWord(word, r, c, i, false);
            return;
          }
        }
      }
    }

    for (int attempt = 0; attempt < 300; attempt++) {
      bool horizontal = random.nextBool();
      int r = random.nextInt(gridSize);
      int c = random.nextInt(gridSize);

      if (_canPlace(word, r, c, 0, horizontal)) {
        _placeWord(word, r, c, 0, horizontal);
        return;
      }
    }
  }

  bool _canPlace(String word, int r, int c, int index, bool horizontal) {
    int startRow = horizontal ? r : r - index;
    int startCol = horizontal ? c - index : c;

    if (startRow < 0 ||
        startCol < 0 ||
        (horizontal && startCol + word.length > gridSize) ||
        (!horizontal && startRow + word.length > gridSize)) {
      return false;
    }

    for (int i = 0; i < word.length; i++) {
      int rr = horizontal ? startRow : startRow + i;
      int cc = horizontal ? startCol + i : startCol;

      if (grid[rr][cc].letter.isNotEmpty && grid[rr][cc].letter != word[i]) {
        return false;
      }
    }
    return true;
  }

  void _placeWord(String word, int r, int c, int index, bool horizontal) {
    int startRow = horizontal ? r : r - index;
    int startCol = horizontal ? c - index : c;

    for (int i = 0; i < word.length; i++) {
      int rr = horizontal ? startRow : startRow + i;
      int cc = horizontal ? startCol + i : startCol;
      grid[rr][cc].letter = word[i];
    }
  }

  void _numberClues() {
    int acrossCount = 0;
    int downCount = 0;

    for (int r = 0; r < gridSize; r++) {
      for (int c = 0; c < gridSize; c++) {
        if (grid[r][c].letter.isEmpty) continue;

        bool startAcross =
            acrossCount < maxAcross &&
            (c == 0 || grid[r][c - 1].letter.isEmpty) &&
            (c + 1 < gridSize && grid[r][c + 1].letter.isNotEmpty);

        bool startDown =
            downCount < maxDown &&
            (r == 0 || grid[r - 1][c].letter.isEmpty) &&
            (r + 1 < gridSize && grid[r + 1][c].letter.isNotEmpty);

        String? acrossWord;
        String? downWord;

        if (startAcross) {
          final w = _extractWord(r, c, true);
          if (wordBank.containsKey(w)) {
            acrossWord = w;
          }
        }

        if (startDown) {
          final w = _extractWord(r, c, false);
          if (wordBank.containsKey(w)) {
            downWord = w;
          }
        }

        if (acrossWord != null || downWord != null) {
          grid[r][c].number = clueCounter;

          if (acrossWord != null && acrossCount < maxAcross) {
            acrossClues.add(Clue(clueCounter, wordBank[acrossWord]!));
            acrossCount++;
          }

          if (downWord != null && downCount < maxDown) {
            downClues.add(Clue(clueCounter, wordBank[downWord]!));
            downCount++;
          }

          clueCounter++;
        }

        if (acrossCount == maxAcross && downCount == maxDown) return;
      }
    }
  }

  bool _isCellPartOfNumberedWord(int r, int c) {
    // Check if this cell is part of any across word that starts with a number
    int checkCol = c;
    while (checkCol > 0 && grid[r][checkCol - 1].letter.isNotEmpty) {
      checkCol--;
    }
    if (grid[r][checkCol].number != null) {
      // Verify the word from this numbered cell is in our clues
      String word = _extractWord(r, checkCol, true);
      if (wordBank.containsKey(word)) return true;
    }

    // Check if this cell is part of any down word that starts with a number
    int checkRow = r;
    while (checkRow > 0 && grid[checkRow - 1][c].letter.isNotEmpty) {
      checkRow--;
    }
    if (grid[checkRow][c].number != null) {
      // Verify the word from this numbered cell is in our clues
      String word = _extractWord(checkRow, c, false);
      if (wordBank.containsKey(word)) return true;
    }

    return false;
  }

  bool _isValidCrosswordCell(int r, int c) {
    if (grid[r][c].letter.isEmpty) return false;

    // Only show cells that are part of numbered words
    return _isCellPartOfNumberedWord(r, c);
  }

  String _extractWord(int r, int c, bool horizontal) {
    String word = "";
    while (r < gridSize && c < gridSize && grid[r][c].letter.isNotEmpty) {
      word += grid[r][c].letter;
      horizontal ? c++ : r++;
    }
    return word;
  }

  void _giveHint() {
    if (hintsLeft <= 0) {
      Sound.playTap();
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            "Oops :(",
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text(
            "No more hints left for this game.",
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            GestureDetector(
              onTap: () {
                Sound.playTap();
                Navigator.pop(context);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF5D4037),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Text(
                  "OK",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
      return;
    }

    if (selectedRow == null || selectedCol == null) return;

    final cell = grid[selectedRow!][selectedCol!];

    // Ignore empty or already-correct cells
    if (cell.letter.isEmpty || cell.isCorrect) return;

    // Only hint numbered crossword cells
    if (!_isCellPartOfNumberedWord(selectedRow!, selectedCol!)) return;

    setState(() {
      cell.userLetter = cell.letter;
      cell.controller.text = cell.letter;
      hintsLeft--; // 🔻 use 1 hint
    });

    // After hint, re-check word completion
    if (_hasAcrossWord(selectedRow!, selectedCol!) &&
        !_hasDownWord(selectedRow!, selectedCol!)) {
      _checkWordAt(selectedRow!, selectedCol!, true);
    } else if (_hasDownWord(selectedRow!, selectedCol!) &&
        !_hasAcrossWord(selectedRow!, selectedCol!)) {
      _checkWordAt(selectedRow!, selectedCol!, false);
    } else {
      _checkWordAt(selectedRow!, selectedCol!, true);
    }

    _checkPuzzleCompleted();
  }

  void _checkPuzzleCompleted() {
    for (int r = 0; r < gridSize; r++) {
      for (int c = 0; c < gridSize; c++) {
        if (!_isValidCrosswordCell(r, c)) continue;

        if (grid[r][c].userLetter != grid[r][c].letter) {
          return; // ❌ not complete
        }
      }
    }

    if (!puzzleCompleted) {
      puzzleCompleted = true;
      _confettiController.play();
      _showCompletedDialog();
    }
  }

  void _checkWordAt(int r, int c, bool horizontal) {
    int sr = r;
    int sc = c;

    while (horizontal && sc > 0 && grid[r][sc - 1].letter.isNotEmpty) sc--;
    while (!horizontal && sr > 0 && grid[sr - 1][c].letter.isNotEmpty) sr--;

    // 🚫 Block single-letter words
    int length = 0;
    int tr = sr, tc = sc;
    while (tr < gridSize && tc < gridSize && grid[tr][tc].letter.isNotEmpty) {
      length++;
      horizontal ? tc++ : tr++;
    }
    if (length < 2) return;

    // ✅ Ensure all cells are filled
    int rr = sr, cc = sc;
    while (rr < gridSize && cc < gridSize && grid[rr][cc].letter.isNotEmpty) {
      if (grid[rr][cc].userLetter.isEmpty) return;
      horizontal ? cc++ : rr++;
    }

    // ✅ Build words
    String correct = "";
    String user = "";

    rr = sr;
    cc = sc;
    while (rr < gridSize && cc < gridSize && grid[rr][cc].letter.isNotEmpty) {
      correct += grid[rr][cc].letter;
      user += grid[rr][cc].userLetter;
      horizontal ? cc++ : rr++;
    }

    // ✅ Reward only if fully correct
    if (user != correct) return;

    rr = sr;
    cc = sc;
    while (rr < gridSize && cc < gridSize && grid[rr][cc].letter.isNotEmpty) {
      grid[rr][cc].isCorrect = true;
      horizontal ? cc++ : rr++;
    }
  }

  bool _hasAcrossWord(int r, int c) {
    return (c > 0 && grid[r][c - 1].letter.isNotEmpty) ||
        (c + 1 < gridSize && grid[r][c + 1].letter.isNotEmpty);
  }

  bool _hasDownWord(int r, int c) {
    return (r > 0 && grid[r - 1][c].letter.isNotEmpty) ||
        (r + 1 < gridSize && grid[r + 1][c].letter.isNotEmpty);
  }

  void _moveToNextCell(int r, int c) {
    if (isAcrossMode) {
      // Move RIGHT
      if (c + 1 < gridSize && _isValidCrosswordCell(r, c + 1)) {
        _focusCell(r, c + 1);
      }
    } else {
      // Move DOWN
      if (r + 1 < gridSize && _isValidCrosswordCell(r + 1, c)) {
        _focusCell(r + 1, c);
      }
    }
  }

  void _focusCell(int r, int c) {
    if (!_isValidCrosswordCell(r, c)) return;

    setState(() {
      selectedRow = r;
      selectedCol = c;
    });

    FocusScope.of(context).requestFocus(grid[r][c].focusNode);
  }

  void _showCompletedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Puzzle Completed! 🧩", textAlign: TextAlign.center),
        content: const Text(
          "Great job! You solved the crossword.",
          textAlign: TextAlign.center,
        ),
        actionsPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        actions: [
          Row(
            children: [
              /// ❌ QUIT
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Sound.playTap();
                    Navigator.pop(context); // close dialog
                    Navigator.pop(context, true); // ✅ notify Garden: SUCCESS
                  },

                  child: Container(
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8DED4), // light brown
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Text(
                      "Quit",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF5D4037), // dark brown
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              /// 🔁 PLAY AGAIN
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Sound.playTap();
                    Navigator.pop(context);
                    setState(() {
                      puzzleCompleted = false;
                      _generateCrossword();
                    });
                  },
                  child: Container(
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF8D6E63), // brown
                          Color(0xFF5D4037), // dark brown
                        ],
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
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // Background Image
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/box1.png"),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Main Content (slides up with keyboard)
          // 🔹 MAIN CONTENT (scrolls + moves up with keyboard)
          SingleChildScrollView(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(
                context,
              ).viewInsets.bottom, // keyboard space
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 🔹 TITLE + GRID (anchored near top)
                Padding(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 15,
                  ),
                  child: Column(
                    children: [
                      // 🔹 HEADER BUTTONS (NOW STUCK LIKE title.png)
                      Padding(
                        padding: const EdgeInsets.only(
                          top: 8, // ✅ no extra top space
                          left: 12,
                          right: 12,
                        ),

                        child: Row(
                          children: [
                            // 🔙 BACK
                            GestureDetector(
                              onTap: () {
                                Sound.playTap();
                                Navigator.pop(context);
                              },
                              child: Image.asset(
                                "assets/back.png",
                                width: 62,
                                height: 52,
                              ),
                            ),

                            const Spacer(),

                            // ℹ️ INFO
                            GestureDetector(
                              onTap: () {
                                Sound.playTap();
                                setState(() {
                                  showInstructions = true;
                                });
                              },
                              child: Image.asset(
                                "assets/info.png",
                                width: 40,
                                height: 40,
                              ),
                            ),

                            const SizedBox(width: 6),

                            // 🔄 REFRESH
                            GestureDetector(
                              onTap: () {
                                Sound.playTap();
                                _generateCrossword();
                              },
                              child: const Icon(
                                Icons.refresh,
                                size: 32,
                                color: Colors.black,
                              ),
                            ),

                            const SizedBox(width: 10),

                            // 💡 HINT
                            GestureDetector(
                              onTap: () {
                                Sound.playTap();
                                _giveHint();
                              },
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  const Icon(
                                    Icons.lightbulb_outline,
                                    size: 32,
                                    color: Colors.black,
                                  ),
                                  Positioned(
                                    bottom: -2,
                                    right: -2,
                                    child: Text(
                                      "$hintsLeft",
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      /// 🔹 TITLE
                      Image.asset(
                        "assets/title.png",
                        width: 170,
                        fit: BoxFit.contain,
                      ),

                      const SizedBox(height: 8),

                      /// 🔹 CROSSWORD GRID
                      LayoutBuilder(
                        builder: (context, constraints) {
                          const double gridPadding = 16;
                          final double cellSize =
                              (constraints.maxWidth - gridPadding * 2) /
                              gridSize;

                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: GridView.builder(
                              shrinkWrap: true, // 🔥 IMPORTANT
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: gridSize,
                                    childAspectRatio: 1,
                                  ),
                              itemCount: gridSize * gridSize,
                              itemBuilder: (context, index) {
                                int r = index ~/ gridSize;
                                int c = index % gridSize;

                                if (!_isValidCrosswordCell(r, c)) {
                                  return const SizedBox();
                                }

                                return _buildCell(grid[r][c], r, c, cellSize);
                              },
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // 🔹 CLUES
                Padding(
                  padding: const EdgeInsets.fromLTRB(3, 0, 10, 16),
                  child: _buildClues(),
                ),
              ],
            ),
          ),

          // Back Button
          // Positioned(
          //   top: MediaQuery.of(context).padding.top + 8,
          //   left: 12,
          //   child: GestureDetector(
          //     onTap: () {
          //       Sound.playTap();
          //       Navigator.pop(context);
          //     },
          //     child: Image.asset("assets/back.png", width: 62, height: 52),
          //   ),
          // ),

          // ℹ️ + Refresh + Hint (VERTICAL STACK)
          // ℹ️ + 🔄 + 💡 layout
          // Positioned(
          //   top: MediaQuery.of(context).padding.top + 8,
          //   right: 12,
          //   child: SizedBox(
          //     width: 90,
          //     height: 110,
          //     child: Column(
          //       children: [
          //         // 🔝 Top row → Info & Refresh
          //         Row(
          //           children: [
          //             const Spacer(), // ⬅️ pushes icons to the right
          //             // ℹ️ INFO
          //             GestureDetector(
          //               onTap: () {
          //                 Sound.playTap();
          //                 setState(() {
          //                   showInstructions = true;
          //                 });
          //               },
          //               child: Image.asset(
          //                 "assets/info.png",
          //                 width: 40,
          //                 height: 40,
          //               ),
          //             ),

          //             const SizedBox(width: 6), // 🔹 small gap
          //             // 🔄 REFRESH
          //             GestureDetector(
          //               onTap: () {
          //                 Sound.playTap();
          //                 _generateCrossword();
          //               },
          //               child: const Icon(
          //                 Icons.refresh,
          //                 size: 32,
          //                 color: Colors.black,
          //               ),
          //             ),
          //           ],
          //         ),

          //         const SizedBox(height: 12),

          //         // 💡 HINT (aligned under refresh)
          //         Align(
          //           alignment: Alignment.centerRight,
          //           child: GestureDetector(
          //             onTap: () {
          //               Sound.playTap();
          //               _giveHint();
          //             },
          //             child: Stack(
          //               clipBehavior: Clip.none,
          //               children: [
          //                 const Icon(
          //                   Icons.lightbulb_outline,
          //                   size: 32,
          //                   color: Colors.black,
          //                 ),
          //                 Positioned(
          //                   bottom: -2, // adjust for perfect placement
          //                   right: -2,
          //                   child: Text(
          //                     "$hintsLeft",
          //                     style: const TextStyle(
          //                       fontSize: 12,
          //                       fontWeight: FontWeight.bold,
          //                     ),
          //                   ),
          //                 ),
          //               ],
          //             ),
          //           ),
          //         ),
          //       ],
          //     ),
          //   ),
          // ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              emissionFrequency: 0.05,
              numberOfParticles: 30,
              gravity: 0.2,
            ),
          ),
          // 📜 CROSSWORD INSTRUCTIONS
          if (showInstructions)
            Instructions(
              game: "crossword",
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

  Widget _buildCell(Cell cell, int r, int c, double size) {
    return Container(
      margin: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        color: cell.isCorrect
            ? Colors.green.shade200
            : (selectedRow == r && selectedCol == c)
            ? Colors.yellow.shade200
            : const Color(0xFFFFFDE7),

        border: Border.all(color: Colors.black54),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Stack(
        children: [
          if (cell.number != null)
            Positioned(
              top: 2,
              left: 2,
              child: Text(
                cell.number.toString(),
                style: TextStyle(
                  fontSize: size * 0.45,
                  color: Colors.black54,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          Center(
            child: TextField(
              focusNode: cell.focusNode,
              maxLength: 1,
              textAlign: TextAlign.center,
              controller: cell.controller,

              // 🔒 LOCK when correct
              readOnly: cell.isCorrect,
              enableInteractiveSelection: !cell.isCorrect,

              style: TextStyle(
                fontSize: size * 0.55,
                fontWeight: FontWeight.bold,
                color: cell.isCorrect ? Colors.black : Colors.black,
              ),

              onTap: cell.isCorrect
                  ? null
                  : () {
                      setState(() {
                        selectedRow = r;
                        selectedCol = c;

                        bool hasAcross = _hasAcrossWord(r, c);
                        bool hasDown = _hasDownWord(r, c);

                        if (hasAcross && !hasDown) {
                          isAcrossMode = true;
                        } else if (hasDown && !hasAcross) {
                          isAcrossMode = false;
                        }
                        // if both exist → keep previous direction
                      });

                      FocusScope.of(context).requestFocus(cell.focusNode);
                    },

              onChanged: cell.isCorrect
                  ? null
                  : (v) {
                      if (v.isEmpty) return;

                      setState(() {
                        cell.userLetter = v.toUpperCase();
                        cell.controller.text = cell.userLetter;

                        _checkWordAt(r, c, true);
                        _checkWordAt(r, c, false);
                      });

                      _checkPuzzleCompleted();

                      // 🔥 AUTO MOVE TO NEXT CELL
                      // Decide typing direction if not decided yet
                      if (_hasAcrossWord(r, c) && !_hasDownWord(r, c)) {
                        isAcrossMode = true;
                      } else if (_hasDownWord(r, c) && !_hasAcrossWord(r, c)) {
                        isAcrossMode = false;
                      }

                      _moveToNextCell(r, c);
                    },

              decoration: const InputDecoration(
                border: InputBorder.none,
                counterText: "",
                isCollapsed: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClues() {
    final int maxRows = max(acrossClues.length, downClues.length).clamp(0, 6);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      child: Table(
        columnWidths: const {0: FlexColumnWidth(1), 1: FlexColumnWidth(1)},
        border: TableBorder.symmetric(
          inside: BorderSide(color: Colors.black26),
        ),
        children: [
          /// 🔹 HEADER ROW
          TableRow(
            decoration: BoxDecoration(
              color: const Color.fromARGB(200, 130, 74, 5),
            ),
            children: const [
              Padding(
                padding: EdgeInsets.all(8),
                child: Text(
                  "Across",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(8),
                child: Text(
                  "Down",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),

          /// 🔹 CLUE ROWS
          for (int i = 0; i < maxRows; i++)
            TableRow(
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.8)),

              children: [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    i < acrossClues.length
                        ? "${acrossClues[i].number}. ${acrossClues[i].clue}"
                        : "",
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    i < downClues.length
                        ? "${downClues[i].number}. ${downClues[i].clue}"
                        : "",
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class Cell {
  String letter = "";
  String userLetter = "";
  int? number;
  bool isCorrect = false;
  final TextEditingController controller = TextEditingController();
  final FocusNode focusNode = FocusNode();
}

class Clue {
  final int number;
  final String clue;
  Clue(this.number, this.clue);
}
