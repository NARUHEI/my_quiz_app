import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class QuestionEditScreen extends StatefulWidget {
  // 編集時はドキュメントを受け取り、新規作成時はnull
  final QueryDocumentSnapshot? questionDoc;

  const QuestionEditScreen({super.key, required this.questionDoc});

  @override
  State<QuestionEditScreen> createState() => _QuestionEditScreenState();
}

class _QuestionEditScreenState extends State<QuestionEditScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // 各フィールドのコントローラー
  late final TextEditingController _idController;
  late final TextEditingController _categoryController;
  late final TextEditingController _scenarioController;
  late final TextEditingController _questionController;
  late final TextEditingController _option1Controller;
  late final TextEditingController _option2Controller;
  late final TextEditingController _option3Controller;
  late final TextEditingController _answerLogicalController;
  late final TextEditingController _answerEmotionalController;
  late final TextEditingController _explanation1Controller;
  late final TextEditingController _explanation2Controller;
  late final TextEditingController _explanation3Controller;

  @override
  void initState() {
    super.initState();

    final data = widget.questionDoc?.data() as Map<String, dynamic>?;
    final options = data?['options'] as List<dynamic>? ?? ['', '', ''];
    final explanations =
        data?['explanations'] as List<dynamic>? ?? ['', '', ''];
    final answers = data?['answers'] as Map<String, dynamic>?;

    _idController = TextEditingController(text: data?['id'] ?? '');
    _categoryController = TextEditingController(text: data?['category'] ?? '');
    _scenarioController = TextEditingController(
      text: data?['scenario']?['text'] ?? '',
    );
    _questionController = TextEditingController(text: data?['question'] ?? '');
    _option1Controller = TextEditingController(
      text: options.isNotEmpty ? options[0].toString() : '',
    );
    _option2Controller = TextEditingController(
      text: options.length > 1 ? options[1].toString() : '',
    );
    _option3Controller = TextEditingController(
      text: options.length > 2 ? options[2].toString() : '',
    );
    _answerLogicalController = TextEditingController(
      text: answers?['論理的']?.toString() ?? '',
    );
    _answerEmotionalController = TextEditingController(
      text: answers?['情緒的']?.toString() ?? '',
    );
    _explanation1Controller = TextEditingController(
      text: explanations.isNotEmpty ? explanations[0].toString() : '',
    );
    _explanation2Controller = TextEditingController(
      text: explanations.length > 1 ? explanations[1].toString() : '',
    );
    _explanation3Controller = TextEditingController(
      text: explanations.length > 2 ? explanations[2].toString() : '',
    );
  }

  @override
  void dispose() {
    // コントローラーを破棄
    _idController.dispose();
    _categoryController.dispose();
    _scenarioController.dispose();
    _questionController.dispose();
    // ... 他のすべてのコントローラーも同様にdispose()
    super.dispose();
  }

  Future<void> _saveQuestion() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _isLoading = true;
    });

    try {
      final data = {
        'id': _idController.text,
        'category': _categoryController.text,
        'scenario': {'text': _scenarioController.text},
        'question': _questionController.text,
        'options': [
          _option1Controller.text,
          _option2Controller.text,
          _option3Controller.text,
        ],
        'answers': {
          '論理的': int.tryParse(_answerLogicalController.text) ?? 0,
          '情緒的': int.tryParse(_answerEmotionalController.text) ?? 0,
        },
        'explanations': [
          _explanation1Controller.text,
          _explanation2Controller.text,
          _explanation3Controller.text,
        ],
      };

      if (widget.questionDoc == null) {
        // 新規作成
        await FirebaseFirestore.instance.collection('quizzes').add(data);
      } else {
        // 更新
        await FirebaseFirestore.instance
            .collection('quizzes')
            .doc(widget.questionDoc!.id)
            .update(data);
      }

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('問題を保存しました。')));
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('保存に失敗しました: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: (value) =>
          (value == null || value.isEmpty) ? '$labelを入力してください' : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.questionDoc == null ? '問題の新規作成' : '問題の編集'),
        actions: [
          IconButton(onPressed: _saveQuestion, icon: const Icon(Icons.save)),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildTextField(_idController, '問題ID (例: q001)'),
                    const SizedBox(height: 16),
                    _buildTextField(_categoryController, 'カテゴリ'),
                    const SizedBox(height: 16),
                    _buildTextField(_scenarioController, '状況'),
                    const SizedBox(height: 16),
                    _buildTextField(_questionController, '問い'),
                    const SizedBox(height: 16),
                    _buildTextField(_option1Controller, '選択肢1 (インデックス0)'),
                    const SizedBox(height: 16),
                    _buildTextField(_option2Controller, '選択肢2 (インデックス1)'),
                    const SizedBox(height: 16),
                    _buildTextField(_option3Controller, '選択肢3 (インデックス2)'),
                    const SizedBox(height: 16),
                    _buildTextField(
                      _answerLogicalController,
                      '正解(論理的): インデックス番号',
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      _answerEmotionalController,
                      '正解(情緒的): インデックス番号',
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(_explanation1Controller, '解説1 (選択肢1に対応)'),
                    const SizedBox(height: 16),
                    _buildTextField(_explanation2Controller, '解説2 (選択肢2に対応)'),
                    const SizedBox(height: 16),
                    _buildTextField(_explanation3Controller, '解説3 (選択肢3に対応)'),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      onPressed: _saveQuestion,
                      child: const Text('保存する'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
