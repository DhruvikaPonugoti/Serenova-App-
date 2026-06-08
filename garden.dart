import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'word_puzzle.dart';
import 'mindfulness.dart';
import 'mmatch.dart';
import '../services/sound.dart';
import 'dart:ui';

class GardenSlot {
  final String journalId;
  final int slotIndex;
  final bool isFlower;
  final bool isLocked; // 🔒
  final bool isWeed; // 🌱

  GardenSlot({
    required this.journalId,
    required this.slotIndex,
    required this.isFlower,
    required this.isLocked,
    required this.isWeed,
  });
}

class Garden extends StatefulWidget {
  const Garden({super.key});

  @override
  State<Garden> createState() => _GardenState();
}

class _GardenState extends State<Garden> {
  bool _checkedUnblock = false;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text("User not logged in")));
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection("users")
                .doc(user.uid)
                .collection("journals")
                .orderBy("createdAt")
                .snapshots(),
            builder: (context, snapshot) {
              _checkedUnblock = false;
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return _lockedGarden();
              }

              final journals = snapshot.data!.docs;
              final slots = _buildSlots(journals);

              // 🔢 Calculate global flowers & weeds
              int totalFlowers = 0;
              int totalWeeds = 0;

              for (final doc in journals) {
                final data = doc.data() as Map<String, dynamic>;
                final int flowers = data["flowers"] ?? 0;
                final int weeds = data["weeds"] ?? 0;
                final List completed = data["completedSlots"] ?? [];

                totalFlowers += flowers + completed.length;
                final remainingWeeds = weeds - completed.length;
                if (remainingWeeds > 0) totalWeeds += remainingWeeds;
              }
              if (!_checkedUnblock) {
                _checkedUnblock = true;

                FirebaseFirestore.instance
                    .collection("users")
                    .doc(user.uid)
                    .get()
                    .then((snap) {
                      final wasBlocked = snap.data()?["wasBlocked"] ?? false;

                      if (wasBlocked && totalWeeds * 2 <= totalFlowers) {
                        _showUnblockedPopup(context);

                        FirebaseFirestore.instance
                            .collection("users")
                            .doc(user.uid)
                            .update({"wasBlocked": false});
                      }
                    });
              }

              final int gardensNeeded = (slots.length / 5).ceil();

              // 🔹 TOTAL GROWTH (ACCUMULATED)

              return ListView.builder(
                reverse: true,
                itemCount: gardensNeeded,
                itemBuilder: (context, index) {
                  return GardenTile(slots: slots, startIndex: index * 5);
                },
              );
            },
          ),

          // 🔙 BACK BUTTON
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 12,
            child: GestureDetector(
              onTap: () {
                Navigator.pop(context);
                Sound.playTap();
              },
              child: Image.asset("assets/back.png", width: 62, height: 52),
            ),
          ),
        ],
      ),
    );
  }

  List<GardenSlot> _buildSlots(List<QueryDocumentSnapshot> journals) {
    final List<GardenSlot> slots = [];

    for (final doc in journals) {
      final data = doc.data() as Map<String, dynamic>;
      final String journalId = doc.id;

      final int flowers = (data["flowers"] ?? 0) as int;
      final List completed = data["completedSlots"] ?? [];

      const int totalSlots = 3;

      for (int i = 0; i < totalSlots; i++) {
        final bool emotionFlower = i < flowers; // 🌸 ML prediction
        final bool gameFixed = completed.contains(i); // 🎮 healed weed

        final bool isFlower = emotionFlower || gameFixed;
        final bool isWeed = !isFlower;

        slots.add(
          GardenSlot(
            journalId: journalId,
            slotIndex: i,
            isFlower: isFlower,
            isWeed: isWeed,
            isLocked: false,
          ),
        );
      }
    }

    return slots;
  }

  Widget _lockedGarden() {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset("assets/mgarden.png", fit: BoxFit.cover),
        ),
        Container(color: Colors.black.withOpacity(0.3)),
        const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_rounded, size: 64, color: Colors.white),
              SizedBox(height: 16),
              Text(
                "Your garden is locked ",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                "Write your first journal\nto unlock and grow it",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color.fromARGB(255, 255, 255, 255),
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showUnblockedPopup(BuildContext context) {
    Future.delayed(Duration.zero, () {
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (_) {
          return AlertDialog(
            backgroundColor: const Color(0xFF0F172A),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              "🌸 Garden Healed!",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: const Text(
              "You've cleared enough weeds.\nYou can now write your journal again.",
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Sound.playTap();
                  Navigator.pop(context);
                },
                child: const Text(
                  "Continue",
                  style: TextStyle(color: Colors.greenAccent),
                ),
              ),
            ],
          );
        },
      );
    });
  }
}

///////////////////////////////////////////////////////////////////////////////
/// 🌿 SINGLE GARDEN IMAGE (5 SLOTS, FILLED PROGRESSIVELY)
///////////////////////////////////////////////////////////////////////////////

class GardenTile extends StatelessWidget {
  final List<GardenSlot> slots;
  final int startIndex;

  const GardenTile({required this.slots, required this.startIndex});

  static const List<FractionalOffset> pitOffsets = [
    FractionalOffset(0.40, 0.10),
    FractionalOffset(0.74, 0.32),
    FractionalOffset(0.27, 0.51),
    FractionalOffset(0.55, 0.72),
    FractionalOffset(0.91, 0.90),
  ];

  @override
  Widget build(BuildContext context) {
    final items = _buildItems(context);

    return SizedBox(
      height: 900,
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset("assets/mgarden.png", fit: BoxFit.cover),
          ),

          for (int i = 0; i < pitOffsets.length; i++)
            Align(alignment: pitOffsets[i], child: items[i]),
        ],
      ),
    );
  }

  Future<void> _openGameSelector(BuildContext context, GardenSlot slot) async {
    final selectedGame = await showDialog<Widget>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.3), // semi transparent overlay
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 30),
          child: Stack(
            children: [
              // 🌫 Blur Background
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15), // glass effect
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          " Heal the Weed 🌱",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 0, 0, 0),
                          ),
                        ),
                        const SizedBox(height: 25),

                        _glassGameButton(
                          context,
                          " Mindfulness",
                          const Mindfulness(),
                        ),

                        const SizedBox(height: 12),

                        _glassGameButton(
                          context,
                          " Crossword Puzzle",
                          const WordPuzzle(),
                        ),

                        const SizedBox(height: 12),

                        _glassGameButton(
                          context,
                          " Memory Match",
                          const MemoryMatch(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (selectedGame == null) return;

    final completed = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => selectedGame),
    );

    if (completed == true) {
      await FirebaseFirestore.instance
          .collection("users")
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .collection("journals")
          .doc(slot.journalId)
          .update({
            "completedSlots": FieldValue.arrayUnion([slot.slotIndex]),
          });
    }
  }

  Widget _glassGameButton(BuildContext context, String title, Widget game) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context, game);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 255, 255, 255).withOpacity(0.85),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
    );
  }

  // 🌱 CORE LOGIC — EMPTY SLOTS STAY EMPTY
  List<Widget> _buildItems(BuildContext context) {
    return List.generate(5, (index) {
      final slotIndex = startIndex + (4 - index);

      if (slotIndex >= slots.length) return const SizedBox();

      final slot = slots[slotIndex];

      return GestureDetector(
        onTap: () {
          Sound.playTap();
          if (slot.isWeed) {
            _openGameSelector(context, slot);
          }
        },
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),

          transitionBuilder: (child, animation) {
            return ScaleTransition(
              scale: Tween(begin: 0.4, end: 1.0).animate(
                CurvedAnimation(
                  parent: animation,
                  curve: Curves.elasticOut, // 🌱 growth feel
                ),
              ),
              child: FadeTransition(opacity: animation, child: child),
            );
          },

          child: Image.asset(
            slot.isFlower ? "assets/flower.png" : "assets/weed.png",
            key: ValueKey(slot.isFlower), // ⭐ REQUIRED
            width: slot.isFlower ? 100 : 80,
          ),
        ),
      );
    });
  }
}
