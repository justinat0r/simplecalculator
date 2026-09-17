import 'dart:math' as math;

/// The four binary operations the calculator supports.
enum CalcOp {
  add('+'),
  subtract('−'),
  multiply('×'),
  divide('÷');

  const CalcOp(this.symbol);

  /// The character shown on the button and in the expression preview.
  final String symbol;
}

/// All calculation state and logic, deliberately free of any UI code so the
/// behaviour can be unit tested on its own.
///
/// The engine follows the semantics of a common pocket calculator: entering a
/// number, an operation and another number and then pressing `=` evaluates
/// left to right, with no operator precedence.
class CalculatorEngine {
  /// Maximum number of digits the user may type into a single entry.
  static const int maxDigits = 12;

  /// The number currently being typed or the last result, as text.
  String _entry = '0';

  /// The left hand side of a pending operation.
  double? _accumulator;

  CalcOp? _pendingOp;

  /// True once the user has typed into [_entry]; false when [_entry] holds a
  /// result, so the next digit starts a fresh number.
  bool _typing = false;

  bool _error = false;

  double _memory = 0;

  /// The last operation and right hand operand, so repeated `=` presses repeat
  /// the operation (5 + 3 = 8, = 11, = 14).
  CalcOp? _repeatOp;
  double? _repeatOperand;

  /// The text to show on the main display line.
  String get display => _error ? 'Error' : _entry;

  /// A hint of the pending calculation, e.g. `12 +`. Empty when idle.
  String get expression {
    if (_error || _pendingOp == null) return '';
    return '${formatValue(_accumulator ?? 0)} ${_pendingOp!.symbol}';
  }

  /// The operation waiting for a right hand operand, if any.
  CalcOp? get pendingOp => _pendingOp;

  bool get hasError => _error;

  bool get hasMemory => _memory != 0;

  /// The value the display currently represents.
  double get value => _error ? 0 : (double.tryParse(_entry) ?? 0);

  void inputDigit(String digit) {
    assert(RegExp(r'^[0-9]$').hasMatch(digit));
    if (_error) return;
    _clearRepeat();
    if (!_typing) {
      _entry = digit;
      _typing = true;
      return;
    }
    if (_entry == '0') {
      _entry = digit;
    } else if (_entry == '-0') {
      _entry = '-$digit';
    } else if (_digitCount(_entry) < maxDigits) {
      _entry += digit;
    }
  }

  void inputDecimalPoint() {
    if (_error) return;
    _clearRepeat();
    if (!_typing) {
      _entry = '0.';
      _typing = true;
    } else if (!_entry.contains('.')) {
      _entry += '.';
    }
  }

  /// Removes the last typed character, like the backspace key.
  void backspace() {
    if (_error) return;
    _clearRepeat();
    var next = _entry.substring(0, _entry.length - 1);
    if (next.isEmpty || next == '-') next = '0';
    _entry = next;
    _typing = true;
  }

  /// Flips the sign of the displayed value.
  void toggleSign() {
    if (_error) return;
    if (_entry.startsWith('-')) {
      _entry = _entry.substring(1);
    } else if (_entry != '0') {
      _entry = '-$_entry';
    }
  }

  /// `%` behaves the way pocket calculators do: with a pending `+` or `-` it
  /// means "that percentage of the accumulator" (200 + 10 % = 220), otherwise
  /// it simply divides by 100.
  void percent() {
    if (_error) return;
    _clearRepeat();
    final current = value;
    final result = (_pendingOp == CalcOp.add || _pendingOp == CalcOp.subtract)
        ? (_accumulator ?? 0) * current / 100
        : current / 100;
    _showResult(result);
  }

  void squareRoot() {
    if (_error) return;
    _clearRepeat();
    final current = value;
    if (current < 0) {
      _fail();
      return;
    }
    _showResult(math.sqrt(current));
  }

  /// Starts (or replaces) a pending operation, evaluating anything already
  /// pending so chains like `2 + 3 + 4` accumulate as you type.
  void setOperation(CalcOp op) {
    if (_error) return;
    _clearRepeat();
    if (_pendingOp != null && _typing) {
      final result = _apply(_accumulator ?? 0, value, _pendingOp!);
      if (result == null) {
        _fail();
        return;
      }
      _accumulator = result;
      _showResult(result);
    } else {
      _accumulator = value;
    }
    _pendingOp = op;
    _typing = false;
  }

  void equals() {
    if (_error) return;

    final CalcOp? op = _pendingOp ?? _repeatOp;
    if (op == null) {
      _typing = false;
      return;
    }

    final double lhs;
    final double rhs;
    if (_pendingOp != null) {
      lhs = _accumulator ?? 0;
      rhs = value;
    } else {
      lhs = value;
      rhs = _repeatOperand!;
    }

    final result = _apply(lhs, rhs, op);
    if (result == null) {
      _fail();
      return;
    }

    _repeatOp = op;
    _repeatOperand = rhs;
    _accumulator = null;
    _pendingOp = null;
    _showResult(result);
  }

  /// Clears the current entry only, keeping any pending operation.
  void clearEntry() {
    if (_error) {
      clearAll();
      return;
    }
    _entry = '0';
    _typing = false;
    _clearRepeat();
  }

  /// Clears everything except memory, like `AC`.
  void clearAll() {
    _entry = '0';
    _accumulator = null;
    _pendingOp = null;
    _typing = false;
    _error = false;
    _clearRepeat();
  }

  void memoryClear() => _memory = 0;

  void memoryRecall() {
    if (_error) return;
    _clearRepeat();
    _showResult(_memory);
  }

  void memoryAdd() {
    if (_error) return;
    _memory += value;
    _typing = false;
  }

  void memorySubtract() {
    if (_error) return;
    _memory -= value;
    _typing = false;
  }

  void _showResult(double result) {
    final text = formatValue(result);
    if (text == 'Error') {
      _fail();
      return;
    }
    _entry = text;
    _typing = false;
  }

  void _fail() {
    _entry = '0';
    _accumulator = null;
    _pendingOp = null;
    _typing = false;
    _error = true;
    _clearRepeat();
  }

  void _clearRepeat() {
    _repeatOp = null;
    _repeatOperand = null;
  }

  /// Returns null when the operation has no finite result.
  static double? _apply(double lhs, double rhs, CalcOp op) {
    final result = switch (op) {
      CalcOp.add => lhs + rhs,
      CalcOp.subtract => lhs - rhs,
      CalcOp.multiply => lhs * rhs,
      CalcOp.divide => rhs == 0 ? double.nan : lhs / rhs,
    };
    return result.isFinite ? result : null;
  }

  static int _digitCount(String text) =>
      text.replaceAll(RegExp(r'[-.]'), '').length;

  /// Renders [value] the way a calculator would: no trailing `.0`, no float
  /// noise such as `0.30000000000000004`, and scientific notation only when
  /// the number does not otherwise fit.
  static String formatValue(double value) {
    if (!value.isFinite) return 'Error';
    if (value == 0) return '0';

    final magnitude = value.abs();
    if (magnitude >= 1e12 || magnitude < 1e-9) {
      final text = value.toStringAsExponential(6);
      final parts = text.split('e');
      final mantissa = _trimTrailingZeros(parts.first);
      return '${mantissa}e${parts.last}';
    }

    final text = _trimTrailingZeros(value.toStringAsFixed(10));
    return text == '-0' ? '0' : text;
  }

  static String _trimTrailingZeros(String text) {
    if (!text.contains('.')) return text;
    return text
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }
}
