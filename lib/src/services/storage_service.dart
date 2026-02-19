import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../models/app_state.dart';

class StorageService {
  StorageService(this._box);

  static const String boxName = 'kyno_box';
  static const String appStateKey = 'app_state_v1';

  final Box<String> _box;

  static Future<StorageService> init() async {
    await Hive.initFlutter();
    final box = await Hive.openBox<String>(boxName);
    return StorageService(box);
  }

  AppState loadState() {
    final raw = _box.get(appStateKey);
    if (raw == null || raw.isEmpty) {
      return AppState.empty();
    }
    try {
      final jsonMap = jsonDecode(raw) as Map<String, dynamic>;
      return AppState.fromJson(jsonMap);
    } catch (_) {
      return AppState.empty();
    }
  }

  Future<void> saveState(AppState state) async {
    final raw = jsonEncode(state.toJson());
    await _box.put(appStateKey, raw);
  }

  Future<void> overwriteStateFromJson(String jsonString) async {
    final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
    final state = AppState.fromJson(jsonMap);
    await saveState(state);
  }
}
