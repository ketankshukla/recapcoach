import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/logging/logger.dart';
import '../../shared/providers/shared_prefs_provider.dart';
import '../auth/auth_providers.dart';
import 'note.dart';
import 'note_cloud_repository.dart';
import 'note_repository.dart';
import 'note_sync_service.dart';

/// Overridden in `main.dart` after Hive is initialized.
final noteRepositoryProvider = Provider<NoteRepository>((_) {
  throw UnimplementedError(
    'noteRepositoryProvider must be overridden in ProviderScope after Hive init.',
  );
});

final noteCloudRepositoryProvider = Provider<NoteCloudRepository>((_) {
  return NoteCloudRepository();
});

final noteSyncServiceProvider = Provider<NoteSyncService>((ref) {
  return NoteSyncService(
    local: ref.watch(noteRepositoryProvider),
    cloud: ref.watch(noteCloudRepositoryProvider),
    prefs: ref.watch(sharedPrefsProvider),
  );
});

/// Watches Firebase auth state. The first time we see a signed-in user (per
/// session), we trigger a one-shot cloud-to-local sync. The bootstrap is
/// idempotent: it tracks UIDs it has already synced this session.
final noteSyncBootstrapProvider = Provider<void>((ref) {
  final syncedUids = <String>{};
  ref.listen<AsyncValue<User?>>(authStateProvider, (prev, next) {
    final user = next.value;
    if (user == null) return;
    final uid = user.uid;
    if (syncedUids.contains(uid)) return;
    syncedUids.add(uid);
    final svc = ref.read(noteSyncServiceProvider);
    svc.syncForUser(uid).then((pulled) {
      logger.info('Sync bootstrap: pulled $pulled note(s) for uid=$uid');
    }).catchError((Object e, StackTrace st) {
      logger.error('Sync bootstrap failed for uid=$uid', e, st);
    });
  }, fireImmediately: true,);
});

/// Live stream of all notes, newest first.
final notesStreamProvider = StreamProvider<List<Note>>((ref) {
  final repo = ref.watch(noteRepositoryProvider);
  return repo.watchAll();
});

/// Lookup a single note by id. Re-emits whenever the underlying list changes.
final noteByIdProvider = Provider.family<Note?, String>((ref, id) {
  final notes = ref.watch(notesStreamProvider).value ?? const <Note>[];
  for (final n in notes) {
    if (n.id == id) return n;
  }
  return null;
});
