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
  static const _kLastResetDate = 'last_reset_date';
  static const _kInterstitialCounter = 'interstitial_counter';

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
      // It's a new day! Reset to base 3 if current is less than 3,
      // or just add 3 to available?
      // User said "Daily base is 3", implying if they have 0, they get 3.
      // If they have 10 (from ads), should they get 13?
      // Let's assume daily reset means "ensure at least 3".
      final current = _prefs.getInt(_kAdCredits) ?? 0;
      if (current < 3) {
        _prefs.setInt(_kAdCredits, 3);
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

  // --- Interstitial Ad Logic ---
  int get interstitialCounter => _prefs.getInt(_kInterstitialCounter) ?? 0;

  Future<bool> incrementAndCheckInterstitial() async {
    int current = interstitialCounter + 1;
    if (current >= 3) {
      // Trigger every 3 times
      await _prefs.setInt(_kInterstitialCounter, 0);
      return true;
    }
    await _prefs.setInt(_kInterstitialCounter, current);
    return false;
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
