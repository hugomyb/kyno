import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';

class StorageService {
  StorageService(this._box);

  static const String boxName = 'kyno_box';
  static const String authTokenKey = 'auth_token_v1';
  static const String pushOptInKey = 'push_opt_in_v1';
  static const String pushPromptedKey = 'push_prompted_v1';
  static const String pendingWorkoutKey = 'pending_workout_v1';
  static const String appDataCacheKey = 'app_data_cache_v1';

  final Box<String> _box;
  final ValueNotifier<int> _authTokenVersion = ValueNotifier<int>(0);

  ValueListenable<int> get authTokenVersion => _authTokenVersion;

  static Future<StorageService> init() async {
    await Hive.initFlutter();
    final box = await Hive.openBox<String>(boxName);
    return StorageService(box);
  }

  String? loadAuthToken() {
    final token = _box.get(authTokenKey);
    if (token == null || token.isEmpty) {
      return null;
    }
    return token;
  }

  Future<void> saveAuthToken(String token) async {
    await _box.put(authTokenKey, token);
    _authTokenVersion.value++;
  }

  Future<void> clearAuthToken() async {
    await _box.delete(authTokenKey);
    _authTokenVersion.value++;
  }

  String? getString(String key) {
    return _box.get(key);
  }

  Future<void> setString(String key, String value) async {
    await _box.put(key, value);
  }

  Future<void> delete(String key) async {
    await _box.delete(key);
  }

  bool? getBool(String key) {
    final value = _box.get(key);
    if (value == null) return null;
    if (value == 'true') return true;
    if (value == 'false') return false;
    return null;
  }

  Future<void> setBool(String key, bool value) async {
    await _box.put(key, value ? 'true' : 'false');
  }
}
