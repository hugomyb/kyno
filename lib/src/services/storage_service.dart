import 'package:hive_flutter/hive_flutter.dart';

class StorageService {
  StorageService(this._box);

  static const String boxName = 'kyno_box';
  static const String authTokenKey = 'auth_token_v1';

  final Box<String> _box;

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
  }

  Future<void> clearAuthToken() async {
    await _box.delete(authTokenKey);
  }
}
