import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/hexagram.dart';
import '../../models/divination_record.dart';
import '../../providers/hexagram_provider.dart';
import '../../providers/record_list_provider.dart';
import '../../services/zhuxi_interpreter_service.dart';
import '../../services/ai_interpreter_service.dart';
import 'widgets/hexagram_widget.dart';
import 'hexagram_detail_screen.dart';
import 'home_screen.dart';

class DivinationResultScreen extends ConsumerWidget {
  final List<int>
  lines; // [6, 7, 8, 9] mapped values, 6 elements, index 0 is bottom
  final String question;
  final String method;

  const DivinationResultScreen({
    super.key,
    required this.lines,
    required this.question,
    required this.method,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (lines.length != 6) {
      return const Scaffold(body: Center(child: Text("Invalid lines")));
    }

    final hexagramsAsync = ref.watch(hexagramsProvider);

    return hexagramsAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) =>
          Scaffold(body: Center(child: Text('載入失敗: $error'))),
      data: (_) {
        final hexRepository = ref.watch(hexagramRepositoryProvider);
        final interpreter = ZhuxiInterpreterService();

        // 1. Calculate Primary Hexagram ID
        int primaryId = _linesToId(lines, isResulting: false);
        Hexagram? primaryHex = hexRepository.getById(primaryId);

        // 2. Calculate Resulting Hexagram ID
        bool hasChangingLines = lines.contains(6) || lines.contains(9);
        int? resultingId = hasChangingLines
            ? _linesToId(lines, isResulting: true)
            : null;
        Hexagram? resultingHex = resultingId != null
            ? hexRepository.getById(resultingId)
            : null;

        // 3. Get guidance
        String guidance = interpreter.getInterpretationGuidance(lines);

        return Scaffold(
          appBar: AppBar(title: const Text('起卦結果 (Divination Result)')),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                // Guidance Card
                Card(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.1),
                  shape: RoundedRectangleBorder(
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.lightbulb_outline, color: Colors.orange),
                            SizedBox(width: 8),
                            Text(
                              '朱熹解卦法則建議',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          guidance,
                          style: const TextStyle(fontSize: 16, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Hexagrams Display
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (primaryHex != null)
                      _buildHexagramColumn(
                        context,
                        "本卦",
                        primaryHex,
                        lines,
                        false,
                      ),

                    if (hasChangingLines)
                      const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.grey,
                        size: 32,
                      ),

                    if (resultingHex != null)
                      _buildHexagramColumn(
                        context,
                        "變卦",
                        resultingHex,
                        lines,
                        true,
                      ),
                  ],
                ),

                const SizedBox(height: 48),
                // Action Buttons
                if (primaryHex != null)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _showAIDialog(
                          context,
                          question,
                          primaryHex,
                          resultingHex,
                          guidance,
                        );
                      },
                      icon: const Icon(Icons.auto_awesome),
                      label: const Text('請 AI 大師解卦'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        textStyle: const TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Save to object box
                      final newRecord = DivinationRecord(
                        createdAt: DateTime.now(),
                        question: question,
                        method: method,
                        primaryHexagramId: primaryId,
                        resultingHexagramId: resultingId,
                      );

                      // Keep the raw drawing values
                      newRecord.rawHexagramNumbers = lines;

                      // Calculate moving lines logic specifically (1-based index)
                      List<int> movingLines = [];
                      for (int i = 0; i < lines.length; i++) {
                        if (lines[i] == 6 || lines[i] == 9) {
                          movingLines.add(i + 1);
                        }
                      }
                      newRecord.changingLines = movingLines;

                      ref.read(recordsProvider.notifier).addRecord(newRecord);

                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(const SnackBar(content: Text('紀錄已儲存！')));

                      // Navigate back to history list
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (context) => const HomeScreen(),
                        ),
                        (route) => false,
                      );
                    },
                    icon: const Icon(Icons.save),
                    label: const Text('記錄此次占卜'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      textStyle: const TextStyle(fontSize: 18),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAIDialog(
    BuildContext context,
    String question,
    Hexagram primaryHexagram,
    Hexagram? resultingHexagram,
    String guidance,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.auto_awesome, color: Colors.amber),
              SizedBox(width: 8),
              Text('AI 大師為您解卦...'),
            ],
          ),
          content: FutureBuilder<String>(
            future: AIInterpreterService().interpret(
              question: question,
              primaryHexagram: primaryHexagram,
              resultingHexagram: resultingHexagram,
              guidance: guidance,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('大師正在推演卦理與天機...'),
                  ],
                );
              } else if (snapshot.hasError) {
                return Text('發生錯誤: \n${snapshot.error}');
              } else {
                return SingleChildScrollView(
                  child: Text(
                    snapshot.data ?? '',
                    style: const TextStyle(fontSize: 16, height: 1.6),
                  ),
                );
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('了解'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHexagramColumn(
    BuildContext context,
    String title,
    Hexagram hexagram,
    List<int> originalLines,
    bool isResulting,
  ) {
    // 繪製 HexagramWidget 時，若是變卦，需要把 6, 9 轉成 7, 8 以確保只畫出靜態陰陽
    List<int> drawnLines = isResulting
        ? originalLines.map((l) => (l == 6 || l == 7) ? 7 : 8).toList()
        : originalLines;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HexagramDetailScreen(hexagram: hexagram),
          ),
        );
      },
      child: Column(
        children: [
          Text(title, style: const TextStyle(fontSize: 18, color: Colors.grey)),
          const SizedBox(height: 12),
          Text(
            hexagram.name,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          HexagramWidget(
            lines: drawnLines,
            lineWidth: 80,
            lineHeight: 12,
            spacing: 8,
            yangColor: Colors.white,
            yinColor: Colors.white,
            changingColor: isResulting ? Colors.white : Colors.redAccent,
          ),
          const SizedBox(height: 16),
          const Text(
            '點擊查看詳細',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
              decoration: TextDecoration.underline,
            ),
          ),
        ],
      ),
    );
  }

  // 二進位轉 64 卦 ID (通行本序)
  int _linesToId(List<int> originalLines, {required bool isResulting}) {
    List<int> binaryLines = originalLines.map((l) {
      if (!isResulting) {
        return (l == 7 || l == 9) ? 1 : 0;
      } else {
        return (l == 7 || l == 6) ? 1 : 0;
      }
    }).toList();
    String binaryStr = binaryLines.join();
    return _kingWenMap[binaryStr] ?? 1;
  }

  static const Map<String, int> _kingWenMap = {
    '111111': 1,
    '000000': 2,
    '100010': 3,
    '010001': 4,
    '111010': 5,
    '010111': 6,
    '010000': 7,
    '000010': 8,
    '111011': 9,
    '110111': 10,
    '111000': 11,
    '000111': 12,
    '101111': 13,
    '111101': 14,
    '001000': 15,
    '000100': 16,
    '100110': 17,
    '011001': 18,
    '110000': 19,
    '000011': 20,
    '100101': 21,
    '101001': 22,
    '000001': 23,
    '100000': 24,
    '100111': 25,
    '111001': 26,
    '100001': 27,
    '011110': 28,
    '010010': 29,
    '101101': 30,
    '001110': 31,
    '011100': 32,
    '001111': 33,
    '111100': 34,
    '000101': 35,
    '101000': 36,
    '101011': 37,
    '110101': 38,
    '001010': 39,
    '010100': 40,
    '110001': 41,
    '100011': 42,
    '111110': 43,
    '011111': 44,
    '000110': 45,
    '011000': 46,
    '010110': 47,
    '011010': 48,
    '101110': 49,
    '011101': 50,
    '100100': 51,
    '001001': 52,
    '001011': 53,
    '110100': 54,
    '101100': 55,
    '001101': 56,
    '011011': 57,
    '110110': 58,
    '010011': 59,
    '110010': 60,
    '110011': 61,
    '001100': 62,
    '101010': 63,
    '010101': 64,
  };
}
