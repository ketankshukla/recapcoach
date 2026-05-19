// Widget tests for `UserAvatar`. Verifies initials selection across
// the (displayName, email) input matrix and that the photo URL branch
// renders without crashing.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recapcoach/core/theme/app_theme.dart';
import 'package:recapcoach/features/home/widgets/user_avatar.dart';

Future<void> _pump(
  WidgetTester tester, {
  String? displayName,
  String? email,
  String? photoUrl,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(
        body: Center(
          child: UserAvatar(
            photoUrl: photoUrl,
            displayName: displayName,
            email: email,
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('UserAvatar -- initials fallback', () {
    testWidgets('Two-word display name -> first + last initials',
        (tester) async {
      await _pump(tester, displayName: 'Ketan Shukla', email: 'k@e.com');
      expect(find.text('KS'), findsOneWidget);
    });

    testWidgets('Single-word display name -> first letter only',
        (tester) async {
      await _pump(tester, displayName: 'Cher', email: 'c@e.com');
      expect(find.text('C'), findsOneWidget);
    });

    testWidgets('Three-word display name -> first + last initials only',
        (tester) async {
      await _pump(
        tester,
        displayName: 'Mary Anne Smith',
        email: 'm@e.com',
      );
      // First word "Mary" -> M; last word "Smith" -> S.
      expect(find.text('MS'), findsOneWidget);
    });

    testWidgets('No display name -> first letter of email', (tester) async {
      await _pump(tester, email: 'jordan@example.com');
      expect(find.text('J'), findsOneWidget);
    });

    testWidgets('No display name and no email -> "?" placeholder',
        (tester) async {
      await _pump(tester);
      expect(find.text('?'), findsOneWidget);
    });

    testWidgets('Whitespace-only display name falls through to email',
        (tester) async {
      await _pump(tester, displayName: '   ', email: 'a@b.com');
      expect(find.text('A'), findsOneWidget);
    });
  });

  group('UserAvatar -- photo URL branch', () {
    testWidgets('Builds with photoUrl set; initials still render as fallback',
        (tester) async {
      // We deliberately do NOT pumpAndSettle here. The widget builds
      // synchronously with the initials as the CircleAvatar's `child`,
      // which is what we're verifying. The asynchronous NetworkImage
      // load in the test environment hits a 400 stub HTTP client and
      // would emit a NetworkImageLoadException; we drain it explicitly
      // below so the (expected) failure doesn't fail the test.
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(
            body: Center(
              child: UserAvatar(
                photoUrl: 'https://example.com/pic.jpg',
                displayName: 'Ketan Shukla',
                email: 'k@e.com',
              ),
            ),
          ),
        ),
      );

      expect(find.byType(UserAvatar), findsOneWidget);
      expect(find.text('KS'), findsOneWidget);

      // Drain the expected async NetworkImage load failure.
      await tester.pump(const Duration(milliseconds: 1));
      while (tester.takeException() != null) {
        // no-op: just consume any pending image-load exceptions.
      }
    });
  });
}
