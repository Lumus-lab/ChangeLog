import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/divination_record.dart';
import '../repositories/record_repository.dart';
import '../providers/database_provider.dart';

final recordsProvider =
    NotifierProvider<RecordsNotifier, List<DivinationRecord>>(
      RecordsNotifier.new,
    );

class RecordsNotifier extends Notifier<List<DivinationRecord>> {
  late final RecordRepository _repo;

  @override
  List<DivinationRecord> build() {
    _repo = ref.watch(recordRepositoryProvider);
    return _repo.getAllRecords();
  }

  void loadRecords() {
    state = _repo.getAllRecords();
  }

  void addRecord(DivinationRecord record) {
    _repo.saveRecord(record);
    loadRecords();
  }

  void updateRecord(DivinationRecord record) {
    _repo.saveRecord(record);
    loadRecords();
  }

  void deleteRecord(int id) {
    _repo.deleteRecord(id);
    loadRecords();
  }
}
