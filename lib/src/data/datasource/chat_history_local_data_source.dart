import 'dart:convert';

import 'package:bloc_clean_architecture/src/domain/entities/chat_session.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Lưu/đọc danh sách session trò chuyện trong SharedPreferences.
abstract class ChatHistoryLocalDataSource {
  Future<List<ChatSession>> loadSessions();
  Future<void> saveSession(ChatSession session);
  Future<void> deleteSession(String id);
  Future<void> clearAll();
}

class ChatHistoryLocalDataSourceImpl implements ChatHistoryLocalDataSource {
  static const _kKey = 'chat_sessions_v1';
  static const _kMaxSessions = 50; // giới hạn để không phình SharedPreferences

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  @override
  Future<List<ChatSession>> loadSessions() async {
    try {
      final prefs = await _prefs;
      final raw = prefs.getString(_kKey);
      if (raw == null || raw.isEmpty) return [];
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(ChatSession.fromJson)
          .toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    } catch (_) {
      // Nếu data bị corrupt, trả mảng rỗng (không crash app).
      return [];
    }
  }

  @override
  Future<void> saveSession(ChatSession session) async {
    final prefs = await _prefs;
    final list = await loadSessions();

    // Update nếu trùng id, ngược lại thêm mới.
    final idx = list.indexWhere((s) => s.id == session.id);
    if (idx >= 0) {
      list[idx] = session;
    } else {
      list.insert(0, session);
    }

    // Cắt bớt nếu quá nhiều.
    if (list.length > _kMaxSessions) {
      list.removeRange(_kMaxSessions, list.length);
    }

    final encoded =
        jsonEncode(list.map((s) => s.toJson()).toList(growable: false));
    await prefs.setString(_kKey, encoded);
  }

  @override
  Future<void> deleteSession(String id) async {
    final prefs = await _prefs;
    final list = await loadSessions();
    list.removeWhere((s) => s.id == id);
    final encoded =
        jsonEncode(list.map((s) => s.toJson()).toList(growable: false));
    await prefs.setString(_kKey, encoded);
  }

  @override
  Future<void> clearAll() async {
    final prefs = await _prefs;
    await prefs.remove(_kKey);
  }
}
