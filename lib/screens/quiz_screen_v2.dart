import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import './result_screen_v2.dart';

// Questionクラスの定義（変更なし）
class Question {
  final String category;
  final String situation;
  final String customerQuote;
  final List<String> options;
  final Map<String, List<int>> points;
  final List<String> explanations;

  Question({
    required this.category,
    required this.situation,
    required this.customerQuote,
    required this.options,
    required this.points,
    required this.explanations,
  });

  factory Question.fromMap(Map<String, dynamic> map) {
    final pointsMap = (map['points'] as Map<String, dynamic>? ?? {}).map(
      (key, value) => MapEntry(key, List<int>.from(value)),
    );
    return Question(
      category: map['category'] as String? ?? '',
      situation: map['situation'] as String? ?? '',
      customerQuote: map['customer_quote'] as String? ?? '',
      options: List<String>.from(map['options'] ?? []),
      points: pointsMap,
      explanations: List<String>.from(map['explanations'] ?? []),
    );
  }
}

class QuizScreenV2 extends StatefulWidget {
  final String personaId;
  const QuizScreenV2({super.key, required this.personaId});

  @override
  State<QuizScreenV2> createState() => _QuizScreenV2State();
}

class _QuizScreenV2State extends State<QuizScreenV2> {
  bool _isLoading = true;
  String? _errorMessage;
  List<Question> _quizQuestions = [];

  int _currentQuestionIndex = 0;
  int _totalScore = 0;
  int _timeLeft = 30;
  Timer? _timer;

  // --- 状態管理の変数を修正 ---
  int? _preSelectedOptionIndex; // ★「仮選択」中の選択肢インデックス
  int? _finalAnswerIndex; // ★「確定」した答えのインデックス
  bool _isAnswerConfirmed = false; // ★回答が「確定」したかどうか
  bool _isBestAnswer = false;
  int? _bestAnswerIndex;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // _loadQuestions, _startTimer は変更なし
  Future<void> _loadQuestions() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final categories = ['不安', '不信', '不要', '不適', '不急', '不金'];
      List<Question> questions = [];
      final random = Random();

      for (final category in categories) {
        final querySnapshot = await FirebaseFirestore.instance
            .collection('quizzes')
            .where('category', isEqualTo: category)
            .get();
        final categoryQuestions = querySnapshot.docs
            .map((doc) => Question.fromMap(doc.data()))
            .toList();
        categoryQuestions.shuffle(random);
        questions.addAll(categoryQuestions.take(2));
      }

      if (questions.length < 12) {
        throw Exception('クイズの問題数が足りません。各カテゴリに2問以上必要です。');
      }
      questions.shuffle(random);
      setState(() {
        _quizQuestions = questions;
        _isLoading = false;
      });
      _startTimer();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = '問題の取得に失敗しました: $e';
        });
      }
    }
  }

  void _startTimer() {
    _timeLeft = 30;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_timeLeft > 0) {
        setState(() {
          _timeLeft--;
        });
      } else {
        _confirmAnswer(); // 時間切れの場合は未選択で回答確定
      }
    });
  }

  // --- 新しいロジック ---
  // ★ 選択肢を「仮選択」するだけの関数
  void _selectOption(int index) {
    setState(() {
      _preSelectedOptionIndex = index;
    });
  }

  // ★「決定」ボタンが押されたときの関数
  void _confirmAnswer() {
    _timer?.cancel();
    int points = 0;
    final question = _quizQuestions[_currentQuestionIndex];

    final bestIndex = question.points[widget.personaId]!.indexOf(15);

    // 時間切れ（_preSelectedOptionIndexがnull）でない場合
    if (_preSelectedOptionIndex != null) {
      points = question.points[widget.personaId]![_preSelectedOptionIndex!];
    }

    setState(() {
      _totalScore += points;
      _isAnswerConfirmed = true;
      _finalAnswerIndex = _preSelectedOptionIndex;
      _bestAnswerIndex = bestIndex;
      _isBestAnswer = (_preSelectedOptionIndex == bestIndex);
    });

    // 最高得点だった場合のみ、2秒後に自動で次へ
    if (_isBestAnswer) {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) _nextQuestion();
      });
    }
  }

  void _nextQuestion() async {
    if (_currentQuestionIndex < _quizQuestions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        // 状態をリセット
        _isAnswerConfirmed = false;
        _preSelectedOptionIndex = null;
        _finalAnswerIndex = null;
        _isBestAnswer = false;
        _bestAnswerIndex = null;
      });
      _startTimer();
    } else {
      if (mounted) {
        await Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ResultScreenV2(totalScore: _totalScore),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // ▼▼▼ この3つのチェックで、データが不完全な場合は先に進まないようにする ▼▼▼
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('問題読み込み中...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('エラー')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(_errorMessage!),
          ),
        ),
      );
    }
    // _quizQuestionsが空の時点で後続の処理に進むとエラーになるため、ここで必ずreturnする
    if (_quizQuestions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('クイズ')),
        body: const Center(child: Text('出題できる問題がありません。')),
      );
    }

    // この時点では、_quizQuestionsにデータが入っていることが保証される
    final currentQuestion = _quizQuestions[_currentQuestionIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '第${_currentQuestionIndex + 1}問 / ${_quizQuestions.length}問',
        ),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 24.0),
        child: Column(
          children: [
            // --- 上部（タイマーと問題文） ---
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.timer_outlined),
                const SizedBox(width: 8),
                Text(
                  '残り時間: $_timeLeft 秒',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '【状況】${currentQuestion.situation}',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '【お客様】「${currentQuestion.customerQuote}」',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // --- 中央（選択肢リスト、スクロール可能） ---
            Expanded(
              child: ListView.builder(
                itemCount: currentQuestion.options.length,
                itemBuilder: (context, index) {
                  Color? tileColor;
                  Icon? leadingIcon;
                  if (_isAnswerConfirmed) {
                    if (index == _bestAnswerIndex) {
                      tileColor = Colors.green.withAlpha(50);
                      leadingIcon = const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                      );
                    } else if (index == _finalAnswerIndex) {
                      tileColor = Colors.red.withAlpha(50);
                      leadingIcon = const Icon(Icons.cancel, color: Colors.red);
                    }
                  } else if (index == _preSelectedOptionIndex) {
                    tileColor = Colors.blue.withAlpha(50);
                  }
                  return Card(
                    color: tileColor,
                    margin: const EdgeInsets.symmetric(vertical: 4.0),
                    child: ListTile(
                      leading: leadingIcon,
                      title: Text(currentQuestion.options[index]),
                      onTap: _isAnswerConfirmed
                          ? null
                          : () => _selectOption(index),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),
            // --- 下部（決定ボタン、解説、次へボタン） ---
            if (!_isAnswerConfirmed)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: _preSelectedOptionIndex != null
                      ? _confirmAnswer
                      : null,
                  child: const Text('決定'),
                ),
              ),
            if (_isAnswerConfirmed)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('【解説】', style: Theme.of(context).textTheme.titleSmall),
                    if (!_isBestAnswer && _bestAnswerIndex != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(
                          "より適切な対応は「${currentQuestion.options[_bestAnswerIndex!]}」です。\n理由: ${currentQuestion.explanations[_bestAnswerIndex!]}",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    if (_finalAnswerIndex != null)
                      Text(currentQuestion.explanations[_finalAnswerIndex!]),
                  ],
                ),
              ),
            if (_isAnswerConfirmed && !_isBestAnswer)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _nextQuestion,
                    child: const Text('次の問題へ'),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
