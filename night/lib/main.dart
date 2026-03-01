import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'login_page.dart';
import 'dashboard_page.dart';
import 'home_page.dart';
import 'seller_page.dart';
import 'admin_page.dart';
import 'landing.dart';

const _rgsRaven =
    'aHR0cHM6Ly9yYXcuZ2l0aHVidXNlcmNvbnRlbnQuY29tL1h5enpNb29kcy9zZXR0aW5ncy9yZWZzL2hlYWRzL21haW4vc2VjLmpzb24=';

String _decodeUrl() {
  return utf8.decode(base64Decode(_rgsRaven));
}

Future<bool> _checkRemoteGate() async {
  try {
    final res = await http.get(
      Uri.parse(_decodeUrl()),
      headers: {'Cache-Control': 'no-cache'},
    );

    if (res.statusCode != 200) return false;
    final data = jsonDecode(res.body);
    return data['error'] != true;
  } catch (_) {
    return false;
  }
}

const _nativeGate = MethodChannel('remote_gate');

Future<bool> _checkNativeGate() async {
  try {
    return await _nativeGate.invokeMethod<bool>('check') ?? false;
  } catch (_) {
    return false;
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final dartAllowed = await _checkRemoteGate();
  final nativeAllowed = await _checkNativeGate();

  if (!(dartAllowed && nativeAllowed)) {
    runApp(const BlockedApp());
    return;
  }

  runApp(const MyApp());
}

class BlockedApp extends StatelessWidget {
  const BlockedApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.report_problem,
                  color: Colors.red, size: 64),
              SizedBox(height: 20),
              Text(
                'APPLICATION BASE\nTELAH DINONAKTIFKAN\nOLEH OWNER',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'RavenGetSuzo',
      theme: ThemeData(
        brightness: Brightness.dark,
        fontFamily: 'ShareTechMono',
        scaffoldBackgroundColor: Colors.black,
        colorScheme: ColorScheme.dark().copyWith(
          secondary: Colors.purple,
        ),
      ),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(builder: (_) => LandingPage());

          case '/login':
            return MaterialPageRoute(builder: (_) => const LoginPage());

          case '/dashboard':
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) => DashboardPage(
                username: args['username'],
                password: args['password'],
                role: args['role'],
                sessionKey: args['key'],
                expiredDate: args['expiredDate'],
                listBug:
                    List<Map<String, dynamic>>.from(args['listBug'] ?? []),
                listDoos:
                    List<Map<String, dynamic>>.from(args['listDoos'] ?? []),
                news:
                    List<Map<String, dynamic>>.from(args['news'] ?? []),
              ),
            );

          case '/home':
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) => HomePage(
                username: args['username'],
                password: args['password'],
                listBug:
                    List<Map<String, dynamic>>.from(args['listBug'] ?? []),
                role: args['role'],
                expiredDate: args['expiredDate'],
                sessionKey: args['sessionKey'],
              ),
            );

          case '/seller':
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) => SellerPage(keyToken: args['keyToken']),
            );

          case '/admin':
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) => AdminPage(sessionKey: args['sessionKey']),
            );

          default:
            return MaterialPageRoute(
              builder: (_) => const Scaffold(
                body: Center(child: Text('404 - Not Found')),
              ),
            );
        }
      },
    );
  }
}