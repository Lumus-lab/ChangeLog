import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/hexagram_repository.dart';
import '../models/hexagram.dart';

final hexagramRepositoryProvider = Provider<HexagramRepository>((ref) {
  return HexagramRepository();
});

final hexagramsProvider = FutureProvider<List<Hexagram>>((ref) async {
  final repo = ref.watch(hexagramRepositoryProvider);
  await repo.loadHexagrams();
  return repo.getAll();
});
