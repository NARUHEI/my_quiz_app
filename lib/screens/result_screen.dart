// lib/screens/result_screen.dart

import 'package:flutter/material.dart';
import './my_page_screen.dart';

class ResultScreen extends StatelessWidget {
  final int score;
  final int totalQuestions;
  const ResultScreen({
    super.key,
    required this.score,
    required this.totalQuestions,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('クイズ結果'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: Colors.green,
              size: 80,
            ),
            const SizedBox(height: 20),
            const Text(
              'クイズ終了！',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Text(
              'あなたのスコア: $score / $totalQuestions 問正解',
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 40),
            Column(
              children: [
                SizedBox(
                  width: 250,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => const MyPageScreen(),
                        ),
                      );
                    },
                    child: const Text('成績一覧を見る'),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: 250,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    onPressed: () {
                      // スタックの最初のページ（PersonaSelectionScreen）まで戻る
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    child: const Text('トップに戻る'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
