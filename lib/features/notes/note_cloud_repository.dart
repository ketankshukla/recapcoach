import 'package:cloud_firestore/cloud_firestore.dart';

import 'note.dart';

/// Cloud (Firestore) backing store for [Note]s, scoped per Firebase user.
///
/// Document path: `users/{uid}/notes/{noteId}`. Only the owning user can
/// read or write — see `firestore.rules`.
class NoteCloudRepository {
  NoteCloudRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _notesOf(String uid) =>
      _db.collection('users').doc(uid).collection('notes');

  Future<void> upsert(String uid, Note note) async {
    final data = <String, dynamic>{
      ...note.toMap(),
      // Server-side timestamp lets us reason about conflicts later.
      'updatedAt': FieldValue.serverTimestamp(),
    };
    await _notesOf(uid).doc(note.id).set(data, SetOptions(merge: true));
  }

  Future<void> delete(String uid, String noteId) async {
    await _notesOf(uid).doc(noteId).delete();
  }

  /// One-shot fetch of every cloud note for [uid]. Used during sign-in sync.
  Future<List<Note>> all(String uid) async {
    final snap = await _notesOf(uid).get();
    return snap.docs
        .map((d) => Note.fromMap(_sanitize(d.data())))
        .toList(growable: false);
  }

  /// Live stream of every cloud note for [uid]. (Not currently subscribed —
  /// kept here so future cross-device live-sync is one wire-up away.)
  Stream<List<Note>> watchAll(String uid) {
    return _notesOf(uid).snapshots().map(
          (snap) => snap.docs
              .map((d) => Note.fromMap(_sanitize(d.data())))
              .toList(growable: false),
        );
  }

  /// Firestore returns `Timestamp` for date fields and `int` for some numerics
  /// in different shapes than [Note.fromMap] expects. Normalize to the JSON-y
  /// shape that [Note.fromMap] consumes.
  Map<String, dynamic> _sanitize(Map<String, dynamic> raw) {
    final out = Map<String, dynamic>.from(raw);
    final ca = out['createdAt'];
    if (ca is Timestamp) {
      out['createdAt'] = ca.toDate().toIso8601String();
    }
    out.remove('updatedAt'); // server-only, not part of Note
    return out;
  }
}
