import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'note.dart';
import 'note_repository.dart';

/// Overridden in `main.dart` after Hive is initialized.
final noteRepositoryProvider = Provider<NoteRepository>((_) {
  throw UnimplementedError(
    'noteRepositoryProvider must be overridden in ProviderScope after Hive init.',
  );
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
