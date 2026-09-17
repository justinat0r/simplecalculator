import 'package:flutter_test/flutter_test.dart';
import 'package:simplecalculator/calculator_engine.dart';

void main() {
  late CalculatorEngine engine;

  setUp(() => engine = CalculatorEngine());

  /// Types a sequence such as `12+3=` into the engine.
  void type(String keys) {
    for (final key in keys.split('')) {
      switch (key) {
        case '+':
          engine.setOperation(CalcOp.add);
        case '-':
          engine.setOperation(CalcOp.subtract);
        case '*':
          engine.setOperation(CalcOp.multiply);
        case '/':
          engine.setOperation(CalcOp.divide);
        case '=':
          engine.equals();
        case '.':
          engine.inputDecimalPoint();
        default:
          engine.inputDigit(key);
      }
    }
  }

  group('entry', () {
    test('starts at zero', () {
      expect(engine.display, '0');
    });

    test('replaces the leading zero', () {
      type('05');
      expect(engine.display, '5');
    });

    test('accepts a single decimal point', () {
      type('1.2.5');
      expect(engine.display, '1.25');
    });

    test('a bare decimal point starts "0."', () {
      type('.5');
      expect(engine.display, '0.5');
    });

    test('caps the number of digits', () {
      type('1234567890123456');
      expect(engine.display, '123456789012');
    });

    test('backspace removes the last character', () {
      type('123');
      engine.backspace();
      expect(engine.display, '12');
      engine.backspace();
      engine.backspace();
      expect(engine.display, '0');
    });
  });

  group('arithmetic', () {
    test('adds', () {
      type('12+30=');
      expect(engine.display, '42');
    });

    test('subtracts into negatives', () {
      type('3-10=');
      expect(engine.display, '-7');
    });

    test('multiplies', () {
      type('6*7=');
      expect(engine.display, '42');
    });

    test('divides', () {
      type('7/2=');
      expect(engine.display, '3.5');
    });

    test('chains left to right without precedence', () {
      type('2+3*4=');
      expect(engine.display, '20');
    });

    test('shows the running total as a chain is typed', () {
      type('2+3+');
      expect(engine.display, '5');
      type('4=');
      expect(engine.display, '9');
    });

    test('repeats the last operation on further equals presses', () {
      type('5+3=');
      expect(engine.display, '8');
      engine.equals();
      expect(engine.display, '11');
      engine.equals();
      expect(engine.display, '14');
    });

    test('replacing an operator keeps the left operand', () {
      type('8+');
      engine.setOperation(CalcOp.multiply);
      type('2=');
      expect(engine.display, '16');
    });

    test('hides float noise', () {
      type('0.1+0.2=');
      expect(engine.display, '0.3');
    });

    test('exposes the pending operation as an expression', () {
      type('12+');
      expect(engine.expression, '12 +');
      expect(engine.pendingOp, CalcOp.add);
    });
  });

  group('errors', () {
    test('dividing by zero errors and ignores further input', () {
      type('5/0=');
      expect(engine.hasError, isTrue);
      expect(engine.display, 'Error');
      type('7');
      expect(engine.display, 'Error');
    });

    test('AC recovers from an error', () {
      type('5/0=');
      engine.clearAll();
      expect(engine.hasError, isFalse);
      expect(engine.display, '0');
    });

    test('the square root of a negative errors', () {
      type('9');
      engine.toggleSign();
      engine.squareRoot();
      expect(engine.display, 'Error');
    });
  });

  group('functions', () {
    test('toggles the sign', () {
      type('5');
      engine.toggleSign();
      expect(engine.display, '-5');
      engine.toggleSign();
      expect(engine.display, '5');
    });

    test('percent of a pending addition is relative to the accumulator', () {
      type('200+10');
      engine.percent();
      expect(engine.display, '20');
      engine.equals();
      expect(engine.display, '220');
    });

    test('a bare percent divides by 100', () {
      type('50');
      engine.percent();
      expect(engine.display, '0.5');
    });

    test('takes square roots', () {
      type('81');
      engine.squareRoot();
      expect(engine.display, '9');
    });

    test('clearEntry keeps the pending operation', () {
      type('9+5');
      engine.clearEntry();
      expect(engine.display, '0');
      type('1=');
      expect(engine.display, '10');
    });

    test('clearAll resets everything', () {
      type('9+5');
      engine.clearAll();
      expect(engine.display, '0');
      expect(engine.expression, isEmpty);
    });
  });

  group('memory', () {
    test('adds, recalls, subtracts and clears', () {
      type('7');
      engine.memoryAdd();
      expect(engine.hasMemory, isTrue);

      type('2');
      engine.memoryAdd();
      engine.memoryRecall();
      expect(engine.display, '9');

      type('4');
      engine.memorySubtract();
      engine.memoryRecall();
      expect(engine.display, '5');

      engine.memoryClear();
      expect(engine.hasMemory, isFalse);
      engine.memoryRecall();
      expect(engine.display, '0');
    });

    test('a recalled value can be used as an operand', () {
      type('6');
      engine.memoryAdd();
      type('4+');
      engine.memoryRecall();
      engine.equals();
      expect(engine.display, '10');
    });
  });

  group('formatting', () {
    test('drops trailing zeros', () {
      expect(CalculatorEngine.formatValue(3.5000), '3.5');
      expect(CalculatorEngine.formatValue(42), '42');
    });

    test('never shows negative zero', () {
      expect(CalculatorEngine.formatValue(-0.0), '0');
    });

    test('falls back to scientific notation for extreme values', () {
      expect(CalculatorEngine.formatValue(1e20), contains('e+'));
      expect(CalculatorEngine.formatValue(1e-12), contains('e-'));
    });
  });
}
