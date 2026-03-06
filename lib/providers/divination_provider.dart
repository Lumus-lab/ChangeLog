import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/divination_service.dart';
import '../services/zhuxi_interpreter_service.dart';

final divinationServiceProvider = Provider<DivinationService>((ref) {
  return DivinationService();
});

final zhuxiInterpreterProvider = Provider<ZhuxiInterpreterService>((ref) {
  return ZhuxiInterpreterService();
});
