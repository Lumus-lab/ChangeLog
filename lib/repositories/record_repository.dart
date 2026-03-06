import '../models/divination_record.dart';
import '../objectbox.g.dart';
import 'objectbox_service.dart';

class RecordRepository {
  final Box<DivinationRecord> _box;

  RecordRepository(ObjectBoxService objectbox)
    : _box = objectbox.store.box<DivinationRecord>();

  /// 建立或更新紀錄
  int saveRecord(DivinationRecord record) {
    return _box.put(record);
  }

  /// 讀取單筆紀錄
  DivinationRecord? getRecord(int id) {
    return _box.get(id);
  }

  /// 讀取所有紀錄 (依照建立時間倒序)
  List<DivinationRecord> getAllRecords() {
    final query = _box
        .query()
        .order(DivinationRecord_.createdAt, flags: Order.descending)
        .build();
    final results = query.find();
    query.close();
    return results;
  }

  /// 刪除單筆紀錄
  bool deleteRecord(int id) {
    return _box.remove(id);
  }
}
