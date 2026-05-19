// Widget tests for `NoteCard`. Verifies the card renders the right
// status chip, summary preview, and fires its onTap callback.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recapcoach/core/theme/app_theme.dart';
import 'package:recapcoach/features/home/widgets/note_card.dart';
import 'package:recapcoach/features/notes/note.dart';

Note _note({
  String? title,
  String? summary,
  bool isProcessing = false,
  String? processingError,
}) {
  return Note(
    id: 'n1',
    audioFilePath: '/tmp/x.aac',
    createdAt: DateTime.utc(2026, 5, 18, 12),
    durationMs: 134000, // 2:14
    title: title,
    summary: summary,
    isProcessing: isProcessing,
    processingError: processingError,
  );
}

Future<void> _pump(WidgetTester tester, NoteCard card) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(body: card),
    ),
  );
}

void main() {
  group('NoteCard', () {
    testWidgets('Renders title, duration label, and summary for done note',
        (tester) async {
      var tapped = 0;
      await _pump(
        tester,
        NoteCard(
          note: _note(title: 'Q3 launch sync', summary: 'Discussed timing.'),
          onTap: () => tapped++,
        ),
      );

      expect(find.text('Q3 launch sync'), findsOneWidget);
      expect(find.text('2:14'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);
      expect(find.text('Discussed timing.'), findsOneWidget);
      expect(tapped, 0);
    });

    testWidgets('Tap fires the onTap callback', (tester) async {
      var tapped = 0;
      await _pump(
        tester,
        NoteCard(
          note: _note(summary: 'x'),
          onTap: () => tapped++,
        ),
      );
      await tester.tap(find.byType(NoteCard));
      await tester.pump();
      expect(tapped, 1);
    });

    testWidgets('Shows "Transcribing" body when note is processing',
        (tester) async {
      await _pump(
        tester,
        NoteCard(note: _note(isProcessing: true), onTap: () {}),
      );
      expect(find.text('Transcribing'), findsOneWidget);
      expect(find.text('Transcribing your recording…'), findsOneWidget);
    });

    testWidgets('Shows the error text when transcription failed',
        (tester) async {
      await _pump(
        tester,
        NoteCard(
          note: _note(processingError: 'Server timed out after 30s'),
          onTap: () {},
        ),
      );
      expect(find.text('Failed'), findsOneWidget);
      expect(find.text('Server timed out after 30s'), findsOneWidget);
    });

    testWidgets('Pending note shows the waiting copy', (tester) async {
      await _pump(tester, NoteCard(note: _note(), onTap: () {}));
      expect(find.text('Pending'), findsOneWidget);
      expect(find.text('Recorded. Waiting on transcription.'), findsOneWidget);
    });
  });
}
