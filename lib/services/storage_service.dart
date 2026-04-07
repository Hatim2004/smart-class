import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transcript.dart';

class StorageService {
  static const _key = 'transcripts';

  Future<List<Transcript>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    return raw.map((e) => Transcript.fromJson(jsonDecode(e))).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> save(Transcript t) async {
    final prefs = await SharedPreferences.getInstance();
    final all = await loadAll();
    final idx = all.indexWhere((e) => e.id == t.id);
    if (idx >= 0) {
      all[idx] = t;
    } else {
      all.insert(0, t);
    }
    await prefs.setStringList(_key, all.map((e) => jsonEncode(e.toJson())).toList());
  }

  Future<void> delete(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final all = await loadAll();
    all.removeWhere((e) => e.id == id);
    await prefs.setStringList(_key, all.map((e) => jsonEncode(e.toJson())).toList());
  }
}
