import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class HomePage extends StatefulWidget {
  final String username;
  final String password;
  final String sessionKey;
  final List<Map<String, dynamic>> listBug;
  final String role;
  final String expiredDate;

  const HomePage({
    super.key,
    required this.username,
    required this.password,
    required this.sessionKey,
    required this.listBug,
    required this.role,
    required this.expiredDate,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  final targetController = TextEditingController();
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late AnimationController _pulseController;
  int bCoin = 0;
  int lCoin = 0;
  String selectedBugId = "";

  bool _isSending = false;
  String? _responseMessage;

  // Video Player Variables
  late VideoPlayerController _videoController;
  late ChewieController _chewieController;
  bool _isVideoInitialized = false;
  
  // warna
  final Color darkRed = const Color(0xFF5A0000);
  final Color accentRed = const Color(0xFFB11226);
  final Color glassBlack = const Color(0xFF0F0F0F).withOpacity(0.75);

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseController = AnimationController(
  vsync: this,
  duration: const Duration(milliseconds: 1500),
)..repeat(reverse: true);

// ✅ TAMBAH INI
_slideAnimation = Tween<Offset>(
  begin: const Offset(0, 0.08), // turun dikit
  end: const Offset(0, 0),      // balik normal
).animate(
  CurvedAnimation(
    parent: _pulseController,
    curve: Curves.easeInOut,
  ),
);

    if (widget.listBug.isNotEmpty) {
      selectedBugId = widget.listBug[0]['bug_id'];
    }

    // Initialize video player from assets
    _initializeVideoPlayer();
  }

  void _initializeVideoPlayer() {
    _videoController = VideoPlayerController.asset(
      'assets/videos/banner.mp4',
    );

    _videoController.initialize().then((_) {
      setState(() {
        _videoController.setVolume(0.1); // Mute dari VideoPlayerController
        _chewieController = ChewieController(
          videoPlayerController: _videoController,
          autoPlay: true,
          looping: true,
          showControls: false,
          autoInitialize: true,
        );
        _isVideoInitialized = true;
      });
    }).catchError((error) {
      print("Video initialization error: $error");
      setState(() {
        _isVideoInitialized = false;
      });
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    targetController.dispose();
    _videoController.dispose();
    _chewieController.dispose();
    super.dispose();
  }

  String? formatPhoneNumber(String input) {
    final cleaned = input.replaceAll(RegExp(r'[^\d+]'), '');
    if (!cleaned.startsWith('+') || cleaned.length < 8) return null;
    return cleaned;
  }

  Future<void> _sendBug() async {
    final rawInput = targetController.text.trim();
    final target = formatPhoneNumber(rawInput);
    final key = widget.sessionKey;

    if (target == null || key.isEmpty) {
      _showAlert("❌ Invalid Number",
          "Gunakan nomor internasional (misal: +62, 1, 44), bukan 08xxx.");
      return;
    }

    setState(() {
      _isSending = true;
      _responseMessage = null;
    });

    try {
      final res = await http.get(Uri.parse(
          "http://shirokoandrefzxprivt.pterodactly.biz.id:2460/sendBug?key=$key&target=$target&bug=$selectedBugId"));
      final data = jsonDecode(res.body);

      if (data["cooldown"] == true) {
        setState(() => _responseMessage = "⏳ Cooldown: Tunggu beberapa saat.");
      } else if (data["valid"] == false) {
        setState(() => _responseMessage = "❌ Key Invalid: Silakan login ulang.");
      } else if (data["noSender"] == true) {
        setState(() =>
            _showAlert("❌ No Connection",
            "Tolong sambungkan WhatsApp ke aplikasi melalui tombol \"MANAGE BUG SENDER\" di dashboard sebelum mengirim bug.")
        );
      } else if (data["insufficientCoin"] == true) {
        setState(() => _responseMessage = data["message"]);
      } else if (data["sended"] == false) {
        setState(() => _responseMessage =
        "⚠️ Gagal: Server sedang maintenance.");
      } else {
        setState(() => _responseMessage = "✅ Berhasil mengirim bug ke $target!");
        targetController.clear();
      }
    } catch (_) {
      setState(() =>
      _responseMessage = "❌ Error: Terjadi kesalahan. Coba lagi.");
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  void _showConfirmationDialog() {
    final rawInput = targetController.text.trim();
    final target = formatPhoneNumber(rawInput);

    if (target == null) {
      _showAlert("❌ Invalid Number",
          "Gunakan nomor internasional (misal: +62, 1, 44), bukan 08xxx.");
      return;
    }

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF0A0A0A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.redAccent, width: 2),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.red.withOpacity(0.1),
                Colors.black.withOpacity(0.9),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Warning Icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.redAccent, width: 2),
                  gradient: LinearGradient(
                    colors: [
                      Colors.red.withOpacity(0.3),
                      Colors.redAccent.withOpacity(0.1),
                    ],
                  ),
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.redAccent,
                  size: 40,
                ),
              ),

              const SizedBox(height: 20),

              // Title
              const Text(
                "CONFIRM ACTION",
                style: TextStyle(
                  color: Colors.redAccent,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Orbitron',
                  letterSpacing: 1.5,
                ),
              ),

              const SizedBox(height: 16),

              // Message
              Text(
                "This will consume 5 BCoin\nAre you sure?",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  fontFamily: 'ShareTechMono',
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 8),

              // Target Info
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.phone_android, color: Colors.redAccent, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      "Target: $target",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontFamily: 'ShareTechMono',
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Buttons
              Row(
                children: [
                  // No Button
                  Expanded(
                    child: AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey.withOpacity(0.8),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.3),
                                blurRadius: _pulseController.value * 10,
                                spreadRadius: _pulseController.value * 2,
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              "NO",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                fontFamily: 'Orbitron',
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Yes Button
                  Expanded(
                    child: AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: LinearGradient(
                              colors: [
                                Colors.redAccent,
                                Colors.red,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.redAccent.withOpacity(0.5),
                                blurRadius: _pulseController.value * 15,
                                spreadRadius: _pulseController.value * 3,
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _sendBug();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              "YES",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                fontFamily: 'Orbitron',
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAlert(String title, String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF0A0A0A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title,
            style: const TextStyle(color: Colors.red, fontFamily: 'Orbitron')),
        content: Text(msg,
            style: const TextStyle(
                color: Colors.white70, fontFamily: 'ShareTechMono')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderPanel() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        FadeTransition(
          opacity: Tween(begin: 0.5, end: 1.0).animate(_fadeController),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  Colors.redAccent,
                  Colors.red,
                  Colors.red.shade900,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.redAccent.withOpacity(0.3),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const CircleAvatar(
              radius: 55,
              backgroundImage: AssetImage('assets/images/logo.jpg'),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(widget.username,
            style: const TextStyle(
                color: Colors.red,
                fontFamily: 'Orbitron',
                fontWeight: FontWeight.w900,
                fontSize: 24,
                letterSpacing: 1.2)),
        const SizedBox(height: 6),
        Text(
          "Role: ${widget.role.toUpperCase()} • Exp: ${widget.expiredDate}",
          style: const TextStyle(
              color: Colors.white70,
              fontFamily: 'ShareTechMono',
              fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildVideoPlayer() {
    if (!_isVideoInitialized) {
      return Container(
        width: double.infinity,
        height: 10,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
            ],
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.redAccent.withOpacity(0.3),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AspectRatio(
          aspectRatio: _videoController.value.aspectRatio,
          child: Chewie(controller: _chewieController),
        ),
      ),
    );
  }

  Widget _buildInputPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          "Nomor Target",
          style: TextStyle(
              color: Colors.red, fontWeight: FontWeight.w700, fontSize: 16),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: targetController,
          style: const TextStyle(color: Colors.white),
          cursorColor: Colors.red,
          decoration: InputDecoration(
            hintText: "Contoh: +62xxxxxxxxxx",
            hintStyle: const TextStyle(color: Colors.redAccent),
            filled: true,
            fillColor: const Color(0xFF0D0D0D),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.red),
            ),
            prefixIcon:
            const Icon(Icons.phone_android, color: Colors.redAccent),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          "Pilih Bug",
          style: TextStyle(
              color: Colors.red, fontWeight: FontWeight.w700, fontSize: 16),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF0D0D0D),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.redAccent, width: 1.2),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              dropdownColor: Colors.black,
              value: selectedBugId,
              isExpanded: true,
              iconEnabledColor: Colors.red,
              style: const TextStyle(color: Colors.white),
              items: widget.listBug.map((bug) {
                return DropdownMenuItem<String>(
                  value: bug['bug_id'],
                  child: Text(
                    bug['bug_name'],
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedBugId = value ?? "";
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSendButton() {
  return SlideTransition(
  position: _slideAnimation,
    child: AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.only(top: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [
                darkRed.withOpacity(0.8),
                accentRed.withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: darkRed.withOpacity(0.4 * _pulseController.value),
                blurRadius: 25 * _pulseController.value,
                spreadRadius: 3 * _pulseController.value,
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: _isSending
                ? null
                : () async {
                    String selectedCoin = "bitcoin"; // bitcoin | lcoin

                    final ok = await showDialog<bool>(
                      context: context,
                      barrierDismissible: true,
                      builder: (dialogContext) {
                        return StatefulBuilder(
                          builder: (context, setDialogState) {
                            return AlertDialog(
                              backgroundColor: const Color(0xFF0F0F0F),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: const BorderSide(
                                  color: Color(0xFFFFC107),
                                ),
                              ),
                              contentPadding:
                                  const EdgeInsets.fromLTRB(20, 20, 20, 10),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    selectedCoin == "bitcoin"
                                        ? Icons.currency_bitcoin
                                        : Icons.monetization_on,
                                    size: 56,
                                    color: Colors.amber,
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    "Pilih Coin",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  // ===== PILIH COIN =====
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ChoiceChip(
                                          label: const Text("BTC"),
                                          selected:
                                              selectedCoin == "bitcoin",
                                          selectedColor: Colors.amber,
                                          onSelected: (_) {
                                            setDialogState(() {
                                              selectedCoin = "bitcoin";
                                            });
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: ChoiceChip(
                                          label: const Text("LTC"),
                                          selected:
                                              selectedCoin == "lcoin",
                                          selectedColor: Colors.amber,
                                          onSelected: (_) {
                                            setDialogState(() {
                                              selectedCoin = "lcoin";
                                            });
                                          },
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 14),
                                  Text(
                                    "Kirim bug membutuhkan\n5 ${selectedCoin == "bitcoin" ? "BTC" : "LTC"}",
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(dialogContext, false),
                                  child: const Text("BATAL"),
                                ),
                                ElevatedButton(
                                  onPressed: () =>
                                      Navigator.pop(dialogContext, true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.amber,
                                    foregroundColor: Colors.black,
                                  ),
                                  child: const Text("PAKAI COIN"),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    );

                    if (ok != true) return;

                    final res = await http.post(
                      Uri.parse(
                        "http://legal.naelptero.my.id:3242/use-coin",
                      ),
                      headers: {"Content-Type": "application/json"},
                      body: jsonEncode({
                        "username": widget.username,
                        "amount": 5,
                        "coinType": selectedCoin,
                      }),
                    );

                    final data = jsonDecode(res.body);

                    if (data["success"] != true) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              data["message"] ?? "❌ Coin tidak cukup"),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      return;
                    }

                    setState(() {
                      bCoin = data["bitcoin"] ?? bCoin;
                      lCoin = data["lcoin"] ?? lCoin;
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          "✅ 5 ${selectedCoin == "bitcoin" ? "BTC" : "LTC"} digunakan",
                        ),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );

                    await _sendBug();
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: _isSending
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.send, color: Colors.white, size: 22),
                      SizedBox(width: 12),
                      Text(
                        "KIRIM BUG",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
          ),
        );
      },
    ),
  );
}

  Widget _buildResponseMessage() {
    if (_responseMessage == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _responseMessage!.startsWith('✅')
              ? Colors.green.withOpacity(0.1)
              : Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _responseMessage!.startsWith('✅')
                ? Colors.greenAccent
                : Colors.redAccent,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              _responseMessage!.startsWith('✅')
                  ? Icons.check_circle
                  : Icons.error,
              color: _responseMessage!.startsWith('✅')
                  ? Colors.greenAccent
                  : Colors.redAccent,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _responseMessage!,
                style: TextStyle(
                  color: _responseMessage!.startsWith('✅')
                      ? Colors.greenAccent
                      : Colors.redAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildHeaderPanel(),
              _buildVideoPlayer(), // Video player dari assets
              _buildInputPanel(),
              const SizedBox(height: 40),
              _buildSendButton(),
              _buildResponseMessage(),
            ],
          ),
        ),
      ),
    );
  }
}