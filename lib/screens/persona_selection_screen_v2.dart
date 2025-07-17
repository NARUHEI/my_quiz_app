import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import './quiz_screen_v2.dart';
import './my_page_screen.dart';
import './admin_dashboard_screen.dart';

// (Personaクラスの定義は変更なし)
class Persona {
  final String id;
  final String name;
  final IconData icon;
  const Persona({required this.id, required this.name, required this.icon});
}


// ★★★ StatelessWidgetからStatefulWidgetに変更 ★★★
class PersonaSelectionScreenV2 extends StatefulWidget {
  const PersonaSelectionScreenV2({super.key});

  @override
  State<PersonaSelectionScreenV2> createState() => _PersonaSelectionScreenV2State();
}

class _PersonaSelectionScreenV2State extends State<PersonaSelectionScreenV2> {
  final List<Persona> personas = const [
    Persona(id: 'male_solo', name: '論理的男性', icon: Icons.person_outline),
    Persona(id: 'female_solo', name: '共感重視の女性', icon: Icons.person_2_outlined),
    Persona(id: 'parent_child', name: '親と子', icon: Icons.escalator_warning),
    Persona(id: 'family', name: 'ファミリー', icon: Icons.family_restroom),
  ];

  // ★★★ ユーザーロールの取得ロジックを追加 ★★★
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _fetchUserRole();
  }

  Future<void> _fetchUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (mounted && doc.exists && doc.data()!.containsKey('role')) {
      setState(() {
        _userRole = doc.data()!['role'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ペルソナを選択'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
            tooltip: 'ログアウト',
          ),
        ],
      ),
      // ★★★ Columnでラップしてボタンを追加 ★★★
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                  childAspectRatio: 1,
                ),
                itemCount: personas.length,
                itemBuilder: (context, index) {
                  final persona = personas[index];
                  return Card(
                    elevation: 4,
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => QuizScreenV2(personaId: persona.id),
                          ),
                        );
                      },
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(persona.icon, size: 50, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(height: 15),
                          Text(persona.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            // ★★★ ここにボタンを追加 ★★★
            TextButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const MyPageScreen()));
              },
              child: const Text('マイページ（成績一覧）を見る'),
            ),
            if (_userRole == 'admin')
              TextButton.icon(
                icon: const Icon(Icons.admin_panel_settings),
                label: const Text('管理者ダッシュボード'),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminDashboardScreen()));
                },
              ),
          ],
        ),
      ),
    );
  }
}