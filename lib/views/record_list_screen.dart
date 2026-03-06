import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/record_list_provider.dart';
import '../providers/hexagram_provider.dart';
import '../services/data_transfer_service.dart';
import 'record_detail_screen.dart';

class RecordListScreen extends ConsumerWidget {
  const RecordListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final records = ref.watch(recordsProvider);
    final hexagramsAsync = ref.watch(hexagramsProvider);
    final hexagrams = hexagramsAsync.value ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('歷史日誌'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: '匯入備份',
            onPressed: () async {
              try {
                final count = await DataTransferService().importRecords(
                  ref.read(recordsProvider.notifier),
                );
                if (count > 0 && context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('成功匯入 $count 筆紀錄')));
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('匯入失敗: $e')));
                }
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: '匯出備份',
            onPressed: () async {
              try {
                await DataTransferService().exportRecords(records);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('匯出失敗: $e')));
                }
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: records.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history_toggle_off,
                    size: 64,
                    color: Colors.grey[800],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '尚無任何起卦紀錄',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ).animate().fadeIn().slideY(begin: 0.2),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: records.length,
              itemBuilder: (context, index) {
                final record = records[index];

                // 查找對應的本卦名稱
                String primaryName = "未知卦";
                try {
                  primaryName = hexagrams
                      .firstWhere((h) => h.id == record.primaryHexagramId)
                      .name;
                } catch (_) {}

                String resultingName = "";
                if (record.resultingHexagramId != null) {
                  try {
                    resultingName =
                        " 之 ${hexagrams.firstWhere((h) => h.id == record.resultingHexagramId).name}卦";
                  } catch (_) {}
                }

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              RecordDetailScreen(record: record),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withValues(alpha: 0.1),
                              border: Border.all(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary.withValues(alpha: 0.3),
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              primaryName,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  record.question,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '本卦：$primaryName卦$resultingName',
                                  style: TextStyle(
                                    color: Colors.grey[300],
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today,
                                      size: 14,
                                      color: Colors.grey[500],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      DateFormat(
                                        'yyyy-MM-dd HH:mm',
                                      ).format(record.createdAt),
                                      style: TextStyle(
                                        color: Colors.grey[500],
                                        fontSize: 12,
                                      ),
                                    ),
                                    const Spacer(),
                                    if (record.isResolved)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withValues(
                                            alpha: 0.2,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: Colors.green.withValues(
                                              alpha: 0.5,
                                            ),
                                          ),
                                        ),
                                        child: const Text(
                                          '已驗證',
                                          style: TextStyle(
                                            color: Colors.green,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ).animate(delay: (50 * index).ms).fadeIn().slideX(begin: 0.1);
              },
            ),
    );
  }
}
