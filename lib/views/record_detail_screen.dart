import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/divination_record.dart';
import '../models/hexagram.dart';
import '../providers/record_list_provider.dart';
import '../providers/hexagram_provider.dart';
import '../services/zhuxi_interpreter_service.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'widgets/ai_markdown_style.dart';
import 'widgets/hexagram_column.dart';
import 'widgets/yarrow_detail_section.dart';

class RecordDetailScreen extends ConsumerStatefulWidget {
  final DivinationRecord record;

  const RecordDetailScreen({super.key, required this.record});

  @override
  ConsumerState<RecordDetailScreen> createState() => _RecordDetailScreenState();
}

class _RecordDetailScreenState extends ConsumerState<RecordDetailScreen> {
  late TextEditingController _interpretationCtrl;
  late TextEditingController _actionCtrl;
  late TextEditingController _outcomeCtrl;
  late bool _isResolved;

  @override
  void initState() {
    super.initState();
    _interpretationCtrl = TextEditingController(
      text: widget.record.interpretation,
    );
    _actionCtrl = TextEditingController(text: widget.record.actionTaken);
    _outcomeCtrl = TextEditingController(text: widget.record.actualOutcome);
    _isResolved = widget.record.isResolved;
  }

  @override
  void dispose() {
    _interpretationCtrl.dispose();
    _actionCtrl.dispose();
    _outcomeCtrl.dispose();
    super.dispose();
  }

  void _saveChanges() {
    final updatedRecord = widget.record
      ..interpretation = _interpretationCtrl.text
      ..actionTaken = _actionCtrl.text
      ..actualOutcome = _outcomeCtrl.text
      ..isResolved = _isResolved;

    ref.read(recordsProvider.notifier).updateRecord(updatedRecord);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('已儲存變更')));
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final hexRepository = ref.watch(hexagramRepositoryProvider);

    // 取得本卦與之卦
    Hexagram? primaryHex;
    Hexagram? resultingHex;
    try {
      primaryHex = hexRepository.getById(widget.record.primaryHexagramId);
      if (widget.record.resultingHexagramId != null) {
        resultingHex = hexRepository.getById(
          widget.record.resultingHexagramId!,
        );
      }
    } catch (_) {}

    final rawLines = widget.record.rawHexagramNumbers;
    String guidance = "尚無可用指引";
    if (rawLines != null) {
      guidance = ZhuxiInterpreterService().getInterpretationGuidance(rawLines);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('解卦日誌'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.grey),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('刪除紀錄？'),
                  content: const Text('確定要永久刪除這筆占卜紀錄嗎？此動作無法復原。'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('取消'),
                    ),
                    TextButton(
                      onPressed: () {
                        ref
                            .read(recordsProvider.notifier)
                            .deleteRecord(widget.record.id);
                        Navigator.pop(context); // 關對話框
                        Navigator.pop(context); // 退回列表頁
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(const SnackBar(content: Text('紀錄已刪除')));
                      },
                      child: const Text(
                        '確認刪除',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () {
              FocusScope.of(context).unfocus(); // 收起鍵盤
              _saveChanges();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 第一區塊：提問與日期
            Text(
              widget.record.question,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                height: 1.4,
              ),
            ).animate().fadeIn().slideX(begin: -0.1),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey[400]),
                const SizedBox(width: 8),
                Text(
                  DateFormat(
                    'yyyy年MM月dd日 HH:mm',
                  ).format(widget.record.createdAt),
                  style: TextStyle(color: Colors.grey[400], fontSize: 14),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: primary.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    widget.record.method,
                    style: TextStyle(
                      color: primary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 100.ms),

            const SizedBox(height: 32),

            // 第二區塊：卦象圖騰與結果
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        if (primaryHex != null && rawLines != null)
                          HexagramColumn(
                            title: '本卦',
                            hexagram: primaryHex,
                            originalLines: rawLines,
                          ),
                        if (resultingHex != null && rawLines != null) ...[
                          Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.grey[600],
                            size: 32,
                          ),
                          HexagramColumn(
                            title: '之卦',
                            hexagram: resultingHex,
                            originalLines: rawLines,
                            isResulting: true,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.explore, color: primary, size: 20),
                              const SizedBox(width: 8),
                              const Text(
                                '閱讀建議 (朱熹解卦法則)',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(guidance, style: const TextStyle(height: 1.5)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),

            const SizedBox(height: 32),

            if (widget.record.method == '籌策') ...[
              YarrowDetailSection(
                methodDetailJson: widget.record.methodDetailJson,
                rawLines: rawLines,
              ),
              const SizedBox(height: 32),
            ],

            // AI 解卦區塊 (如果有存的話)
            if (widget.record.aiInterpretation != null &&
                widget.record.aiInterpretation!.isNotEmpty) ...[
              Row(
                children: [
                  const Icon(Icons.auto_awesome, color: Colors.amber, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'AI 大師解析',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ).animate().fadeIn(delay: 250.ms),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.purple.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.purple.withValues(alpha: 0.2),
                  ),
                ),
                child: MarkdownBody(
                  data: widget.record.aiInterpretation!,
                  styleSheet: buildAIMarkdownStyle(context),
                ),
              ).animate().fadeIn(delay: 280.ms),
              const SizedBox(height: 32),
            ],

            // 第三區塊：輸入反思紀錄
            Row(
              children: [
                Icon(Icons.edit_note, color: primary),
                const SizedBox(width: 8),
                const Text(
                  '自己如何解卦',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ).animate().fadeIn(delay: 300.ms),
            const SizedBox(height: 16),
            TextField(
              controller: _interpretationCtrl,
              maxLines: 4,
              decoration: _inputDecoration(
                '輸入您的解讀...',
                helperText: '記下你現在的理解，不必一次寫完整。',
              ),
            ).animate().fadeIn(delay: 400.ms),

            const SizedBox(height: 24),
            Row(
              children: [
                Icon(Icons.directions_run, color: primary),
                const SizedBox(width: 8),
                const Text(
                  '決定怎麼做 (Action Plan)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ).animate().fadeIn(delay: 500.ms),
            const SizedBox(height: 16),
            TextField(
              controller: _actionCtrl,
              maxLines: 3,
              decoration: _inputDecoration(
                '根據卦象，接下來打算如何行動？',
                helperText: '把卦象帶來的提醒轉成可觀察的行動。',
              ),
            ).animate().fadeIn(delay: 600.ms),

            const SizedBox(height: 48),
            // 第四區塊：後續驗證
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white24),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '事後驗證追蹤',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Switch(
                        value: _isResolved,
                        onChanged: (val) => setState(() => _isResolved = val),
                        activeThumbColor: primary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '事情經過一段時間後，不妨回來校準當初的判斷。',
                    style: TextStyle(color: Colors.grey[500], fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _outcomeCtrl,
                    maxLines: 3,
                    decoration: _inputDecoration(
                      '這件事後來實際上是如何發展的？',
                      helperText: '過一段時間回來記錄實際發展。',
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 700.ms),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, {String? helperText}) {
    return InputDecoration(
      hintText: hint,
      helperText: helperText,
      helperMaxLines: 2,
      filled: true,
      fillColor: Theme.of(context).colorScheme.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.primary,
          width: 2,
        ),
      ),
    );
  }
}
