import 'package:flutter/material.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import './auth_gate.dart'; // 遷移先を修正

class CompanyAuthScreen extends StatefulWidget {
  const CompanyAuthScreen({super.key});
  @override
  State<CompanyAuthScreen> createState() => _CompanyAuthScreenState();
}

class _CompanyAuthScreenState extends State<CompanyAuthScreen> {
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _authenticate() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final remoteConfig = FirebaseRemoteConfig.instance;
      await remoteConfig.fetchAndActivate();
      final companyPassword = remoteConfig.getString('company_secret_password');

      if (companyPassword.isEmpty) {
        throw Exception('共通パスワードが設定されていません。');
      }
      if (_passwordController.text == companyPassword) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const AuthGate()),
          );
        }
      } else {
        throw Exception('共通パスワードが違います。');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '共通パスワードを入力してください',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                onSubmitted: (_) => _authenticate(),
              ),
              const SizedBox(height: 30),
              _isLoading
                  ? const CircularProgressIndicator()
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.secondary,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _authenticate,
                        child: const Text('認証', style: TextStyle(fontSize: 16)),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
