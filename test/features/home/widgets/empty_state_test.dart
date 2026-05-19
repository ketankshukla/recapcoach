// Widget test for `HomeEmptyState`. Verifies the headline + helper copy
// + the directional hint chip are all on screen.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recapcoach/core/theme/app_theme.dart';
import 'package:recapcoach/features/home/widgets/empty_state.dart';

void main() {
  group('HomeEmptyState', () {
    testWidgets('Renders headline, helper copy, and start-recording hint',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(body: HomeEmptyState()),
        ),
      );

      expect(find.text('Capture your first call'), findsOneWidget);
      expect(
        find.textContaining('transcript, summary, and action items'),
        findsOneWidget,
      );
      expect(find.text('Start recording'), findsOneWidget);
      expect(find.byIcon(Icons.mic_rounded), findsOneWidget);
      expect(find.byIcon(Icons.arrow_downward_rounded), findsOneWidget);
    });

    testWidgets('Renders correctly under the dark theme too', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: const Scaffold(body: HomeEmptyState()),
        ),
      );
      expect(find.text('Capture your first call'), findsOneWidget);
    });
  });
}
