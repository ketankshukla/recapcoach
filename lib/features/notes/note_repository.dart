import 'dart:io';

import 'package:hive_flutter/hive_flutter.dart';

import 'note.dart';

/// Hive-backed CRUD for [Note]s. Notes are JSON-encoded into a `Box<String>`
/// keyed by [Note.id].
class NoteRepository {
  NoteRepository(this._box);

  final Box<String> _box;

  static const String boxName = 'notes_v1';

  /// Open the underlying Hive box. Call after `Hive.initFlutter()`.
  static Future<NoteRepository> open() async {
    final box = await Hive.openBox<String>(boxName);
    return NoteRepository(box);
  }

  /// All notes, newest first.
  List<Note> all() {
    final notes = _box.values.map(Note.fromJsonString).toList();
    notes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return notes;
  }

  Note? byId(String id) {
    final s = _box.get(id);
    return s == null ? null : Note.fromJsonString(s);
  }

  Future<void> upsert(Note n) async {
    await _box.put(n.id, n.toJsonString());
  }

  /// Delete the note record AND its underlying audio file (best effort).
  Future<void> delete(String id) async {
    final n = byId(id);
    if (n != null) {
      try {
        final f = File(n.audioFilePath);
        if (f.existsSync()) await f.delete();
      } catch (_) {
        // best-effort; persist deletion of metadata regardless
      }
    }
    await _box.delete(id);
  }

  /// Stream of notes that emits a fresh sorted list whenever the box changes.
  Stream<List<Note>> watchAll() async* {
    yield all();
    yield* _box.watch().map((_) => all());
  }
}
