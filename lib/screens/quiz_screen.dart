import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';

import './result_screen.dart';

class QuizScreen extends StatefulWidget {
  final String persona;
  final String mode;
  const QuizScreen({super.key, required this.persona, required this.mode});
  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  List<Map<String, dynamic>> _quizQuestions = [];
  int _currentQuestionIndex = 0;
  int? _selectedOptionIndex;
  bool _isAnswered = false;
  List<Map<String, dynamic>> _userAnswers = [];
  bool _isLoading = true; // ローディング状態

  @override
  void initState() {
    super.initState();
    _loadQuizData();
  }

  Future<void> _loadQuizData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      QuerySnapshot<Map<String, dynamic>> snapshot;
      final collection = FirebaseFirestore.instance.collection('quizzes');

      if (widget.mode == 'ランダム10問') {
        snapshot = await collection.get();
      } else {
        snapshot = await collection
            .where('category', isEqualTo: widget.mode)
            .get();
      }

      final allQuestions = snapshot.docs.map((doc) {
        return {'docId': doc.id, ...doc.data()};
      }).toList();

      allQuestions.shuffle(Random());

      setState(() {
        _quizQuestions = allQuestions.take(10).toList();
        _userAnswers = [];
        _isLoading = false;
      });
    } catch (e) {
      // エラーハンドリング
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('クイズの読み込みに失敗しました: $e')));
      }
    }
  }

  void _submitAnswer() {
    if (_selectedOptionIndex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('選択肢を選んでください。'),
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }
    final question = _quizQuestions[_currentQuestionIndex];
    // 'answers'フィールドがマップであることを確認
    final answersMap = question['answers'] as Map<String, dynamic>;
    final correctAnswerIndex = answersMap[widget.persona];

    final isCorrect = _selectedOptionIndex == correctAnswerIndex;
    _userAnswers.add({
      'questionId': question['id'], // 'id'フィールドがあることを前提
      'selectedOption': _selectedOptionIndex,
      'isCorrect': isCorrect,
    });
    setState(() {
      _isAnswered = true;
    });
  }

  Future<void> _nextQuestion() async {
    if (_currentQuestionIndex < _quizQuestions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _selectedOptionIndex = null;
        _isAnswered = false;
      });
    } else {
      await _saveResultsAndNavigate();
    }
  }

  Future<void> _saveResultsAndNavigate() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final score = _userAnswers.where((answer) => answer['isCorrect']).length;
    final totalQuestions = _quizQuestions.length;
    await FirebaseFirestore.instance.collection('quizAttempts').add({
      'userId': user.uid,
      'timestamp': FieldValue.serverTimestamp(),
      'mode': widget.mode,
      'persona': widget.persona,
      'score': score,
      'totalQuestions': totalQuestions,
      'results': _userAnswers,
    });
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              ResultScreen(score: score, totalQuestions: totalQuestions),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // ローディング中の表示
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.mode)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    // 取得した問題がない場合の表示
    if (_quizQuestions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.mode)),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('このカテゴリの問題はありません。'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('選択画面に戻る'),
              ),
            ],
          ),
        ),
      );
    }

    // --- ここからがクイズ本体の描画処理です ---
    final question = _quizQuestions[_currentQuestionIndex];
    final options = question['options'] as List<dynamic>; // List<dynamic>に
    final answersMap = question['answers'] as Map<String, dynamic>;
    final correctAnswerIndex = answersMap[widget.persona];

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.mode} (${widget.persona})'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LinearProgressIndicator(
                value: (_currentQuestionIndex + 1) / _quizQuestions.length,
                minHeight: 10,
                borderRadius: BorderRadius.circular(5),
              ),
              const SizedBox(height: 20),
              Text(
                '第 ${_currentQuestionIndex + 1} 問',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(15),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '【状況】: ${question['scenario']['text']}',
                  style: const TextStyle(fontSize: 16, height: 1.5),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                '【問い】: ${question['question']}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              ...options.asMap().entries.map((entry) {
                int index = entry.key;
                String text = entry.value.toString();
                Color? buttonColor;
                BorderSide borderSide = BorderSide(color: Colors.grey.shade400);
                if (_isAnswered) {
                  if (index == correctAnswerIndex) {
                    buttonColor = Colors.green[50];
                    borderSide = const BorderSide(
                      color: Colors.green,
                      width: 2,
                    );
                  } else if (index == _selectedOptionIndex) {
                    buttonColor = Colors.red[50];
                    borderSide = const BorderSide(color: Colors.red, width: 2);
                  }
                } else if (index == _selectedOptionIndex) {
                  buttonColor = Colors.blue[100];
                  borderSide = const BorderSide(color: Colors.blue, width: 2);
                }
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5.0),
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.all(15),
                      backgroundColor: buttonColor,
                      side: borderSide,
                    ),
                    onPressed: _isAnswered
                        ? null
                        : () {
                            setState(() {
                              _selectedOptionIndex = index;
                            });
                          },
                    child: Text(
                      text,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                );
              }),
              if (_isAnswered)
                Container(
                  margin: const EdgeInsets.only(top: 20),
                  padding: const EdgeInsets.all(15),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.amber[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Text(
                    '【解説】: ${(question['explanations'] as List<dynamic>)[correctAnswerIndex]}',
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),
                ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('モード選択に戻る'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    onPressed: _isAnswered ? _nextQuestion : _submitAnswer,
                    child: Text(
                      _isAnswered
                          ? (_currentQuestionIndex < _quizQuestions.length - 1
                                ? '次の問題へ'
                                : '結果を見る')
                          : '回答する',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
