// Widget tests for `NoteStatusChip`. Verifies each status renders the
// expected label so the user can read the chip without color cues.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recapcoach/core/theme/app_theme.dart';
import 'package:recapcoach/features/home/widgets/note_status.dart';
import 'package:recapcoach/features/home/widgets/note_status_chip.dart';

Future<void> _pump(WidgetTester tester, NoteStatus status) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(body: Center(child: NoteStatusChip(status: status))),
    ),
  );
}

void main() {
  group('NoteStatusChip', () {
    testWidgets('Renders "Transcribing" for processing', (tester) async {
      await _pump(tester, NoteStatus.processing);
      expect(find.text('Transcribing'), findsOneWidget);
      expect(find.byIcon(Icons.hourglass_top_rounded), findsOneWidget);
    });

    testWidgets('Renders "Done" for done', (tester) async {
      await _pump(tester, NoteStatus.done);
      expect(find.text('Done'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    });

    testWidgets('Renders "Failed" for failed', (tester) async {
      await _pump(tester, NoteStatus.failed);
      expect(find.text('Failed'), findsOneWidget);
      expect(find.byIcon(Icons.error_rounded), findsOneWidget);
    });

    testWidgets('Renders "Pending" for pending', (tester) async {
      await _pump(tester, NoteStatus.pending);
      expect(find.text('Pending'), findsOneWidget);
      expect(find.byIcon(Icons.mic_none_rounded), findsOneWidget);
    });
  });
}
