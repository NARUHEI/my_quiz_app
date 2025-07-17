import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import './question_management_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});
  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _searchController = TextEditingController();
  List<QueryDocumentSnapshot>? _allAttempts;
  List<QueryDocumentSnapshot>? _filteredAttempts;
  Map<String, String> _userMap = {};
  Map<String, dynamic> _categoryStats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .get();
      _userMap = {
        for (var doc in usersSnapshot.docs)
          doc.id: doc.data()['employeeId'] ?? '不明',
      };

      final attemptsSnapshot = await FirebaseFirestore.instance
          .collection('quizAttempts')
          .orderBy('timestamp', descending: true)
          .get();
      _allAttempts = attemptsSnapshot.docs;

      _calculateCategoryStats(_allAttempts!);

      setState(() {
        _filteredAttempts = _allAttempts;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("データの読み込みに失敗しました: $e")));
      }
    }
  }

  void _calculateCategoryStats(List<QueryDocumentSnapshot> attempts) {
    Map<String, dynamic> stats = {};
    for (var attemptDoc in attempts) {
      final data = attemptDoc.data() as Map<String, dynamic>;
      final mode = data['mode'] as String;
      final score = data['score'] as int;
      final totalQuestions = data['totalQuestions'] as int;

      // 修正済みの箇所
      if (mode == 'ランダム10問') {
        continue;
      }

      if (!stats.containsKey(mode)) {
        stats[mode] = {'correct': 0, 'total': 0};
      }
      stats[mode]['correct'] += score;
      stats[mode]['total'] += totalQuestions;
    }
    _categoryStats = stats;
  }

  void _onSearch() {
    final searchEmployeeId = _searchController.text;
    if (searchEmployeeId.isEmpty) {
      _onReset();
      return;
    }
    String? targetUid;
    _userMap.forEach((uid, employeeId) {
      if (employeeId == searchEmployeeId) {
        targetUid = uid;
      }
    });
    setState(() {
      if (targetUid != null) {
        _filteredAttempts = _allAttempts
            ?.where((doc) => doc['userId'] == targetUid)
            .toList();
        // このif文にも波括弧を追加しました
        if (_filteredAttempts != null) {
          _calculateCategoryStats(_filteredAttempts!);
        }
      } else {
        _filteredAttempts = [];
        _categoryStats = {};
      }
    });
  }

  void _onReset() {
    _searchController.clear();
    setState(() {
      _filteredAttempts = _allAttempts;
      // このif文にも波括弧を追加しました
      if (_allAttempts != null) {
        _calculateCategoryStats(_allAttempts!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('管理者ダッシュボード'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            labelText: '社員番号で検索',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton(
                        onPressed: _onSearch,
                        icon: const Icon(Icons.search),
                      ),
                      IconButton(
                        onPressed: _onReset,
                        icon: const Icon(Icons.refresh),
                      ),
                    ],
                  ),
                ),
                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _searchController.text.isEmpty
                              ? '全体のカテゴリ別正答率'
                              : '${_searchController.text}さんのカテゴリ別正答率',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 10),
                        if (_categoryStats.isEmpty) const Text('データがありません'),
                        ..._categoryStats.entries.map((entry) {
                          final category = entry.key;
                          final stats = entry.value;
                          final correct = stats['correct'];
                          final total = stats['total'];
                          final rate = total > 0
                              ? (correct / total * 100).toStringAsFixed(0)
                              : 0;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(category),
                                Text('$rate % ($correct/$total)'),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 20),
                // ★★★ ここから追加 ★★★
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.edit_note),
                    label: const Text('問題の追加・編集・削除'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 40),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const QuestionManagementScreen(),
                        ),
                      );
                    },
                  ),
                ),
                // ★★★ ここまで追加 ★★★
                const Divider(height: 20),

                Expanded(
                  child:
                      (_filteredAttempts == null || _filteredAttempts!.isEmpty)
                      ? const Center(child: Text('該当する解答履歴はありません。'))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          itemCount: _filteredAttempts!.length,
                          itemBuilder: (context, index) {
                            final attempt =
                                _filteredAttempts![index].data()
                                    as Map<String, dynamic>;
                            final timestamp =
                                (attempt['timestamp'] as Timestamp?)?.toDate();
                            final formattedDate = timestamp != null
                                ? DateFormat(
                                    'yyyy/MM/dd HH:mm',
                                  ).format(timestamp)
                                : '日時不明';
                            final score = attempt['score'] ?? 0;
                            final totalQuestions =
                                attempt['totalQuestions'] ?? 0;
                            final userId = attempt['userId'] as String;
                            final employeeId = _userMap[userId] ?? '不明';

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 5),
                              child: ListTile(
                                leading: CircleAvatar(child: Text('$score')),
                                title: Text(
                                  '${attempt['mode']} (${attempt['persona']})',
                                ),
                                subtitle: Text(
                                  '社員番号: $employeeId\n$formattedDate',
                                ),
                                isThreeLine: true,
                                trailing: Text(
                                  '$score / $totalQuestions 問',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
