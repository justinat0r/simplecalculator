// Widget tests for the calculator UI. The arithmetic itself is covered by
// calculator_engine_test.dart; these tests check that the keys are wired up.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:simplecalculator/main.dart';

void main() {
  /// Taps the keys named in [labels], in order.
  Future<void> tapKeys(WidgetTester tester, List<String> labels) async {
    for (final label in labels) {
      await tester.tap(find.widgetWithText(FilledButton, label));
      await tester.pump();
    }
  }

  testWidgets('shows a full keypad starting at zero', (tester) async {
    await tester.pumpWidget(const CalculatorApp());

    for (final label in ['0', '5', '9', '+', '−', '×', '÷', '=', 'AC', '%']) {
      expect(
        find.widgetWithText(FilledButton, label),
        findsOneWidget,
        reason: 'missing the "$label" key',
      );
    }
    expect(find.text('0'), findsNWidgets(2)); // the display and the 0 key
  });

  testWidgets('tapping digits and an operator computes a result', (
    tester,
  ) async {
    await tester.pumpWidget(const CalculatorApp());

    await tapKeys(tester, ['1', '2', '+', '3', '0', '=']);

    expect(find.text('42'), findsOneWidget);
  });

  testWidgets('AC clears the display', (tester) async {
    await tester.pumpWidget(const CalculatorApp());

    await tapKeys(tester, ['9', '9', 'AC']);

    expect(find.text('99'), findsNothing);
    expect(find.text('0'), findsNWidgets(2));
  });

  testWidgets('the backspace button deletes the last digit', (tester) async {
    await tester.pumpWidget(const CalculatorApp());

    await tapKeys(tester, ['1', '2', '3']);
    await tester.tap(find.byIcon(Icons.backspace_outlined));
    await tester.pump();

    expect(find.text('12'), findsOneWidget);
  });
}
