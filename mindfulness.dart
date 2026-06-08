import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../services/sound.dart';
import '../services/music.dart';
import 'ginst.dart';

class Mindfulness extends StatefulWidget {
  const Mindfulness({super.key});

  @override
  State<Mindfulness> createState() => _MindfulnessState();
}

class _MindfulnessState extends State<Mindfulness> {
  final AudioPlayer _player = AudioPlayer();
  bool _musicWasOn = false;
  bool showInstructions = false;

  Timer? _timer;
  int _selectedMinutes = 3;
  int _remainingSeconds = 180;
  bool _isRunning = false;

  final Map<int, String> _audioMap = {
    3: "vid3.mp3",
    5: "vid5.mp3",
    10: "vid10.mp3",
  };

  @override
  void initState() {
    super.initState();

    // 🎵 Save current music state
    _musicWasOn = Music.musicOn;

    // ⛔ Stop background music when mindfulness starts
    Music.stop();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _player.dispose();

    // 🔄 Restore music if user had it ON
    if (_musicWasOn) {
      Music.play();
    }

    super.dispose();
  }

  Future<void> _startTimer() async {
    if (_isRunning) return;

    final audioPath = _audioMap[_selectedMinutes]!;

    await _player.stop();
    await _player.play(AssetSource(audioPath));

    setState(() => _isRunning = true);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        _completeSession();
      }
    });
  }

  Future<void> _pauseTimer() async {
    _timer?.cancel();
    await _player.pause();
    setState(() => _isRunning = false);
  }

  Future<void> _stopTimer() async {
    _timer?.cancel();
    await _player.stop();
    setState(() {
      _isRunning = false;
      _remainingSeconds = _selectedMinutes * 60;
    });
  }

  void _playAgain() {
    setState(() {
      _remainingSeconds = _selectedMinutes * 60;
    });
    _startTimer();
  }

  Future<void> _completeSession() async {
    _timer?.cancel();
    await _player.stop();
    setState(() => _isRunning = false);

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Time Well Spent!", textAlign: TextAlign.center),
        content: const Text(
          "Your mindfulness session is done.\nWould you like to continue?",
          textAlign: TextAlign.center,
        ),
        actionsPadding: const EdgeInsets.all(16),
        actions: [
          Row(
            children: [
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
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Text("Quit"),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Sound.playTap();
                    Navigator.pop(context);
                    _playAgain();
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
                      style: TextStyle(color: Colors.white),
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

  String _formatTime(int seconds) {
    final min = seconds ~/ 60;
    final sec = seconds % 60;
    return "${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final progress = 1 - (_remainingSeconds / (_selectedMinutes * 60));

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          /// 🔹 BACKGROUND
          Positioned.fill(
            child: Image.asset("assets/med.jpg", fit: BoxFit.cover),
          ),

          /// 🔹 DARK OVERLAY
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.65)),
          ),

          /// 🔹 TOP BAR (FIXED — NO OVERLAP EVER)
          SizedBox(
            height: 130, // 👈 IMPORTANT: Stack needs height
            child: Stack(
              children: [
                /// 🔹 BACK ARROW
                Positioned(
                  top: 30,
                  left: 6,
                  child: GestureDetector(
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
                ),

                /// 🔹 TITLE IMAGE
                Positioned(
                  top: 80, // 👈 title top control
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Image.asset(
                      "assets/med_title.png",
                      height: 50,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),

                /// ℹ️ INFO BUTTON
                Positioned(
                  top: 42,
                  right: 12,
                  child: GestureDetector(
                    onTap: () {
                      Sound.playTap();
                      setState(() {
                        showInstructions = true;
                      });
                    },
                    child: Image.asset(
                      "assets/info.png",
                      width: 45,
                      height: 45,
                    ),
                  ),
                ),
              ],
            ),
          ),

          /// 🔹 CENTER CONTENT (TIMER ONLY)
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 220,
                      height: 220,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 10,
                        backgroundColor: Colors.green.shade100,
                        valueColor: AlwaysStoppedAnimation(
                          Colors.green.shade700,
                        ),
                      ),
                    ),
                    Text(
                      _formatTime(_remainingSeconds),
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),

                    // 📜 MINDFULNESS INSTRUCTIONS
                  ],
                ),

                const SizedBox(height: 30),

                /// TIME CHIPS
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [3, 5, 10].map((min) {
                    final isSelected = _selectedMinutes == min;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: ChoiceChip(
                        label: Text("$min min"),
                        selected: isSelected,
                        showCheckmark: false,
                        selectedColor: Colors.green.shade300,
                        onSelected: (_) {
                          Sound.playTap();
                          if (!_isRunning) {
                            setState(() {
                              _selectedMinutes = min;
                              _remainingSeconds = min * 60;
                            });
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 30),

                /// CONTROLS
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      iconSize: 48,
                      icon: Icon(
                        _isRunning ? Icons.pause_circle : Icons.play_circle,
                        color: Colors.green.shade300,
                      ),
                      onPressed: () {
                        if (_isRunning) {
                          _pauseTimer();
                        } else {
                          _startTimer();
                        }
                        Sound.playTap();
                      },
                    ),
                    const SizedBox(width: 20),
                    IconButton(
                      iconSize: 48,
                      icon: Icon(Icons.stop_circle, color: Colors.red.shade300),
                      onPressed: () {
                        _stopTimer();
                        Sound.playTap();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (showInstructions)
            Instructions(
              game: "mindfulness",
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
