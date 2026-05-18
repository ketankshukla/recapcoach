import 'dart:io';

import 'package:hive_flutter/hive_flutter.dart';

import '../../core/logging/logger.dart';
import 'note.dart';
import 'note_cloud_repository.dart';

/// Hive-backed CRUD for [Note]s, with optional best-effort write-through to
/// Firestore via [NoteCloudRepository]. Notes are JSON-encoded into a
/// `Box<String>` keyed by [Note.id].
class NoteRepository {
  NoteRepository(
    this._box, {
    NoteCloudRepository? cloud,
    String? Function()? uidGetter,
  })  : _cloud = cloud,
        _uidGetter = uidGetter;

  final Box<String> _box;
  final NoteCloudRepository? _cloud;
  final String? Function()? _uidGetter;

  static const String boxName = 'notes_v1';

  /// Open the underlying Hive box. Call after `Hive.initFlutter()`.
  static Future<NoteRepository> open({
    NoteCloudRepository? cloud,
    String? Function()? uidGetter,
  }) async {
    final box = await Hive.openBox<String>(boxName);
    return NoteRepository(box, cloud: cloud, uidGetter: uidGetter);
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

  /// Persist [n] locally, then mirror to the cloud (best-effort).
  Future<void> upsert(Note n) async {
    await _box.put(n.id, n.toJsonString());
    final cloud = _cloud;
    final uid = _uidGetter?.call();
    if (cloud != null && uid != null) {
      try {
        await cloud.upsert(uid, n);
      } catch (e) {
        logger.warning('Cloud upsert failed for note ${n.id}: $e');
      }
    }
  }

  /// Internal: write only to Hive. Used by the sync service when pulling
  /// notes down from the cloud, to avoid recursive cloud writes.
  Future<void> upsertLocalOnly(Note n) async {
    await _box.put(n.id, n.toJsonString());
  }

  /// Delete the note record AND its underlying audio file (best effort).
  /// Also removes from the cloud (best-effort).
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
    final cloud = _cloud;
    final uid = _uidGetter?.call();
    if (cloud != null && uid != null) {
      try {
        await cloud.delete(uid, id);
      } catch (e) {
        logger.warning('Cloud delete failed for note $id: $e');
      }
    }
  }

  /// Wipe ALL locally-cached notes (Hive only; cloud is untouched). Used by
  /// the sync service when a different user signs in on this device.
  Future<void> clearAllLocalOnly() async {
    await _box.clear();
  }

  /// Stream of notes that emits a fresh sorted list whenever the box changes.
  Stream<List<Note>> watchAll() async* {
    yield all();
    yield* _box.watch().map((_) => all());
  }
}
