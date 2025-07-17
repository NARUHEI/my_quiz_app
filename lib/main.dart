// lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';

import 'firebase_options.dart';
import 'screens/company_auth_screen.dart'; // 作成した画面をインポート

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '実践ロープレクイズ',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF005AAA)),
        useMaterial3: true,
        textTheme: GoogleFonts.notoSansJpTextTheme(Theme.of(context).textTheme),
      ),
      home: const CompanyAuthScreen(), // 最初の画面を指定
      debugShowCheckedModeBanner: false,
    );
  }
}
