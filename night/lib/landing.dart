import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage>
    with SingleTickerProviderStateMixin {
  late VideoPlayerController _controller;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset("assets/videos/landing.mp4")
      ..initialize().then((_) {
        setState(() {});
        _controller.setLooping(true);
        _controller.play();
      });

    _animController =
    AnimationController(vsync: this, duration: const Duration(seconds: 1))
      ..forward();

    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _openUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception("Could not launch $uri");
    }
  }

  Future<String?> _fetchRegisterCode() async {
    try {
      final res = await http.get(Uri.parse("https://dark.nullxteam.fun/getCode"));
      if (res.statusCode == 200) {
        final jsonData = jsonDecode(res.body);
        return jsonData["code"]?.toString();
      }
    } catch (e) {
      debugPrint("Error fetching code: $e");
    }
    return null;
  }

  Future<void> _signInWith(String type) async {
    final code = await _fetchRegisterCode();
    if (code == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to get registration code.")),
      );
      return;
    }

    final message = Uri.encodeComponent("""
{ RavenGetSuzo }
Inspired By @permen_md
Type: Register
Code: $code
Role: Member
""");

    if (type == "whatsapp") {
      final whatsappUrl = "https://wa.me/6285135074300";
      await _openUrl(whatsappUrl);
    } else if (type == "telegram") {
      final telegramUrl = "https://t.me/kyyxXxror";
      await _openUrl(telegramUrl);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color darkRed = const Color(0xFF8B0000);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background video
          if (_controller.value.isInitialized)
            Positioned.fill(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller.value.size.width,
                  height: _controller.value.size.height,
                  child: ColorFiltered(
                    colorFilter: ColorFilter.mode(
                      Colors.black.withOpacity(0.4),
                      BlendMode.darken,
                    ),
                    child: VideoPlayer(_controller),
                  ),
                ),
              ),
            )
          else
            Container(color: Colors.black),

          // Overlay blur
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(color: Colors.black.withOpacity(0.3)),
            ),
          ),

          // Konten utama
          FadeTransition(
            opacity: _fadeAnim,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    // Logo
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Hero(
                        tag: "logo",
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.redAccent.withOpacity(0.4),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.asset(
                              "assets/images/logo.jpg",
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.security_rounded,
                                size: 50,
                                color: Colors.white70,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Video Glass card
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        width: double.infinity,
                        height: 200,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.15), width: 1),
                          color: Colors.white.withOpacity(0.08),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            _controller.value.isInitialized
                                ? ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: VideoPlayer(_controller),
                            )
                                : const Center(
                              child: CircularProgressIndicator(),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.4),
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                            Text(
                              "Tr4sFuck",
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                    offset: const Offset(0, 0),
                                    blurRadius: 12,
                                    color: Colors.redAccent.withOpacity(0.9),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    const Text(
                      "Choose sign-in method to continue",
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 30),

                    // Sign-in using Username
                    _buildButton(
                      label: "Sign-in using Username",
                      icon: Icons.person_outline,
                      color: darkRed,
                      onTap: () => Navigator.pushNamed(context, "/login"),
                    ),

                    const SizedBox(height: 16),

                    // Sign-in using Telegram
                    _buildButton(
                      label: "Sign-in using Telegram",
                      icon: FontAwesomeIcons.telegram,
                      color: Colors.blueAccent,
                      onTap: () => _signInWith("telegram"),
                    ),

                    const Spacer(),

                    // Footer glass
                    GlassFooter(
                      onTelegram: () => _openUrl("https://t.me/Tr4sFuck_bot/start"),
                      onTiktok: () =>
                          _openUrl("https://tiktok.com/@kyyxxror"),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        icon: FaIcon(icon, color: Colors.white),
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withOpacity(0.85),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 10,
          shadowColor: color,
        ),
        onPressed: onTap,
        label: Text(
          label,
          style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }
}

class GlassFooter extends StatelessWidget {
  final VoidCallback onTelegram;
  final VoidCallback onTiktok;

  const GlassFooter({
    super.key,
    required this.onTelegram,
    required this.onTiktok,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            "Contact Us",
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const FaIcon(
                  FontAwesomeIcons.telegram,
                  color: Colors.blueAccent,
                  size: 26,
                ),
                onPressed: onTelegram,
              ),
              const SizedBox(width: 20),
              IconButton(
                icon: const FaIcon(
                  FontAwesomeIcons.tiktok,
                  color: Colors.white,
                  size: 26,
                ),
                onPressed: onTiktok,
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            "© 2026 Tr4sFuck",
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
