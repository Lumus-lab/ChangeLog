import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/ai_config.dart';

final storageServiceProvider = Provider<StorageService>((ref) {
  throw UnimplementedError('storageServiceProvider must be overridden in main');
});

class StorageService {
  final SharedPreferences _prefs;
  final FlutterSecureStorage _secure;

  StorageService(this._prefs, this._secure);

  // --- Keys ---
  static const _kFirstLaunch = 'is_first_launch';
  static const _kAdCredits = 'ad_credits';
  static const _kByokApiKey = 'byok_gemini_api_key';
  static const _kLastResetDate = 'last_reset_date';

  // --- Initialization Helper ---
  static Future<StorageService> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    const secure = FlutterSecureStorage();
    return StorageService(prefs, secure);
  }

  // --- First Time Launch ---
  bool get isFirstLaunch {
    return _prefs.getBool(_kFirstLaunch) ?? true;
  }

  Future<void> setFirstLaunchCompleted() async {
    await _prefs.setBool(_kFirstLaunch, false);
  }

  // --- Ad Credits (AI interpretation usage) ---
  int get adCredits {
    _checkInitialCredits();
    return _prefs.getInt(_kAdCredits) ?? 3;
  }

  void _checkInitialCredits() {
    final lastResetStr = _prefs.getString(_kLastResetDate);
    final now = DateTime.now();
    final todayStr = "${now.year}-${now.month}-${now.day}";

    if (lastResetStr != todayStr) {
      final current = _prefs.getInt(_kAdCredits) ?? 0;
      if (current < AIConfig.dailyFreeCredits) {
        _prefs.setInt(_kAdCredits, AIConfig.dailyFreeCredits);
      }
      _prefs.setString(_kLastResetDate, todayStr);
    }
  }

  Future<void> addAdCredits(int amount) async {
    final current = adCredits;
    await _prefs.setInt(_kAdCredits, current + amount);
  }

  Future<void> deductAdCredit() async {
    final current = adCredits;
    if (current > 0) {
      await _prefs.setInt(_kAdCredits, current - 1);
    }
  }

  // --- BYOK API Key (Secure Storage) ---
  Future<void> setByokApiKey(String key) async {
    await _secure.write(key: _kByokApiKey, value: key);
  }

  Future<String?> getByokApiKey() async {
    return await _secure.read(key: _kByokApiKey);
  }

  Future<void> deleteByokApiKey() async {
    await _secure.delete(key: _kByokApiKey);
  }
}
