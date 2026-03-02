import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart'; // Impor url_launcher

import 'anime_home.dart';
import 'change_password.dart';
import 'bug_sender.dart';
import 'nik_check.dart';
import 'history_coin.dart';
import 'admin_page.dart';
import 'home_page.dart';
import 'seller_page.dart';
import 'tools_gateway.dart';
import 'login_page.dart';
import 'chatbot_page.dart';
import 'dashboard_ai.dart';
import 'bug_sender.dart';

class DashboardPage extends StatefulWidget {
  final String username;
  final String password;
  final String role;
  final String expiredDate;
  final String sessionKey;
  final List<Map<String, dynamic>> listBug;
  final List<Map<String, dynamic>> listDoos;
  final List<dynamic> news;

  const DashboardPage({
    super.key,
    required this.username,
    required this.password,
    required this.role,
    required this.expiredDate,
    required this.listBug,
    required this.listDoos,
    required this.sessionKey,
    required this.news,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;
  late WebSocketChannel channel;
  int bCoin = 0;
  int lCoin = 0;
  
  Future<void> loadCoin() async {
  final res = await http.post(
    Uri.parse("http://shirokoandrefzxprivt.pterodactly.biz.id:2460/profile"),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({"username": username}),
  );

  final data = jsonDecode(res.body);

  setState(() {
    bCoin = data["bitcoin"] ?? 0;
    lCoin = data["lcoin"] ?? 0;
  });
}

  // Controller untuk video background
  late VideoPlayerController _videoController;
  bool _isVideoInitialized = false;

  late String sessionKey;
  late String username;
  late String password;
  late String role;
  late String expiredDate;
  late List<Map<String, dynamic>> listBug;
  late List<Map<String, dynamic>> listDoos;
  late List<dynamic> newsList;
  String androidId = "unknown";

  int _bottomNavIndex = 0;
  Widget _selectedPage = const Placeholder();

  // New black-red color scheme

  @override
  void initState() {
    super.initState();
    sessionKey = widget.sessionKey;
    username = widget.username;
    password = widget.password;
    role = widget.role;
    expiredDate = widget.expiredDate;
    listBug = widget.listBug;
    listDoos = widget.listDoos;
    newsList = widget.news;

    loadCoin();

    // Inisialisasi video background
    _initializeVideo();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();

    _selectedPage = _buildEnhancedNewsPage();
    _initAndroidIdAndConnect();
  }

  // Fungsi untuk menginisialisasi video
  void _initializeVideo() async {
    // Ganti 'assets/videos/bg.mp4' dengan path video Anda
    _videoController = VideoPlayerController.asset('assets/videos/bg.mp4')
      ..initialize().then((_) {
        // Atur volume ke 0 untuk video background
        _videoController.setVolume(0.0);
        // Atur video agar berulang
        _videoController.setLooping(true);
        // Mulai pemutaran video
        _videoController.play();
        // Update state untuk memberitahu bahwa video telah diinisialisasi
        setState(() {
          _isVideoInitialized = true;
        });
      });
  }

  Future<void> _initAndroidIdAndConnect() async {
    final deviceInfo = await DeviceInfoPlugin().androidInfo;
    androidId = deviceInfo.id;
    _connectToWebSocket();
  }

  void _connectToWebSocket() {
    channel = WebSocketChannel.connect(Uri.parse('wss://ws-privatebyputra.putravvip.dev:3085'));
    channel.sink.add(jsonEncode({
      "type": "validate",
      "key": sessionKey,
      "androidId": androidId,
    }));
    channel.sink.add(jsonEncode({"type": "stats"}));

    channel.stream.listen((event) {
      final data = jsonDecode(event);
      if (data['type'] == 'myInfo') {
        if (data['valid'] == false) {
          _handleInvalidSession("Session invalid, please re-login.");
        }
      }
    });
  }

  void _handleInvalidSession(String message) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          backgroundColor: glassBlack,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: bloodRed.withOpacity(0.5), width: 1),
          ),
          title: Row(
            children: [
              Icon(Icons.warning_rounded, color: bloodRed, size: 28),
              const SizedBox(width: 10),
              Text("Session Expired",
                  style: TextStyle(color: bloodRed, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(message, style: const TextStyle(color: Colors.white70)),
          actions: [
            Container(
              decoration: BoxDecoration(
                color: bloodRed,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                        (route) => false,
                  );
                },
                child: Text("OK", style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onBottomNavTapped(int index) {
    setState(() {
      _bottomNavIndex = index;
      if (index == 0) _selectedPage = _buildEnhancedNewsPage();
      else if (index == 1) {
        _selectedPage = HomePage(
          username: username,
          password: password,
          listBug: listBug,
          role: role,
          expiredDate: expiredDate,
          sessionKey: sessionKey,
        );
      } else if (index == 2) {
        _selectedPage = ToolsPage(sessionKey: sessionKey, userRole: role, listDoos: listDoos);
      } else if (index == 3) {
        _selectedPage = GoToChatBot();
      }
    });
  }

  // Fungsi untuk navigasi ke Admin Page
  void _navigateToAdminPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminPage(sessionKey: sessionKey),
      ),
    );
  }

  // Fungsi untuk navigasi ke Seller Page
  void _navigateToSellerPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SellerPage(keyToken: sessionKey),
      ),
    );
  }

  int onlineUsers = 0;
  int activeConnections = 0;

final Color bloodRed = const Color(0xFF8B0000);
final Color darkRed = const Color(0xFF5A0000);
final Color lightRed = const Color(0xFFB11226);
final Color deepBlack = const Color(0xFF050505);
final Color glassBlack = const Color(0xFF0F0F0F).withOpacity(0.75);
final Color primaryDark = const Color(0xFF0A0A0A);
final Color primaryPurple = const Color(0xFF7A0C0C);
final Color accentPurple = const Color(0xFF9A1B1B);
final Color lightPurple = const Color(0xFFB03030);
final Color primaryWhite = const Color(0xFFEDEDED);
final Color accentGrey = const Color(0xFF9E9E9E);
final Color cardDark = const Color(0xFF141414);
final Color purpleGradientStart = const Color(0xFF5A0000);
final Color purpleGradientEnd = const Color(0xFF8B0000);

  Widget _buildCompactInfoItem({
    required IconData icon,
    required String label,
    required String value,
    Color valueColor = Colors.white,
  }) {
    // PERUBAHAN: Bungkus seluruh item dalam Container untuk border penuh
    return Container(
      margin: const EdgeInsets.only(bottom: 12), // Beri jarak antar item
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: primaryPurple.withOpacity(0.3)), // Border penuh
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: primaryPurple.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: lightPurple, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: accentGrey,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: valueColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'ShareTechMono',
                    shadows: valueColor == primaryWhite ? [
                      Shadow(
                        color: primaryPurple.withOpacity(0.5),
                        blurRadius: 5,
                      ),
                    ] : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStat({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white70, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                    ),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case "owner":
        return Colors.red;
      case "vip":
        return primaryPurple;
      case "reseller":
        return Colors.green;
      case "premium":
        return Colors.orange;
      default:
        return lightPurple;
    }
  }

  // Widget untuk membangun video background
  Widget _buildVideoBackground() {
    if (_isVideoInitialized) {
      return SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: _videoController.value.size.width,
            height: _videoController.value.size.height,
            child: VideoPlayer(_videoController),
          ),
        ),
      );
    } else {
      // Tampilkan layar hitam jika video belum dimuat
      return Container(color: deepBlack);
    }
  }

Widget _buildEnhancedNewsPage() {
  return SingleChildScrollView(
    child: Stack(
      children: [
        // ===== BANNER =====
        SizedBox(
          width: double.infinity,
          height: 240, // 🔥 tinggi banner
          child: PageView.builder(
            controller: PageController(viewportFraction: 1),
            itemCount: newsList.length,
            itemBuilder: (context, index) {
              final item = newsList[index];
              return Stack(
                fit: StackFit.expand,
                children: [
                  if (item['image'] != null &&
                      item['image'].toString().isNotEmpty)
                    NewsMedia(url: item['image']),

                  // dark overlay (biar aesthetic)
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withOpacity(0.9),
                          Colors.transparent,
                        ],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),

        // ===== CONTENT =====
        Column(
          children: [
            const SizedBox(height: 260), // ⬅️ posisi wallet naik ke banner

            // ===== WALLET TITLE =====
            Padding(
  padding: const EdgeInsets.symmetric(horizontal: 20),
  child: Row(
    children: const [
      Icon(
        Icons.account_balance_wallet_rounded,
        color: Color(0xFFFFC107), // 🟡 kuning
        size: 22,
      ),
      SizedBox(width: 10),
      Text(
        "My Wallet",
        style: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  ),
),

            const SizedBox(height: 10),

            // ===== WALLET CARD (TIDAK DIUBAH) =====
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F0F0F),
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.08),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    _AccountTiles(
                      icon: Icons.person,
                      iconColor: const Color(0xFF9E9E9E),
                      title: "Username",
                      amount: '$username',
                      badgeColor: const Color(0xFF9E9E9E),
                    ),
                    const SizedBox(height: 14),
_coinTile(
  icon: Icons.currency_bitcoin,
  iconColor: const Color(0xFFFFC107),
  title: "B Coin",
  amount: bCoin.toString(),
  badgeColor: const Color(0xFFFFC107),
),
                    const SizedBox(height: 14),
_coinTile(
  icon: Icons.monetization_on,
  iconColor: const Color(0xFF4DA3FF),
  title: "L Coin",
  amount: lCoin.toString(),
  badgeColor: const Color(0xFF4DA3FF),
),
                    const SizedBox(height: 22),
Row(
  children: [
    Expanded(
      child: _actionButton(
        icon: Icons.add_circle_outline,
        label: "Top Up",
        color: const Color(0xFFFFC107),
        onTap: () {
          final redeemCtrl = TextEditingController();

          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              backgroundColor: const Color(0xFF0F0F0F),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              title: const Text(
                "Top Up",
                style: TextStyle(color: Colors.white),
              ),
              content: TextField(
                controller: redeemCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: "Masukkan kode redeem",
                  hintStyle: TextStyle(color: Colors.white54),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Batal"),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.pop(context);

                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (_) =>
                          const Center(child: CircularProgressIndicator()),
                    );

                    final res = await http.post(
                      Uri.parse(
                        "http://shirokoandrefzxprivt.pterodactly.biz.id:2460/topup",
                      ),
                      headers: {"Content-Type": "application/json"},
                      body: jsonEncode({
                        "username": widget.username,
                        "redeem_code": redeemCtrl.text,
                      }),
                    );

                    Navigator.pop(context);

                    final data = jsonDecode(res.body);

                    if (data["success"] == true) {
                      await loadCoin();
                    }

                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        backgroundColor: const Color(0xFF0F0F0F),
                        title: Text(
                          data["success"] ? "Berhasil" : "Gagal",
                          style: const TextStyle(color: Colors.white),
                        ),
                        content: Text(
                          data["message"],
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
                    );
                  },
                  child: const Text("Kirim"),
                ),
              ],
            ),
          );
        },
      ),
    ),
    const SizedBox(width: 14),

    Expanded(
      child: _actionButton(
        icon: Icons.send,
        label: "Transfer",
        color: const Color(0xFF4DA3FF),
        onTap: () {
          final userCtrl = TextEditingController();
          final amountCtrl = TextEditingController();

          String selectedCoin = "bitcoin"; // default

          showDialog(
            context: context,
            builder: (context) {
              return StatefulBuilder(
                builder: (context, setState) {
                  return AlertDialog(
                    backgroundColor: const Color(0xFF0F0F0F),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    title: const Text(
                      "Transfer",
                      style: TextStyle(color: Colors.white),
                    ),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: userCtrl,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: "Username tujuan",
                            hintStyle: TextStyle(color: Colors.white54),
                          ),
                        ),
                        const SizedBox(height: 12),

                        DropdownButtonFormField<String>(
                          value: selectedCoin,
                          dropdownColor: const Color(0xFF151515),
                          decoration: const InputDecoration(
                            hintText: "Pilih Coin",
                            hintStyle: TextStyle(color: Colors.white54),
                          ),
                          style: const TextStyle(color: Colors.white),
                          items: const [
                            DropdownMenuItem(
                              value: "bitcoin",
                              child: Text("Bitcoin"),
                            ),
                            DropdownMenuItem(
                              value: "lcoin",
                              child: Text("LCoin"),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              selectedCoin = value!;
                            });
                          },
                        ),

                        const SizedBox(height: 12),
                        TextField(
                          controller: amountCtrl,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: "Jumlah",
                            hintStyle: TextStyle(color: Colors.white54),
                          ),
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Batal"),
                      ),
                      TextButton(
                        onPressed: () async {
                          Navigator.pop(context);

                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (_) =>
                                const Center(child: CircularProgressIndicator()),
                          );

                          final res = await http.post(
                            Uri.parse(
                              "http://shirokoandrefzxprivt.pterodactly.biz.id:2460/transfer",
                            ),
                            headers: {"Content-Type": "application/json"},
                            body: jsonEncode({
                              "from": widget.username,
                              "to": userCtrl.text,
                              "amount": amountCtrl.text,
                              "coinType": selectedCoin,
                            }),
                          );

                          Navigator.pop(context);

                          final data = jsonDecode(res.body);

                          if (data["success"] == true) {
                            await loadCoin();
                          }

                          showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              backgroundColor: const Color(0xFF0F0F0F),
                              title: Text(
                                data["success"] ? "Transfer Berhasil" : "Transfer Gagal",
                                style: const TextStyle(color: Colors.white),
                              ),
                              content: Text(
                                data["message"],
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ),
                          );
                        },
                        child: const Text("Kirim"),
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    ),
    const SizedBox(width: 14),

    // ✅ BUTTON HISTORY DI KANAN TRANSFER
    Expanded(
      child: _actionButton(
        icon: Icons.restore,
        label: "History",
        color: const Color(0xFF00C853),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CoinHistoryPage(
                username: widget.username,
              ),
            ),
          );
        },
      ),
    ),
], // ✅ tutup children Row
),   // ✅ tutup Row
const SizedBox(height: 25),

ManageBugSenderButton(
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BugSenderPage(
          username: username,
          role: role,
          sessionKey: sessionKey,
        ),
      ),
    );
  },
),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ), // ⬅️ tutup Column
      ],   // ⬅️ tutup Stack children
    ),     // ⬅️ tutup Stack
  );       // ⬅️ tutup SingleChildScrollView
}

// fungsi coin

Widget _actionButton({
  required IconData icon,
  required String label,
  required Color color,
  required VoidCallback onTap,
}) {
  return InkWell(
    borderRadius: BorderRadius.circular(20),
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: color.withOpacity(0.18),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 10,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: color.withOpacity(0.4),
          width: 0.8,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _AccountTiles({
  required IconData icon,
  required Color iconColor,
  required String title,
  required String amount,
  required Color badgeColor,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: BoxDecoration(
      color: const Color(0xFF151515),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: badgeColor.withOpacity(0.4),
        width: 0.8,
      ),
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: badgeColor.withOpacity(0.18),
          ),
          child: Icon(icon, color: badgeColor, size: 22),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: badgeColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              amount,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: badgeColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
  mainAxisSize: MainAxisSize.min,
  children: [
    Icon(
      Icons.shield_outlined,
      size: 12,
      color: badgeColor,
    ),
    const SizedBox(width: 4),
    Text(
      "Status",
      style: TextStyle(
        color: badgeColor,
        fontSize: 11,
        fontWeight: FontWeight.w500,
      ),
    ),
  ],
),
        ),
      ],
    ),
  );
}

Widget _coinTile({
  required IconData icon,
  required Color iconColor,
  required String title,
  required String amount,
  required Color badgeColor,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: BoxDecoration(
      color: const Color(0xFF151515),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: badgeColor.withOpacity(0.4),
        width: 0.8,
      ),
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: badgeColor.withOpacity(0.18),
          ),
          child: Icon(icon, color: badgeColor, size: 22),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: badgeColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              amount,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: badgeColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            "Balance",
            style: TextStyle(
              color: badgeColor,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    ),
  );
}

  Widget _contactActionButton({
    required IconData icon,
    required String label,
    required String url,
    required Color color,
  }) {
    return GestureDetector(
      onTap: () async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        } else {
          await launchUrl(uri);
        }
      },
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withOpacity(0.5)),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.2),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _enhancedGlassCard({required Widget child}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: glassBlack,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: bloodRed.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: bloodRed.withOpacity(0.15),
            blurRadius: 25,
            spreadRadius: 2,
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _enhancedInfoRow(IconData icon, String label, String value,
      {Color valueColor = Colors.white}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: bloodRed.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: bloodRed.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: bloodRed, size: 20),
          ),
          const SizedBox(width: 12),
          Text("$label: ", style: const TextStyle(color: Colors.white70)),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: valueColor,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    drawer: _buildDrawer(),
    backgroundColor: deepBlack,
    extendBody: true,

    // APPBAR SELALU ADA
    appBar: AppBar(
      backgroundColor: const Color(0xFF1A0E0E),
      elevation: 0,
      title: const Text(
        "Welcome to Tr4sFuck",
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 24,
          color: Colors.white,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: Colors.white),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text("No new notifications"),
                backgroundColor: bloodRed,
              ),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.logout, color: Colors.white),
          onPressed: () async {
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                backgroundColor: cardDark,
                title: const Text(
                  "Logout",
                  style: TextStyle(color: Colors.white),
                ),
                content: const Text(
                  "Are you sure you want to logout?",
                  style: TextStyle(color: Colors.white70),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child:
                        Text("Cancel", style: TextStyle(color: bloodRed)),
                  ),
                  TextButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      final prefs =
                          await SharedPreferences.getInstance();
                      await prefs.clear();
                      if (!mounted) return;
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (_) => const LoginPage(),
                        ),
                        (route) => false,
                      );
                    },
                    child:
                        Text("Logout", style: TextStyle(color: bloodRed)),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    ),

    body: FadeTransition(
      opacity: _animation,
      child: _selectedPage,
    ),

    // BOTTOM NAV SELALU ADA
    bottomNavigationBar: _buildGlassBottomNavBar(),
  );
}


  // PERUBAHAN: Tambahkan widget Drawer
  Widget _buildDrawer() {
  return Drawer(
    backgroundColor: cardDark,
    child: ListView(
      padding: EdgeInsets.zero,
      children: [
        DrawerHeader(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [darkRed, bloodRed],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          bloodRed,
                          lightRed,
                          darkRed,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: bloodRed.withOpacity(0.5),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 28,
                      backgroundColor: cardDark,
                      child: CircleAvatar(
                        radius: 26,
                        backgroundImage:
                            AssetImage('assets/images/logo.jpg'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Tr4sFuck',
                      style: TextStyle(
                        color: primaryWhite,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Orbitron',
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 5,
                            offset: Offset(1, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'User: $username',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                ),
              ),
              Text(
                'Role: ${role.toUpperCase()}',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              Text(
                'Expired At: $expiredDate',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),

        if (role == "owner")
          ListTile(
            leading:
                Icon(Icons.admin_panel_settings, color: bloodRed),
            title: Text('Admin Page',
                style: TextStyle(color: primaryWhite)),
            onTap: () {
              Navigator.pop(context);
              _navigateToAdminPage();
            },
          ),

        if (role == "reseller")
          ListTile(
            leading:
                Icon(Icons.add_shopping_cart, color: bloodRed),
            title: Text('Seller Page',
                style: TextStyle(color: primaryWhite)),
            onTap: () {
              Navigator.pop(context);
              _navigateToSellerPage();
            },
          ),

        ListTile(
          leading: Icon(Icons.lock_clock, color: bloodRed),
          title: Text('Change Password',
              style: TextStyle(color: primaryWhite)),
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChangePasswordPage(
                  username: username,
                  sessionKey: sessionKey,
                ),
              ),
            );
          },
        ),

        ListTile(
          leading: Icon(Icons.person, color: bloodRed),
          title: Text('NIK Check',
              style: TextStyle(color: primaryWhite)),
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => NikCheckerPage(),
              ),
            );
          },
        ),

        // ===== THANKS TO =====
        const Divider(
          color: Colors.white24,
          thickness: 1,
          height: 24,
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Thanks To',
                style: TextStyle(
                  color: primaryWhite,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              Text(
                '- KaiiOfficial (Creators)',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              Text(
                '- PermenMD (Inspired)',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              Text(
                '- Zyrex (User Ghostfin)',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              Text(
                '- Zsnz (User Element)',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              Text(
                '- Aii Sigma (My Bini😘)',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              Text(
                '- Yayz (70%)',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _buildGlassBottomNavBar() {
  return Container(
    decoration: BoxDecoration(
      color: const Color(0xFF151515), // ✅ abu-abu gelap solid
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.35),
          blurRadius: 8,
          offset: const Offset(0, -3), // shadow ke atas
        ),
      ],
    ),
    child: BottomNavigationBar(
      backgroundColor: const Color(0xFF151515), // ✅ WAJIB sama
      selectedItemColor: bloodRed,
      unselectedItemColor: Colors.white54,
      currentIndex: _bottomNavIndex,
      onTap: _onBottomNavTapped,
      elevation: 0,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_rounded),
          label: "Home",
        ),
        BottomNavigationBarItem(
          icon: Icon(FontAwesomeIcons.whatsapp),
          label: "WhatsApp",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.build_circle_outlined),
          label: "Tools",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.smart_toy_outlined),
          label: "ChatBot",
        ),
      ],
    ),
  );
}

  void _showAccountMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: glassBlack,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border.all(color: bloodRed.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: bloodRed.withOpacity(0.15),
                blurRadius: 30,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 4,
                  decoration: BoxDecoration(
                    color: bloodRed.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [bloodRed, lightRed],
                  ).createShader(bounds),
                  child: const Text(
                    "Account Info",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 24),
                _enhancedInfoRow(Icons.person, "Username", username),
                _enhancedInfoRow(Icons.shield, "Role", role),
                _enhancedInfoRow(Icons.calendar_today, "Expired", expiredDate),
                const SizedBox(height: 32),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [bloodRed, darkRed],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.clear();
                      if (!mounted) return;
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const LoginPage()),
                            (route) => false,
                      );
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text("Logout"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Hentikan dan dispose video controller
    _videoController.dispose();
    channel.sink.close(status.goingAway);
    _controller.dispose();
    super.dispose();
  }
}

class NewsMedia extends StatefulWidget {
  final String url;
  const NewsMedia({super.key, required this.url});

  @override
  State<NewsMedia> createState() => _NewsMediaState();
}

class _NewsMediaState extends State<NewsMedia> {
  VideoPlayerController? _controller;

  @override
  void initState() {
    super.initState();
    if (_isVideo(widget.url)) {
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
        ..initialize().then((_) {
          setState(() {});
          _controller?.setLooping(true);
          _controller?.setVolume(0.0);
          _controller?.play();
        });
    }
  }

  bool _isVideo(String url) =>
      url.endsWith(".mp4") ||
          url.endsWith(".webm") ||
          url.endsWith(".mov") ||
          url.endsWith(".mkv");

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isVideo(widget.url)) {
      if (_controller != null && _controller!.value.isInitialized) {
        return AspectRatio(
          aspectRatio: _controller!.value.aspectRatio,
          child: VideoPlayer(_controller!),
        );
      } else {
        return Center(child: CircularProgressIndicator(color: Colors.red));
      }
    } else {
      return Image.network(widget.url, fit: BoxFit.cover);
    }
  }
}

// Custom painter for grid pattern
class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red.withOpacity(0.05)
      ..strokeWidth = 0.5;

    const gridSize = 30.0;

    // Draw vertical lines
    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Draw horizontal lines
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

// ==========================================
// TEMPel DI SINI (DI LUAR SEMUA CLASS)
// ==========================================

class ManageBugSenderButton extends StatelessWidget {
  final VoidCallback onTap;

  const ManageBugSenderButton({
    Key? key,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Center(
          child: Text(
            "MANAGE BUG SENDER",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
