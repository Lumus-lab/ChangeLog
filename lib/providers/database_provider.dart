import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/objectbox_service.dart';
import '../repositories/record_repository.dart';

final objectBoxProvider = Provider<ObjectBoxService>((ref) {
  throw UnimplementedError('objectBoxProvider is not initialized');
});

final recordRepositoryProvider = Provider<RecordRepository>((ref) {
  final objectBox = ref.watch(objectBoxProvider);
  return RecordRepository(objectBox);
});
