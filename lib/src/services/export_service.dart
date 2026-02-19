import 'dart:convert';

import '../models/app_state.dart';

class ExportService {
  String exportToJson(AppState state) {
    return const JsonEncoder.withIndent('  ').convert(state.toJson());
  }

  AppState importFromJson(String jsonString) {
    final map = jsonDecode(jsonString) as Map<String, dynamic>;
    return AppState.fromJson(map);
  }

  AppState mergeState({
    required AppState current,
    required AppState incoming,
  }) {
    return current.copyWith(
      profile: incoming.profile.name.isNotEmpty ? incoming.profile : current.profile,
      equipment: incoming.equipment.isNotEmpty ? incoming.equipment : current.equipment,
      program: incoming.program.sessions.isNotEmpty ? incoming.program : current.program,
      sessions: [
        ...current.sessions,
        ...incoming.sessions.where(
          (incomingSession) =>
              !current.sessions.any((s) => s.id == incomingSession.id),
        ),
      ],
      lastOpenIso: current.lastOpenIso,
    );
  }
}
