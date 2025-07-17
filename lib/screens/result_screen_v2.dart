import 'package:flutter/material.dart';

class ResultScreenV2 extends StatelessWidget {
  final int totalScore;
  final int maxScore = 180; // 15点 * 12問

  const ResultScreenV2({super.key, required this.totalScore});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('クイズ結果'),
        automaticallyImplyLeading: false, // 戻るボタンを非表示
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'あなたのスコア',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),
            Text(
              '$totalScore / $maxScore 点',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                // 最初の画面（ペルソナ選択画面）まで戻る
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: const Text('もう一度挑戦する'),
            )
          ],
        ),
      ),
    );
  }
}