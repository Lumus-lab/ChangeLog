import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/storage_service.dart';

final aiCreditsProvider = NotifierProvider<AICreditsNotifier, int>(
  AICreditsNotifier.new,
);

class AICreditsNotifier extends Notifier<int> {
  @override
  int build() {
    final storage = ref.watch(storageServiceProvider);
    return storage.adCredits;
  }

  Future<void> addCredits(int amount) async {
    final storage = ref.read(storageServiceProvider);
    await storage.addAdCredits(amount);
    state = storage.adCredits;
  }

  Future<void> useCredit() async {
    final storage = ref.read(storageServiceProvider);
    await storage.deductAdCredit();
    state = storage.adCredits;
  }

  void refresh() {
    state = ref.read(storageServiceProvider).adCredits;
  }
}
