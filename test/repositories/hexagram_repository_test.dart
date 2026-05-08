import 'package:changelog/repositories/hexagram_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads hexagram assets including tuan commentary', () async {
    final repository = HexagramRepository();

    await repository.loadHexagrams();

    final hexagrams = repository.getAll();
    expect(hexagrams, hasLength(64));
    expect(repository.getById(1)?.tuan, isNotEmpty);
  });
}
