import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  // --- Ad Credits (Free AI usage) ---
  int get adCredits {
    // Default starting credits, e.g., 3 free trials.
    return _prefs.getInt(_kAdCredits) ?? 3;
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
