import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class AdminPage extends StatefulWidget {
  final String sessionKey;

  const AdminPage({super.key, required this.sessionKey});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // --- State for Manage Users Tab ---
  List<dynamic> fullUserList = [];
  List<dynamic> filteredList = [];
  final List<String> roleOptions = ['vip', 'reseller', 'reseller1', 'owner', 'member'];
  String selectedRole = 'member';
  int currentPage = 1;
  int itemsPerPage = 15;

  // --- General State ---
  bool isLoading = false;
  final deleteController = TextEditingController();
  final createUsernameController = TextEditingController();
  final createPasswordController = TextEditingController();
  final createDayController = TextEditingController();
  String newUserRole = 'member';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchUsers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    deleteController.dispose();
    createUsernameController.dispose();
    createPasswordController.dispose();
    createDayController.dispose();
    super.dispose();
  }

  Future<void> _fetchUsers() async {
    setState(() => isLoading = true);
    try {
      final res = await http.get(
        Uri.parse('http://shirokoandrefzxprivt.pterodactly.biz.id:2460/listUsers?key=${widget.sessionKey}'),
      );
      final data = jsonDecode(res.body);
      if (data['valid'] == true && data['authorized'] == true) {
        fullUserList = data['users'] ?? [];
        _filterAndPaginate();
      } else {
        _showCustomDialog("⚠️ Error", data['message'] ?? 'Tidak diizinkan melihat daftar user.');
      }
    } catch (_) {
      _showCustomDialog("🌐 Error", "Gagal memuat user list.");
    }
    setState(() => isLoading = false);
  }

  void _filterAndPaginate() {
    setState(() {
      currentPage = 1;
      filteredList = fullUserList.where((u) => u['role'] == selectedRole).toList();
    });
  }

  List<dynamic> _getCurrentPageData() {
    if (filteredList.isEmpty) return [];
    final start = (currentPage - 1) * itemsPerPage;
    final end = (start + itemsPerPage);
    return filteredList.sublist(start, end > filteredList.length ? filteredList.length : end);
  }

  int get totalPages => (filteredList.length / itemsPerPage).ceil();

  Future<void> _deleteUser(String username) async {
    final confirm = await _showConfirmationDialog("Delete User", "Are you sure you want to delete '$username'?");
    if (!confirm) return;

    setState(() => isLoading = true);
    try {
      final res = await http.get(
        Uri.parse('http://shirokoandrefzxprivt.pterodactly.biz.id:2460/deleteUser?key=${widget.sessionKey}&username=$username'),
      );
      final data = jsonDecode(res.body);
      if (data['deleted'] == true) {
        _showCustomDialog("✅ Berhasil", "User '${data['user']['username']}' telah dihapus.");
        _fetchUsers();
      } else {
        _showCustomDialog("❌ Gagal", data['message'] ?? 'Gagal menghapus user.');
      }
    } catch (_) {
      _showCustomDialog("🌐 Error", "Tidak dapat menghubungi server.");
    }
    setState(() => isLoading = false);
  }

  Future<void> _createAccount() async {
    final username = createUsernameController.text.trim();
    final password = createPasswordController.text.trim();
    final day = createDayController.text.trim();

    if (username.isEmpty || password.isEmpty || day.isEmpty) {
      _showCustomDialog("⚠️ Error", "Semua field wajib diisi.");
      return;
    }

    setState(() => isLoading = true);
    try {
      final url = Uri.parse(
        'http://shirokoandrefzxprivt.pterodactly.biz.id:2460/userAdd?key=${widget.sessionKey}&username=$username&password=$password&day=$day&role=$newUserRole',
      );
      final res = await http.get(url);
      final data = jsonDecode(res.body);

      if (data['created'] == true) {
        _showCustomDialog("✅ Sukses", "Akun '${data['user']['username']}' berhasil dibuat.");
        createUsernameController.clear();
        createPasswordController.clear();
        createDayController.clear();
        newUserRole = 'member';
        _fetchUsers();
      } else {
        _showCustomDialog("❌ Gagal", data['message'] ?? 'Gagal membuat akun.');
      }
    } catch (_) {
      _showCustomDialog("🌐 Error", "Gagal menghubungi server.");
    }
    setState(() => isLoading = false);
  }

  // --- UI WIDGETS ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background pattern or image
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black,
                  Colors.black,
                ],
              ),
            ),
          ),
          // Main content
          Column(
            children: [
              _buildHeader(),
              _buildTabBar(),
              Expanded(child: _buildTabBarView()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      child: Row(
        children: [
          FaIcon(FontAwesomeIcons.userShield, color: Colors.redAccent, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "ADMIN PANEL",
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: 26,
                    fontFamily: 'Orbitron',
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                Text(
                  "Security By @permen_md",
                  style: TextStyle(color: Colors.white70, fontFamily: 'ShareTechMono'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.red,
        unselectedLabelColor: Colors.white70,
        labelStyle: const TextStyle(fontFamily: 'Orbitron', fontWeight: FontWeight.bold),
        tabs: const [
          Tab(text: 'USER MANAGEMENT'),
          Tab(text: 'CREATE ACCOUNT'),
        ],
      ),
    );
  }

  Widget _buildTabBarView() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildManageUsersTab(),
        _buildCreateAccountTab(),
      ],
    );
  }

  // --- TAB 1: MANAGE USERS ---
  Widget _buildManageUsersTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Expanded(child: _buildUserListAndActions()),
        ],
      ),
    );
  }

  Widget _buildUserListAndActions() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // User List
        Expanded(flex: 3, child: _buildUserListView()),
      ],
    );
  }

  Widget _buildUserListView() {
    return _buildGlassCard(
      child: Column(
        children: [
          // Filter
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Text("Filter by Role:", style: _styleLabel()),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedRole,
                    dropdownColor: Colors.black87,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration("Role"),
                    items: roleOptions.map((role) {
                      return DropdownMenuItem(value: role, child: Text(role.toUpperCase()));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        selectedRole = val;
                        _filterAndPaginate();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white24),
          // List
          Expanded(
            child: fullUserList.isEmpty
                ? const Center(child: Text("No users found.", style: TextStyle(color: Colors.white54)))
                : ListView.builder(
                itemCount: _getCurrentPageData().length,
                itemBuilder: (context, index) {
                  return _buildUserGlassCard(_getCurrentPageData()[index]);
                }),
          ),
          // Pagination
          if (totalPages > 1) _buildPagination(),
        ],
      ),
    );
  }

  Widget _buildUserGlassCard(Map user) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 300),
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: Colors.white.withOpacity(0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          leading: CircleAvatar(
            backgroundColor: Colors.redAccent.withOpacity(0.2),
            child: FaIcon(FontAwesomeIcons.user, color: Colors.redAccent),
          ),
          title: Text(user['username'], style: _styleCardTitle()),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Role: ${user['role']} | Exp: ${user['expiredDate']}", style: _styleCardSubtitle()),
              Text("Parent: ${user['parent'] ?? 'SYSTEM'}", style: _styleCardSubtitle()),
            ],
          ),
          trailing: IconButton(
            icon: const FaIcon(FontAwesomeIcons.trash, color: Colors.redAccent, size: 20),
            onPressed: () => _deleteUser(user['username']),
          ),
        ),
      ),
    );
  }

  Widget _buildPagination() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: Colors.redAccent),
            onPressed: currentPage > 1 ? () => setState(() => currentPage--) : null,
          ),
          ...List.generate(totalPages, (index) {
            final page = index + 1;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: InkWell(
                onTap: () => setState(() => currentPage = page),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: currentPage == page ? Colors.redAccent : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
                  ),
                  child: Text(
                    "$page",
                    style: TextStyle(
                      color: currentPage == page ? Colors.black : Colors.redAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            );
          }),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: Colors.redAccent),
            onPressed: currentPage < totalPages ? () => setState(() => currentPage++) : null,
          ),
        ],
      ),
    );
  }

  // --- TAB 2: CREATE ACCOUNT ---
  Widget _buildCreateAccountTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: _buildGlassCard(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  FaIcon(FontAwesomeIcons.userPlus, color: Colors.redAccent, size: 24),
                  const SizedBox(width: 12),
                  Text("CREATE NEW ACCOUNT", style: _styleCardTitle()),
                ],
              ),
            ),
            const Divider(color: Colors.white24),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(
                      controller: createUsernameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration("Username"),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: createPasswordController,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration("Password"),
                      obscureText: true,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: createDayController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration("Durasi (hari)"),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: newUserRole,
                      dropdownColor: Colors.black87,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration("Role"),
                      items: roleOptions.map((role) {
                        return DropdownMenuItem(
                          value: role,
                          child: Text(role.toUpperCase()),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => newUserRole = val ?? 'member'),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: isLoading ? null : _createAccount,
                      icon: const FaIcon(FontAwesomeIcons.userPlus, size: 18),
                      label: const Text("CREATE ACCOUNT", style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- HELPER WIDGETS & STYLES ---
  Widget _buildGlassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white.withOpacity(0.1)),
            borderRadius: BorderRadius.circular(20),
          ),
          child: child,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      filled: true,
      fillColor: Colors.white.withOpacity(0.05),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.2))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent)),
    );
  }

  TextStyle _styleCardTitle() {
    return const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Orbitron');
  }

  TextStyle _styleCardSubtitle() {
    return const TextStyle(color: Colors.white70, fontSize: 12);
  }

  TextStyle _styleLabel() {
    return const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold);
  }

  Future<bool> _showConfirmationDialog(String title, String content) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black87,
        title: Text(title, style: const TextStyle(color: Colors.redAccent)),
        content: Text(content, style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Batal", style: TextStyle(color: Colors.white54))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Hapus", style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
    return result ?? false;
  }

  void _showCustomDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.black87,
        title: Text(title, style: const TextStyle(color: Colors.redAccent)),
        content: Text(message, style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK", style: TextStyle(color: Colors.redAccent)),
          )
        ],
      ),
    );
  }
}