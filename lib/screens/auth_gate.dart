import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import './login_screen.dart';
// import './persona_selection_screen.dart'; // ← 不要なので削除
import './persona_selection_screen_v2.dart'; // ← 新しい画面をインポート

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasData) {
          // ▼▼▼ 遷移先をV2に変更 ▼▼▼
          return const PersonaSelectionScreenV2();
        }
        return const LoginScreen();
      },
    );
  }
}