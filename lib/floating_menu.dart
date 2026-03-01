import 'package:flutter/material.dart';

import 'admin_page.dart';
import 'bug_group.dart';
import 'change_password_page.dart';
import 'chat_page.dart';
import 'custom_bug.dart';
import 'ddos_page.dart';
import 'home_page.dart';
import 'seller_page.dart';
import 'sender_page.dart';
import 'loader_page.dart';

class FloatingMenu extends StatelessWidget {
  final String username;
  final String password;
  final String role;
  final String expiredDate;
  final String sessionKey;
  final List<Map<String, dynamic>> listBug;
  final List<Map<String, dynamic>> listPayload;
  final List<Map<String, dynamic>> listDDoS;
  final List<dynamic> news;
  final String keyToken;

  const FloatingMenu({
    super.key,
    required this.username,
    required this.password,
    required this.role,
    required this.expiredDate,
    required this.sessionKey,
    required this.listBug,
    required this.listPayload,
    required this.listDDoS,
    required this.news,
    required this.keyToken,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      child: ClipOval(
        child: Image.asset(
          'assets/images/kyyxXxror.jpg',
          width: 56,
          height: 56,
          fit: BoxFit.cover,
        ),
      ),
      onPressed: () {
        showModalBottomSheet(
          context: context,
          builder: (context) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [

                /// HOME
                ListTile(
                  title: const Text("Home"),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DashboardPage(
                          username: username,
                          password: password,
                          role: role,
                          expiredDate: expiredDate,
                          listBug: listBug,
                          listPayload: listPayload,
                          listDDoS: listDDoS,
                          sessionKey: sessionKey,
                          news: news,
                        ),
                      ),
                    );
                  },
                ),

                /// BUG GROUP
                ListTile(
                  title: const Text("Bug Group"),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => GroupBugPage(
                          username: username,
                          password: password,
                          sessionKey: sessionKey,
                          role: role,
                          expiredDate: expiredDate,
                        ),
                      ),
                    );
                  },
                ),

                /// BASIC BUG
                ListTile(
                  title: const Text("Basic Bug"),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AttackPage(
                          username: username,
                          password: password,
                          sessionKey: sessionKey,
                          listBug: listBug,
                          role: role,
                          expiredDate: expiredDate,
                        ),
                      ),
                    );
                  },
                ),

                /// CUSTOM BUG
                ListTile(
                  title: const Text("Custom Bug"),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CustomAttackPage(
                          username: username,
                          password: password,
                          sessionKey: sessionKey,
                          listPayload: listPayload,
                          role: role,
                          expiredDate: expiredDate,
                        ),
                      ),
                    );
                  },
                ),

                /// DDOS
                ListTile(
                  title: const Text("DDoS"),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ToolsPage(
                          sessionKey: sessionKey,
                          userRole: role,
                        ),
                      ),
                    );
                  },
                ),

                /// CHAT
                ListTile(
                  title: const Text("Chat"),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatPage(
                          sessionKey: sessionKey,
                        ),
                      ),
                    );
                  },
                ),

                /// SENDER
                ListTile(
                  title: const Text("Sender"),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SenderPage(
                          sessionKey: sessionKey,
                        ),
                      ),
                    );
                  },
                ),

                /// CHANGE PASSWORD
                ListTile(
                  title: const Text("Change Password"),
                  onTap: () {
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

                /// ADMIN (only if admin)
                if (role == "admin")
                  ListTile(
                    title: const Text("Admin Panel"),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AdminPage(
                            sessionKey: sessionKey,
                          ),
                        ),
                      );
                    },
                  ),

                /// SELLER
                ListTile(
                  title: const Text("Seller"),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SellerPage(
                          keyToken: keyToken,
                        ),
                      ),
                    );
                  },
                ),

              ],
            );
          },
        );
      },
    );
  }
}