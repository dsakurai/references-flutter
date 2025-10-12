import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:web/web.dart' as web;


///////////////////////////////////////////////////////////////////////////////////////////////
// LoginApp demonstrates how to use a BFF (Backend For Frontend) with Kanidm for authentication
//

class LoginApp extends StatefulWidget {
  const LoginApp.LoginWidget({super.key});
  @override
  State<LoginApp> createState() => _LoginAppState();
}

const bff = 'https://localhost:8081';
class _LoginAppState extends State<LoginApp> {
  Map<String, dynamic>? _session;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  Future<void> _loadSession() async {
    try {
      final resp = await http.get(Uri.parse('$bff/session'));
      if (resp.statusCode == 200) {
        setState(() => _session = jsonDecode(resp.body));
      }
    } catch (e) {
      print('Session check failed: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  void _login() {
    web.window.location.href = '$bff/login';
  }

  void _logout() {
    web.window.location.href = '$bff/logout';
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter BFF Demo',
      home: Scaffold(
        appBar: AppBar(title: const Text('Flutter + BFF + Kanidm')),
        body: Center(
          child: _loading
              ? const CircularProgressIndicator()
              : _session == null || _session?['ok'] != true
                  ? ElevatedButton(
                      onPressed: _login, child: const Text('Login with Kanidm'))
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Welcome ${_session?['email'] ?? 'user'}'),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _logout,
                          child: const Text('Logout'),
                        ),
                      ],
                    ),
        ),
      ),
    );
  }
}