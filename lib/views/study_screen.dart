import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/hexagram_provider.dart';
import '../models/hexagram.dart';
import 'hexagram_detail_screen.dart';

class StudyScreen extends ConsumerStatefulWidget {
  const StudyScreen({super.key});

  @override
  ConsumerState<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends ConsumerState<StudyScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final hexagramsAsyncValue = ref.watch(hexagramsProvider);
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('易經六十四卦'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
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
        ),
      ),
      body: hexagramsAsyncValue.when(
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

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
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
        loading: () => Center(child: CircularProgressIndicator(color: primary)),
        error: (err, stack) => Center(child: Text('下載卦象失敗: $err')),
      ),
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
