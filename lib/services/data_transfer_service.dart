import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import '../models/divination_record.dart';
import '../providers/record_list_provider.dart';

class DataTransferService {
  /// 匯出所有紀錄為 JSON 檔案，並且喚起系統分享選單
  Future<void> exportRecords(List<DivinationRecord> records) async {
    if (records.isEmpty) {
      throw Exception('沒有可匯出的紀錄');
    }

    // Convert records to a list of maps
    List<Map<String, dynamic>> jsonData = records
        .map(
          (r) => {
            'id': r.id,
            'createdAt': r.createdAt.toIso8601String(),
            'question': r.question,
            'method': r.method,
            'rawHexagramNumbersStr': r.rawHexagramNumbersStr,
            'primaryHexagramId': r.primaryHexagramId,
            'resultingHexagramId': r.resultingHexagramId,
            'changingLinesStr': r.changingLinesStr,
            'methodDetailJson': r.methodDetailJson,
            'interpretation': r.interpretation,
            'aiInterpretation': r.aiInterpretation,
            'actionTaken': r.actionTaken,
            'actualOutcome': r.actualOutcome,
            'isResolved': r.isResolved,
          },
        )
        .toList();

    String jsonString = jsonEncode(jsonData);

    // Save to temp file
    final tempDir = await getTemporaryDirectory();
    if (!await tempDir.exists()) {
      await tempDir.create(recursive: true);
    }
    final file = File(
      '${tempDir.path}/changelog_backup_${DateTime.now().millisecondsSinceEpoch}.json',
    );
    await file.writeAsString(jsonString);

    // Share the file
    final xFile = XFile(file.path);
    // Ignore the deprecation warning for now since the new API in this version is unstable.
    // ignore: deprecated_member_use
    await Share.shareXFiles([xFile], text: 'ChangeLog Backup');
  }

  /// 喚起檔案選擇器讀取 JSON 檔案，並且將合法資料存入 Database
  Future<int> importRecords(RecordsNotifier notifier) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result == null || result.files.single.path == null) {
      return 0; // User canceled
    }

    final file = File(result.files.single.path!);
    final String jsonString = await file.readAsString();

    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      int importedCount = 0;

      for (var item in jsonList) {
        if (item is Map<String, dynamic>) {
          // Note: ObjectBox IDs are managed by the database, so we insert as new
          // (id = 0) to avoid conflicts, or we can try to keep original IDs but
          // that risks overriding. We will insert as new records.

          final record = DivinationRecord(
            createdAt: DateTime.parse(item['createdAt']),
            question: item['question'] ?? '未命名紀錄',
            method: item['method'] ?? '未知',
            rawHexagramNumbersStr: item['rawHexagramNumbersStr'],
            primaryHexagramId: item['primaryHexagramId'] ?? 1,
            resultingHexagramId: item['resultingHexagramId'],
            changingLinesStr: item['changingLinesStr'],
            methodDetailJson: item['methodDetailJson'],
            interpretation: item['interpretation'],
            actionTaken: item['actionTaken'],
            actualOutcome: item['actualOutcome'],
            isResolved: item['isResolved'] ?? false,
          );
          record.aiInterpretation = item['aiInterpretation'];

          notifier.addRecord(record);
          importedCount++;
        }
      }
      return importedCount;
    } catch (e) {
      throw Exception('檔案格式不正確或讀取失敗: $e');
    }
  }
}
