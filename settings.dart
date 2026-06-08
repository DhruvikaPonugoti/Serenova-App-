import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/music.dart';
import '../services/sound.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

Future<void> _openEmail() async {
  final Uri emailUri = Uri.parse(
    "mailto:serenovatech@gmail.com?subject=Support%20Request%20-%20Serenova",
  );

  try {
    await launchUrl(emailUri, mode: LaunchMode.externalApplication);
  } catch (e) {
    debugPrint("Error opening email: $e");
  }
}

class _SettingsState extends State<Settings> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // 🔁 App came back to foreground
      if (Music.musicOn) {
        Music.play();
      }
    }
  }

  void logout(BuildContext context) async {
    Sound.playTap();

    // ⛔ Stop background music
    await Music.stop();

    // 🔇 Optional: also stop tap sounds if needed
    // Sound.setSound(false);

    await FirebaseAuth.instance.signOut();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const Login()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // 🔥 Dashboard BG

      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        centerTitle: true,

        leadingWidth: 80,
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
          "Settings",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
      ),

      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          // 👤 MY ACCOUNT
          _cardTile(
            icon: Icons.person,
            title: "My Account",
            onTap: () {
              Sound.playTap();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MyAccountPage()),
              );
            },
          ),

          const SizedBox(height: 14),

          // 🎵 MUSIC
          _switchCard(
            icon: Icons.music_note,
            title: "Music",
            value: Music.musicOn, // 👈 not local bool
            onChanged: (value) async {
              Sound.playTap();
              setState(() {});
              Music.setMusic(value);
            },
          ),

          const SizedBox(height: 14),

          // 🔊 SOUND
          _switchCard(
            icon: Icons.volume_up,
            title: "Sound",
            value: Sound.soundOn,
            onChanged: (value) {
              setState(() {
                Sound.setSound(value);
              });
              Sound.playTap();
            },
          ),

          const SizedBox(height: 14),

          // ❓ FAQs
          _expansionCard(
            icon: Icons.question_answer,
            title: "FAQs",
            children: const [
              _FaqItem(
                q: "What is Serenova?",
                a: "Serenova is a mental wellness app designed to support emotional balance.",
              ),
              _FaqItem(
                q: "Do I need internet access to use Serenova?",
                a: "Some features may require an internet connection for secure authentication and data storage.",
              ),
              _FaqItem(
                q: "Who can use Serenova?",
                a: "Anyone who wants to reflect on their emotions, build healthier habits, or simply maintain daily emotional balance can use it.",
              ),
              _FaqItem(
                q: "Does Serenova require technical knowledge?",
                a: "No. The app is designed to be simple and accessible for all users.",
              ),
            ],
          ),

          const SizedBox(height: 14),

          // 🆘 HELP & SUPPORT
          _expansionCard(
            icon: Icons.support_agent,
            title: "Help & Support",
            children: [
              Text(
                "For more details or assistance, contact us via email:",
                style: TextStyle(color: Colors.white70),
              ),
              SizedBox(height: 6),
              GestureDetector(
                onTap: () {
                  Sound.playTap();
                  _openEmail();
                },
                child: const Text(
                  "serenovatech@gmail.com",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.greenAccent,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 30),

          // 🔴 LOGOUT
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: () => logout(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              child: const Text(
                "Logout",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===================================================
  // 🧩 UI HELPERS
  // ===================================================

  Widget _cardTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      color: const Color(0xFF020617),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ListTile(
        leading: Icon(icon, color: Colors.white),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.white,
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _switchCard({
    required IconData icon,
    required String title,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Card(
      color: const Color(0xFF020617),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: SwitchListTile(
        secondary: Icon(icon, color: Colors.white),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        value: value,
        onChanged: onChanged,
      ),
    );
  }

  Widget _expansionCard({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      color: const Color(0xFF020617),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ExpansionTile(
        leading: Icon(icon, color: Colors.white),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),

        // 🔥 REMOVE the two horizontal divider lines
        shape: const Border(),
        collapsedShape: const Border(),

        iconColor: Colors.white,
        collapsedIconColor: Colors.white,
        childrenPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        children: children,
      ),
    );
  }
}

// ===================================================
// 👤 MY ACCOUNT PAGE
// ===================================================
class MyAccountPage extends StatelessWidget {
  const MyAccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // same as dashboard
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        centerTitle: true,

        leadingWidth: 80,
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
          "My Account",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 👤 NAME
            const Text(
              "Name",
              style: TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),

            Text(
              user?.displayName ?? "Not set",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 26),

            // 📧 EMAIL
            const Text(
              "Account Email",
              style: TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),

            Text(
              user?.email ?? "No email found",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 30),

            GestureDetector(
              onTap: () {
                Sound.playTap();
                _showChangePasswordSheet(context);
              },
              child: const Text(
                "Change Password",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 67, 206, 85),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _passwordField(
    String hint,
    TextEditingController controller,
    bool isHidden,
    VoidCallback toggle,
  ) {
    return TextField(
      controller: controller,
      obscureText: isHidden,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white54),
        filled: true,
        fillColor: const Color(0xFF0F172A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            isHidden ? Icons.visibility_off : Icons.visibility,
            color: Colors.white70,
          ),
          onPressed: toggle,
        ),
      ),
    );
  }

  Future<void> _changePassword(
    BuildContext context,
    String current,
    String newPassword,
  ) async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null || user.email == null) return;

      // 🔐 Re-authenticate
      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: current,
      );

      await user.reauthenticateWithCredential(cred);

      // 🔄 Update password
      await user.updatePassword(newPassword);

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Password updated successfully"),
          backgroundColor: Colors.green,
        ),
      );
    } on FirebaseAuthException catch (e) {
      String msg = "Something went wrong";

      if (e.code == "invalid-credential") {
        msg = "Current password is incorrect";
      } else if (e.code == "weak-password") {
        msg = "New password is too weak";
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
    }
  }

  void _showChangePasswordSheet(BuildContext context) {
    final currentController = TextEditingController();
    final newController = TextEditingController();

    bool loading = false;
    bool hideCurrent = true;
    bool hideNew = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: const Color(0xFF020617),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Change Password",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 20),

                    _passwordField(
                      "Current Password",
                      currentController,
                      hideCurrent,
                      () => setState(() => hideCurrent = !hideCurrent),
                    ),

                    const SizedBox(height: 14),

                    _passwordField(
                      "New Password",
                      newController,
                      hideNew,
                      () => setState(() => hideNew = !hideNew),
                    ),

                    const SizedBox(height: 24),

                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () {
                              Sound.playTap();
                              Navigator.pop(context);
                            },
                            child: const Text(
                              "Cancel",
                              style: TextStyle(color: Colors.white70),
                            ),
                          ),
                        ),

                        Expanded(
                          child: ElevatedButton(
                            onPressed: loading
                                ? null
                                : () async {
                                    setState(() => loading = true);
                                    await _changePassword(
                                      context,
                                      currentController.text.trim(),
                                      newController.text.trim(),
                                    );
                                    setState(() => loading = false);
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.greenAccent.shade400,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: loading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.black,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    "Update",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ===================================================
// FAQ ITEM
// ===================================================
class _FaqItem extends StatelessWidget {
  final String q;
  final String a;

  const _FaqItem({required this.q, required this.a});

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: Text(
        q,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      iconColor: Colors.white,
      collapsedIconColor: Colors.white,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(a, style: const TextStyle(color: Colors.white70)),
        ),
      ],
    );
  }
}
