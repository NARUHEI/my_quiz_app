// lib/screens/mode_selection_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import './quiz_screen.dart';

class ModeSelectionScreen extends StatelessWidget {
  final String persona;
  const ModeSelectionScreen({super.key, required this.persona});

  // カテゴリをFirestoreから非同期で取得する関数
  Future<List<String>> _fetchCategories() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('quizzes')
        .get();
    // Setを使って重複を除外し、Listに変換して返す
    final categories = snapshot.docs
        .map((doc) => doc['category'] as String)
        .toSet()
        .toList();
    return categories;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('クイズ選択 ($persona)'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<String>>(
        future: _fetchCategories(), // 非同期でカテゴリを取得
        builder: (context, snapshot) {
          // データ取得中
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // エラー発生
          if (snapshot.hasError) {
            return Center(child: Text('エラー: ${snapshot.error}'));
          }
          // データがない場合
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('クイズカテゴリが見つかりません。'));
          }

          final categories = snapshot.data!;
          // 取得したカテゴリでリストを生成
          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: ListView.separated(
              itemCount: categories.length + 1,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                if (index < categories.length) {
                  final category = categories[index];
                  return ListTile(
                    title: Text(category),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              QuizScreen(persona: persona, mode: category),
                        ),
                      );
                    },
                  );
                } else {
                  const mode = 'ランダム10問';
                  return ListTile(
                    leading: const Icon(Icons.shuffle),
                    title: const Text(
                      'ランダム10問 力試しテスト',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              QuizScreen(persona: persona, mode: mode),
                        ),
                      );
                    },
                  );
                }
              },
            ),
          );
        },
      ),
    );
  }
}
