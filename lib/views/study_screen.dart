import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/hexagram_provider.dart';
import '../models/hexagram.dart';
import 'hexagram_detail_screen.dart';
import 'ten_wing_detail_screen.dart';
import '../constants/ten_wings.dart';

class StudyScreen extends ConsumerStatefulWidget {
  const StudyScreen({super.key});

  @override
  ConsumerState<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends ConsumerState<StudyScreen>
    with SingleTickerProviderStateMixin {
  String _searchQuery = '';
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hexagramsAsyncValue = ref.watch(hexagramsProvider);
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('易經與易傳'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: primary,
          tabs: const [
            Tab(text: '六十四卦'),
            Tab(text: '十翼 (易傳)'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildHexagramsView(hexagramsAsyncValue, primary),
          _buildTenWingsView(),
        ],
      ),
    );
  }

  Widget _buildHexagramsView(
    AsyncValue<List<Hexagram>> hexagramsAsyncValue,
    Color primary,
  ) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: TextField(
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: '搜尋卦名或編號',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ).animate().fadeIn().slideY(begin: -0.2, end: 0),
        ),
        Expanded(
          child: hexagramsAsyncValue.when(
            data: (hexagrams) {
              final filtered = hexagrams.where((h) {
                return h.name.contains(_searchQuery) ||
                    h.id.toString() == _searchQuery;
              }).toList();

              if (filtered.isEmpty) {
                return const Center(
                  child: Text(
                    '找不到符合的卦象',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                );
              }

              final width = MediaQuery.of(context).size.width;
              final crossAxisCount = width > 900
                  ? 4
                  : width > 600
                      ? 3
                      : 2;

              return GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.85,
                ),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final hexagram = filtered[index];
                  return _HexagramCard(
                    hexagram: hexagram,
                    index: index,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              HexagramDetailScreen(hexagram: hexagram),
                        ),
                      );
                    },
                  );
                },
              );
            },
            loading: () =>
                Center(child: CircularProgressIndicator(color: primary)),
            error: (err, stack) => Center(child: Text('下載失敗: $err')),
          ),
        ),
      ],
    );
  }

  Widget _buildTenWingsView() {
    final keys = tenWingsData.keys.toList();
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: keys.length,
      itemBuilder: (context, index) {
        final title = keys[index];
        final content = tenWingsData[title]!;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 8,
            ),
            leading: Icon(
              Icons.menu_book,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      TenWingDetailScreen(title: title, content: content),
                ),
              );
            },
          ),
        ).animate().fadeIn(delay: (50 * index).ms).slideX(begin: 0.1, end: 0);
      },
    );
  }
}

class _HexagramCard extends StatelessWidget {
  final Hexagram hexagram;
  final int index;
  final VoidCallback onTap;

  const _HexagramCard({
    required this.hexagram,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).colorScheme.surface,
                    primary.withValues(alpha: 0.05),
                  ],
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Hero(
                    tag: 'hexagram_id_${hexagram.id}',
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: primary.withValues(alpha: 0.1),
                        border: Border.all(
                          color: primary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        '${hexagram.id}',
                        style: TextStyle(
                          fontSize: 18,
                          color: primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${hexagram.name}卦',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '進入字典察看詳情',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          ),
        )
        .animate(delay: (50 * index).ms)
        .fadeIn(duration: 300.ms)
        .slideY(begin: 0.2, end: 0, curve: Curves.easeOutQuad);
  }
}
