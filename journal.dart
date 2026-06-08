import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'garden.dart';
import '../services/sound.dart';
import 'package:intl/intl.dart';


class Journal extends StatefulWidget {
  const Journal({super.key});

  @override
  State<Journal> createState() => _JournalState();
}

class _JournalState extends State<Journal> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _journalController = TextEditingController();

  bool isLoading = false;
  bool isGardenBlocked = false;
  bool justSubmitted = false; // 👈 allow one journal even if weeds spike

  // 🌱 Garden results
  int? flowers;
  int? weeds;

  // 🔹 Firestore previous entries
  List<QueryDocumentSnapshot<Map<String, dynamic>>> previousEntries = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    justSubmitted = false;
    fetchPreviousEntries();
  }

  /// ---------------- ANALYZE + SAVE JOURNAL ----------------
  Future<void> analyzeAndSaveJournal() async {
    final text = _journalController.text.trim();
    justSubmitted = true;

    if (text.isEmpty) return;

    setState(() => isLoading = true);

    try {
      // 🔹 Call FastAPI backend
      final response = await http.post(
        // Uri.parse("http://localhost:8000/analyze"),
        // Uri.parse("http://10.10.6.250:8000/analyze"),
        Uri.parse("https://serenova-ml.onrender.com/analyze"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"text": text}),
      );

      final data = jsonDecode(response.body);

      setState(() {
        flowers = data["flowers"];
        weeds = data["weeds"];
      });

      // 🔹 Save journal text to Firestore
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection("users")
            .doc(user.uid)
            .collection("journals")
            .add({
              "text": text,
              "flowers": flowers,
              "weeds": weeds,
              "createdAt": FieldValue.serverTimestamp(),
            });
      }

      _journalController.clear();
      fetchPreviousEntries();

      // ⏳ Let user see emotion result for a few seconds
      await Future.delayed(const Duration(seconds: 3));

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const Garden()),
      );
    } catch (e) {
      debugPrint("Error: $e");
    }

    setState(() => isLoading = false);
  }

  /// ---------------- FETCH PREVIOUS ENTRIES ----------------
  Future<void> fetchPreviousEntries() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .collection("journals")
        .orderBy("createdAt", descending: true)
        .get();

    final docs = snapshot.docs;

    final tempEntries = docs;

    int totalFlowers = 0;
    int totalWeeds = 0;

    for (final doc in tempEntries) {
      final data = doc.data();
      final int flowers = data["flowers"] ?? 0;
      final int weeds = data["weeds"] ?? 0;
      final List completed = data["completedSlots"] ?? [];

      totalFlowers += flowers + completed.length;

      final remainingWeeds = weeds - completed.length;
      if (remainingWeeds > 0) totalWeeds += remainingWeeds;
    }

    final bool blockedNow =
    !justSubmitted &&
    (totalWeeds * 2 > totalFlowers) &&
    tempEntries.isNotEmpty;

    setState(() {
      previousEntries = tempEntries;
      isGardenBlocked = blockedNow;
    });

    // 🔥 SAVE BLOCK STATE TO FIRESTORE
    if (blockedNow) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        FirebaseFirestore.instance.collection("users").doc(user.uid).set({
          "wasBlocked": true,
        }, SetOptions(merge: true));
      }
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true, // ⭐ important
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,

        leadingWidth: 56, // 👈 increase if needed

        leading: IconButton(
          padding: EdgeInsets.only(left: 7),
          constraints: const BoxConstraints(),
          icon: Image.asset(
            "assets/back.png",
            width: 62, // 👈 now this WILL change
            height: 52,
            fit: BoxFit.contain,
          ),
          onPressed: () {
            Sound.playTap();
            Navigator.pop(context);
          },
        ),

        title: const Text("Journal", style: TextStyle(color: Colors.white)),

        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: "Current Entry"),
            Tab(text: "Previous Entries"),
          ],
        ),
      ),

      body: Stack(
        children: [
          // 🌄 Shared background image
          Positioned.fill(
            child: Image.asset("assets/jbg.jpg", fit: BoxFit.cover),
          ),

          // 🌑 Overlay
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.3)),
          ),

          // 🔹 Tabs content
          TabBarView(
            controller: _tabController,
            children: [currentEntryTab(), previousEntriesTab()],
          ),
        ],
      ),
    );
  }

  /// ---------------- CURRENT ENTRY TAB ----------------
  Widget currentEntryTab() {
    return Stack(
      children: [
        // 🔹 Background image (same as previous tab)
        // Positioned.fill(
        //   child: Image.asset("assets/jbg.jpg", fit: BoxFit.cover),
        // ),

        // // 🔹 Dark overlay
        // Positioned.fill(child: Container(color: Colors.black.withOpacity(0.3))),

        // 🔹 Content
        SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            16,
            MediaQuery.of(context).padding.top + kToolbarHeight + 78,
            16,
            16,
          ),
          child: Column(
            children: [
              TextField(
                controller: _journalController,
                enabled: !isGardenBlocked,
                minLines: 4, // starting height
                maxLines: null, // 🔥 expands as user types
                keyboardType: TextInputType.multiline,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Write your thoughts here...",
                  hintStyle: const TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white70),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white),
                  ),
                  filled: true,
                  fillColor: Colors.black.withOpacity(0.4),
                ),
              ),

              const SizedBox(height: 16),

              ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () {
                        Sound.playTap();
                        analyzeAndSaveJournal();
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(248, 95, 0, 0),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Analyze & Save",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),

              const SizedBox(height: 20),

              if (flowers != null && weeds != null) emotionResult(),
            ],
          ),
        ),
        if (isGardenBlocked)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.6),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  margin: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(
                      255,
                      255,
                      255,
                      255,
                    ).withOpacity(0.95),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Your garden needs care 🥀",
                        style: TextStyle(
                          color: Color.fromARGB(255, 16, 16, 16),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "Clear some weeds by playing relaxing games before adding new thoughts.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color.fromARGB(179, 60, 59, 59),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          Sound.playTap();
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => const Garden()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(248, 0, 0, 0),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text("Go to Garden"),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// ---------------- EMOTION RESULT ----------------
  Widget emotionResult() {
    return Column(
      children: [
        Text(
          "Flowers to grow: $flowers",
          style: const TextStyle(fontSize: 16, color: Colors.white),
        ),
        Text(
          "Weeds to clear: $weeds",
          style: const TextStyle(fontSize: 16, color: Colors.white),
        ),
        const SizedBox(height: 10),
        Text(
          flowers! >= weeds!
              ? "Your garden feels hopeful today🌷"
              : "Your garden needs care 🪴",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color.fromARGB(255, 255, 255, 255),
          ),
        ),
      ],
    );
  }

  /// ---------------- PREVIOUS ENTRIES TAB ----------------
  Widget previousEntriesTab() {
    return Stack(
      children: [
        // 🔹 Background image for PREVIOUS ENTRIES
        Positioned.fill(
          child: Image.asset("assets/jbg2.jpg", fit: BoxFit.cover),
        ),

        // 🔹 Dark overlay
        Positioned.fill(child: Container(color: Colors.black.withOpacity(0.3))),

        // 🔹 Content
        Padding(
          padding: EdgeInsets.only(
            top:
                MediaQuery.of(context).padding.top +
                kToolbarHeight +
                48, // AppBar + TabBar
          ),
          child: previousEntries.isEmpty
              ? const Center(
                  child: Text(
                    "No previous journal entries",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: previousEntries.length,
                  itemBuilder: (context, index) {
                    final entry = previousEntries[index];

                    return Card(
                      color: Colors.black.withOpacity(0.6),
                      margin: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 6,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.book, color: Colors.white),
                        title: Text(
                          entry["text"],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Align(
                          alignment: Alignment.bottomRight,
                          child: Text(
                            entry["createdAt"] != null
                                ? DateFormat('dd MMM yyyy').format(
                                    (entry["createdAt"] as Timestamp).toDate(),
                                  )
                                : "",
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
