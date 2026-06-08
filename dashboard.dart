import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/sound.dart';

class Dashboard extends StatelessWidget {
  const Dashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text("User not logged in")));
    }

    final accountCreatedAt = user.metadata.creationTime ?? DateTime.now();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),

      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,

        leadingWidth: 80, // 👈 allows bigger back button

        leading: IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          icon: Image.asset(
            "assets/back.png",
            width: 62,
            height: 52,
            fit: BoxFit.contain,
          ),
          onPressed: () {
            Sound.playTap();
            Navigator.pop(context);
          },
        ),

        title: const Text(
          "Dashboard",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
      ),

      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection("users")
              .doc(user.uid)
              .collection("journals")
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snapshot.data!.docs;

            // -------------------------
            // JOURNAL (TIME BASED)
            // -------------------------
            List<DateTime> dates = [];
            Set<String> activeDays = {};
            int totalEntries = 0;

            // -------------------------
            // GARDEN (SLOT BASED)
            // -------------------------
            int totalGardenFlowers = 0;
            int totalGardenWeeds = 0;

            for (var doc in docs) {
              final data = doc.data() as Map<String, dynamic>;

              // ----- journal data -----
              totalEntries++;

              if (data["createdAt"] != null) {
                final Timestamp ts = data["createdAt"];
                final date = ts.toDate();
                dates.add(date);

                final dayKey = "${date.year}-${date.month}-${date.day}";
                activeDays.add(dayKey);
              }

              // ----- garden data -----
              final int mlFlowers = (data["flowers"] ?? 0);
              final List completed = data["completedSlots"] ?? [];

              const int totalSlots = 3;

              final int healed = completed.length;
              final int realFlowers = mlFlowers + healed;
              final int realWeeds = totalSlots - realFlowers;

              totalGardenFlowers += realFlowers;
              totalGardenWeeds += realWeeds;
            }

            // 🔹 These use DATE logic (unchanged)
            final streak = _calculateStreak(dates);
            final contributionMap = _contributionMap(dates);

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const TypingGreeting(),
                  const SizedBox(height: 24),

                  // STREAK, DAYS, ENTRIES
                  _statsRow(streak, activeDays.length, totalEntries),

                  const SizedBox(height: 24),

                  // TRACK GRID
                  _contributionGrid(contributionMap, accountCreatedAt),

                  const SizedBox(height: 32),

                  // PIE CHART (GARDEN ONLY)
                  _gardenPieChart(totalGardenFlowers, totalGardenWeeds),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // =====================================================
  // 🔥 STATS
  // =====================================================
  Widget _statsRow(int streak, int active, int total) {
    return Row(
      children: [
        Expanded(child: _fixedStatBox("🔥 Streak", "$streak")),
        const SizedBox(width: 12),
        Expanded(child: _fixedStatBox("📅 Active Days", "$active")),
        const SizedBox(width: 12),
        Expanded(child: _fixedStatBox("📝 Entries", "$total")),
      ],
    );
  }

  Widget _fixedStatBox(String title, String value) {
    return SizedBox(
      height: 90, // 🔥 SAME HEIGHT FOR ALL
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF020617),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // 🔥 centers content
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 2, // 🔒 prevents height change
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // 🟩 DAILY TRACK WITH MONTH LABELS
  // =====================================================
  Widget _contributionGrid(Map<DateTime, int> data, DateTime accountCreatedAt) {
    final today = DateTime.now();
    final startDate = _normalize(accountCreatedAt);

    final days = <DateTime>[];
    for (
      DateTime d = startDate;
      !d.isAfter(today);
      d = d.add(const Duration(days: 1))
    ) {
      days.add(d);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Daily Track",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),

        // Month labels
        Row(children: _buildMonthLabels(days)),
        const SizedBox(height: 6),

        SizedBox(
          height: 110,
          child: GridView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: days.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
            ),
            itemBuilder: (context, index) {
              final day = days[index];
              final count = data[_normalize(day)] ?? 0;

              return Container(
                decoration: BoxDecoration(
                  color: _intensityColor(count),
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  List<Widget> _buildMonthLabels(List<DateTime> days) {
    final labels = <Widget>[];
    DateTime? lastMonth;

    for (int i = 0; i < days.length; i++) {
      final d = days[i];
      if (lastMonth == null || d.month != lastMonth.month) {
        labels.add(
          Padding(
            padding: const EdgeInsets.only(right: 24),
            child: Text(
              _monthName(d.month),
              style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
            ),
          ),
        );
        lastMonth = d;
      }
    }
    return labels;
  }

  Color _intensityColor(int count) {
    if (count == 0) return const Color(0xFF020617);
    if (count == 1) return Colors.green.shade900;
    if (count == 2) return Colors.green.shade700;
    if (count == 3) return Colors.green.shade500;
    return Colors.greenAccent;
  }

  // =====================================================
  // 🌱 PIE CHART
  // =====================================================
  Widget _gardenPieChart(int flowers, int weeds) {
    final bool isEmpty = flowers == 0 && weeds == 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Your Garden",
          style: TextStyle(
            fontSize: 18,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        if (isEmpty)
          _emptyGardenState()
        else
          Column(
            children: [
              SizedBox(
                height: 220,
                child: PieChart(
                  PieChartData(
                    centerSpaceRadius: 45,
                    sectionsSpace: 4,
                    sections: [
                      PieChartSectionData(
                        value: flowers.toDouble(),
                        title: "Flowers",
                        color: Colors.greenAccent,
                        radius: 60,
                      ),
                      PieChartSectionData(
                        value: weeds.toDouble(),
                        title: "Weeds",
                        color: Colors.redAccent,
                        radius: 60,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _gardenCount(
                    color: Colors.greenAccent,
                    label: "Flowers",
                    value: flowers,
                  ),
                  _gardenCount(
                    color: Colors.redAccent,
                    label: "Weeds",
                    value: weeds,
                  ),
                ],
              ),
            ],
          ),
      ],
    );
  }

  Widget _emptyGardenState() {
    return Container(
      height: 220,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF020617),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.local_florist, size: 42, color: Colors.greenAccent),
          const SizedBox(height: 12),
          const Text(
            "Your garden is empty",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Start journaling to grow flowers\nand clear weeds",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _gardenCount({
    required Color color,
    required String label,
    required int value,
  }) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
        ),
      ],
    );
  }

  // =====================================================
  // 🔢 CALCULATIONS
  // =====================================================
  DateTime _normalize(DateTime d) => DateTime(d.year, d.month, d.day);

  // int _activeDays(List<DateTime> dates) => dates.map(_normalize).toSet().length;

  int _calculateStreak(List<DateTime> dates) {
    if (dates.isEmpty) return 0;

    final uniqueDays = dates.map(_normalize).toSet().toList()
      ..sort((a, b) => b.compareTo(a));

    int streak = 1;
    for (int i = 1; i < uniqueDays.length; i++) {
      if (uniqueDays[i - 1].difference(uniqueDays[i]).inDays == 1) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  Map<DateTime, int> _contributionMap(List<DateTime> dates) {
    final map = <DateTime, int>{};
    for (var d in dates) {
      final day = _normalize(d);
      map[day] = (map[day] ?? 0) + 1;
    }
    return map;
  }

  String _monthName(int m) {
    const months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];
    return months[m - 1];
  }
}

class TypingGreeting extends StatefulWidget {
  const TypingGreeting({super.key});

  @override
  State<TypingGreeting> createState() => _TypingGreetingState();
}

class _TypingGreetingState extends State<TypingGreeting> {
  String _displayedText = "";
  int _currentIndex = 0;
  late String _fullText;

  bool _showCursor = true;
  bool _typingDone = false;

  @override
  void initState() {
    super.initState();

    final user = FirebaseAuth.instance.currentUser;
    final name = user?.displayName?.trim();

    _fullText = name != null && name.isNotEmpty ? "Hello, $name !" : "Hello !";

    _startTyping();
    _startCursorBlink();
  }

  void _startTyping() {
    const typingSpeed = Duration(milliseconds: 150);

    Future.doWhile(() async {
      await Future.delayed(typingSpeed);

      if (_currentIndex < _fullText.length) {
        setState(() {
          _displayedText += _fullText[_currentIndex];
          _currentIndex++;
        });
        return true;
      } else {
        setState(() {
          _typingDone = true;
          _showCursor = false; // 👈 stop cursor
        });
        return false;
      }
    });
  }

  void _startCursorBlink() {
    const blinkSpeed = Duration(milliseconds: 450);

    Future.doWhile(() async {
      await Future.delayed(blinkSpeed);

      if (_typingDone) return false;

      setState(() {
        _showCursor = !_showCursor;
      });
      return true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: GoogleFonts.poppins(
          fontSize: 26,
          fontWeight: FontWeight.bold,
          fontStyle: FontStyle.italic,
          color: const Color.fromARGB(255, 133, 255, 117),
        ),
        children: [
          TextSpan(text: _displayedText),
          if (!_typingDone && _showCursor) const TextSpan(text: "|"),
        ],
      ),
    );
  }
}
