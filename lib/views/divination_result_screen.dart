import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/hexagram.dart';
import '../../models/divination_record.dart';
import '../../providers/hexagram_provider.dart';
import '../../providers/record_list_provider.dart';
import '../../providers/divination_provider.dart';
import '../../services/zhuxi_interpreter_service.dart';
import 'widgets/hexagram_widget.dart';
import 'hexagram_detail_screen.dart';
import 'home_screen.dart';
import 'settings_screen.dart';
import '../../services/ad_service.dart';
import '../../services/storage_service.dart';
import '../../providers/database_provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

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
                // Main Call to Action: AI Interpretation
                if (primaryHex != null)
                  Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            // 1. 先建立基礎紀錄並取得 ID，確保後續 AI 結果有地方存
                            final recordsNotifier = ref.read(
                              recordsProvider.notifier,
                            );
                            final newRecord = DivinationRecord(
                              createdAt: DateTime.now(),
                              question: question,
                              method: method,
                              primaryHexagramId: primaryId,
                              resultingHexagramId: resultingId,
                            );
                            newRecord.rawHexagramNumbers = lines;

                            // 計算變爻 (1-based)
                            List<int> movingLines = [];
                            for (int i = 0; i < lines.length; i++) {
                              if (lines[i] == 6 || lines[i] == 9) {
                                movingLines.add(i + 1);
                              }
                            }
                            newRecord.changingLines = movingLines;

                            // 儲存並取得包含 ID 的實體
                            final savedRecord = recordsNotifier.addRecord(
                              newRecord,
                            );

                            if (context.mounted) {
                              _showAIDialog(
                                context,
                                ref,
                                question,
                                primaryHex,
                                resultingHex,
                                guidance,
                                savedRecord.id,
                              );
                            }
                          },
                          icon: const Icon(Icons.auto_awesome),
                          label: const Text('✨ 獲取 AI 指引與解釋'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 18,
                            ),
                            textStyle: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            elevation: 8,
                            shadowColor: Colors.purple.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton.icon(
                        onPressed: () async {
                          // 僅儲存基本紀錄
                          final recordsNotifier = ref.read(
                            recordsProvider.notifier,
                          );
                          final newRecord = DivinationRecord(
                            createdAt: DateTime.now(),
                            question: question,
                            method: method,
                            primaryHexagramId: primaryId,
                            resultingHexagramId: resultingId,
                          );
                          newRecord.rawHexagramNumbers = lines;
                          recordsNotifier.addRecord(newRecord);

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('已記錄卦象資訊。')),
                            );
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder: (context) => const HomeScreen(),
                              ),
                              (route) => false,
                            );
                          }
                        },
                        icon: const Icon(Icons.save_alt, size: 16),
                        label: const Text('僅保存卦象文字，不使用 AI'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey,
                        ),
                      ),
                    ],
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
    WidgetRef ref,
    String question,
    Hexagram primaryHexagram,
    Hexagram? resultingHexagram,
    String guidance,
    int? recordId,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return _AIDialogContent(
          question: question,
          primaryHexagram: primaryHexagram,
          resultingHexagram: resultingHexagram,
          guidance: guidance,
          recordId: recordId,
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

class _AIDialogContent extends ConsumerStatefulWidget {
  final String question;
  final Hexagram primaryHexagram;
  final Hexagram? resultingHexagram;
  final String guidance;
  final int? recordId;

  const _AIDialogContent({
    required this.question,
    required this.primaryHexagram,
    this.resultingHexagram,
    required this.guidance,
    this.recordId,
  });

  @override
  ConsumerState<_AIDialogContent> createState() => _AIDialogContentState();
}

class _AIDialogContentState extends ConsumerState<_AIDialogContent> {
  late Future<String> _interpretationFuture;
  bool _isLoadingAd = false;

  @override
  void initState() {
    super.initState();
    _startInterpretation();
  }

  void _startInterpretation() {
    _interpretationFuture = ref
        .read(aiInterpreterServiceProvider)
        .interpret(
          question: widget.question,
          primaryHexagram: widget.primaryHexagram,
          resultingHexagram: widget.resultingHexagram,
          guidance: widget.guidance,
        );
  }

  void _watchAd() {
    setState(() => _isLoadingAd = true);
    AdService.loadRewardedAd(
      onAdLoaded: (ad) {
        setState(() => _isLoadingAd = false);
        ad.show(
          onUserEarnedReward: (view, reward) async {
            final storage = ref.read(storageServiceProvider);
            await storage.addAdCredits(3);
            if (mounted) {
              setState(() {
                _startInterpretation();
              });
            }
          },
        );
      },
      onAdFailedToLoad: (err) {
        setState(() => _isLoadingAd = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('廣告載入失敗：${err.message}')));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.auto_awesome, color: Colors.amber),
          SizedBox(width: 8),
          Text('AI 大師為您解卦...'),
        ],
      ),
      content: FutureBuilder<String>(
        future: _interpretationFuture,
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
            final errStr = snapshot.error.toString();
            final isAdException = errStr.contains('無免費解卦額度');

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isAdException ? '您的免費 AI 解卦額度已用盡。' : '發生錯誤: \\n$errStr',
                  style: const TextStyle(color: Colors.redAccent),
                ),
                const SizedBox(height: 24),
                if (isAdException) ...[
                  if (_isLoadingAd)
                    const CircularProgressIndicator()
                  else
                    ElevatedButton.icon(
                      onPressed: _watchAd,
                      icon: const Icon(Icons.play_circle_filled),
                      label: const Text('觀看廣告獲取 3 次額度'),
                    ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SettingsScreen(),
                        ),
                      ).then((_) {
                        if (mounted) setState(() => _startInterpretation());
                      });
                    },
                    child: const Text('或使用您自己的 API Key (BYOK)'),
                  ),
                ],
              ],
            );
          } else {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  MarkdownBody(
                    data: snapshot.data ?? '',
                    styleSheet: MarkdownStyleSheet.fromTheme(
                      Theme.of(context),
                    ).copyWith(p: const TextStyle(fontSize: 16, height: 1.6)),
                  ),
                ],
              ),
            );
          }
        },
      ),
      actions: [
        if (!_isLoadingAd) ...[
          FutureBuilder<String>(
            future: _interpretationFuture,
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                return TextButton.icon(
                  onPressed: () async {
                    final recordsNotifier = ref.read(recordsProvider.notifier);

                    final id = widget.recordId;
                    if (id != null) {
                      // 取得具體的紀錄
                      final recordRepository = ref.read(
                        recordRepositoryProvider,
                      );
                      final record = recordRepository.getRecord(id);
                      if (record != null) {
                        record.aiInterpretation = snapshot.data;
                        recordsNotifier.updateRecord(record);

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('AI 解卦已成功更新至紀錄！')),
                          );
                          Navigator.of(context).pop();
                        }
                      }
                    }
                  },
                  icon: const Icon(Icons.bookmark_added_outlined),
                  label: const Text('更新解卦至紀錄'),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('了解 / 關閉'),
          ),
        ],
      ],
    );
  }
}
