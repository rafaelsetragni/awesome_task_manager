import 'package:example/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Counter flow shows loading states and updates values',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    // Counter starts at zero
    expect(find.text('0'), findsOneWidget);

    Future<void> pumpAndWait() async => tester.pumpAndSettle(
          const Duration(milliseconds: 100),
          EnginePhase.sendSemanticsUpdate,
          const Duration(seconds: 5),
        );

    // Increment to 1
    await tester.tap(find.byTooltip('Increment'));
    await tester.pump();
    expect(
      find.descendant(
        of: find.byTooltip('Increment'),
        matching: find.byType(CircularProgressIndicator),
      ),
      findsOneWidget,
    );
    await pumpAndWait();
    expect(find.text('1'), findsOneWidget);

    // Increment to 2
    await tester.tap(find.byTooltip('Increment'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));
    expect(
      find.descendant(
        of: find.byTooltip('Increment'),
        matching: find.byType(CircularProgressIndicator),
      ),
      findsOneWidget,
    );
    await pumpAndWait();
    expect(find.text('2'), findsOneWidget);

    // Decrement to 1
    await tester.tap(find.byTooltip('Decrement'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));
    expect(
      find.descendant(
        of: find.byTooltip('Decrement'),
        matching: find.byType(CircularProgressIndicator),
      ),
      findsOneWidget,
    );
    await pumpAndWait();
    expect(find.text('1'), findsOneWidget);

    // Reset to 0 with global loading overlay
    await tester.tap(find.byTooltip('Reset'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));
    expect(find.text('Resetting...'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 3100));
    await tester.pump();
    expect(find.text('0'), findsOneWidget);
    expect(find.text('Resetting...'), findsNothing);
  });
}
