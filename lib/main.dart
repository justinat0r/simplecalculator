import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'calculator_engine.dart';

void main() {
  runApp(const CalculatorApp());
}

class CalculatorApp extends StatelessWidget {
  const CalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Simple Calculator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
      ),
      home: const CalculatorPage(),
    );
  }
}

class CalculatorPage extends StatefulWidget {
  const CalculatorPage({super.key});

  @override
  State<CalculatorPage> createState() => _CalculatorPageState();
}

class _CalculatorPageState extends State<CalculatorPage> {
  final CalculatorEngine _engine = CalculatorEngine();

  /// Runs [action] on the engine and repaints with the new state.
  void _run(VoidCallback action) => setState(action);

  /// Lets a physical keyboard drive the calculator, which matters on desktop
  /// and the web.
  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.backspace) {
      _run(_engine.backspace);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.escape) {
      _run(_engine.clearAll);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.delete) {
      _run(_engine.clearEntry);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      _run(_engine.equals);
      return KeyEventResult.handled;
    }

    final character = event.character;
    switch (character) {
      case '0' || '1' || '2' || '3' || '4' || '5' || '6' || '7' || '8' || '9':
        _run(() => _engine.inputDigit(character!));
      case '.' || ',':
        _run(_engine.inputDecimalPoint);
      case '+':
        _run(() => _engine.setOperation(CalcOp.add));
      case '-':
        _run(() => _engine.setOperation(CalcOp.subtract));
      case '*' || 'x' || 'X':
        _run(() => _engine.setOperation(CalcOp.multiply));
      case '/':
        _run(() => _engine.setOperation(CalcOp.divide));
      case '=':
        _run(_engine.equals);
      case '%':
        _run(_engine.percent);
      default:
        return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Focus(
          autofocus: true,
          onKeyEvent: _handleKey,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480, maxHeight: 900),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    _Display(
                      engine: _engine,
                      onBackspace: () => _run(_engine.backspace),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: _Keypad(engine: _engine, onPressed: _run),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The readout: memory flag, pending expression, current value and backspace.
class _Display extends StatelessWidget {
  const _Display({required this.engine, required this.onBackspace});

  final CalculatorEngine engine;
  final VoidCallback onBackspace;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            children: [
              if (engine.hasMemory)
                Text(
                  'M',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              Expanded(
                child: Text(
                  engine.expression,
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
              IconButton(
                onPressed: onBackspace,
                icon: const Icon(Icons.backspace_outlined),
                tooltip: 'Backspace',
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              engine.display,
              maxLines: 1,
              style: theme.textTheme.displayMedium?.copyWith(
                fontWeight: FontWeight.w300,
                color: engine.hasError ? colors.error : colors.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// How a key is coloured, which also groups it by purpose.
enum _KeyKind { digit, function, operator, equals }

class _Key {
  const _Key(
    this.label,
    this.kind,
    this.onTap, {
    this.semanticLabel,
    this.isActive = false,
  });

  final String label;
  final _KeyKind kind;
  final VoidCallback onTap;
  final String? semanticLabel;

  /// True for the operation that is currently pending, so its key stays lit.
  final bool isActive;
}

class _Keypad extends StatelessWidget {
  const _Keypad({required this.engine, required this.onPressed});

  final CalculatorEngine engine;
  final void Function(VoidCallback) onPressed;

  _Key _op(CalcOp op) => _Key(
    op.symbol,
    _KeyKind.operator,
    () => engine.setOperation(op),
    semanticLabel: op.name,
    isActive: engine.pendingOp == op,
  );

  @override
  Widget build(BuildContext context) {
    final rows = <List<_Key>>[
      [
        _Key(
          'MC',
          _KeyKind.function,
          engine.memoryClear,
          semanticLabel: 'Memory clear',
        ),
        _Key(
          'MR',
          _KeyKind.function,
          engine.memoryRecall,
          semanticLabel: 'Memory recall',
        ),
        _Key(
          'M+',
          _KeyKind.function,
          engine.memoryAdd,
          semanticLabel: 'Memory add',
        ),
        _Key(
          'M−',
          _KeyKind.function,
          engine.memorySubtract,
          semanticLabel: 'Memory subtract',
        ),
      ],
      [
        _Key(
          'AC',
          _KeyKind.function,
          engine.clearAll,
          semanticLabel: 'All clear',
        ),
        _Key(
          '±',
          _KeyKind.function,
          engine.toggleSign,
          semanticLabel: 'Toggle sign',
        ),
        _Key('%', _KeyKind.function, engine.percent, semanticLabel: 'Percent'),
        _op(CalcOp.divide),
      ],
      [
        _Key('7', _KeyKind.digit, () => engine.inputDigit('7')),
        _Key('8', _KeyKind.digit, () => engine.inputDigit('8')),
        _Key('9', _KeyKind.digit, () => engine.inputDigit('9')),
        _op(CalcOp.multiply),
      ],
      [
        _Key('4', _KeyKind.digit, () => engine.inputDigit('4')),
        _Key('5', _KeyKind.digit, () => engine.inputDigit('5')),
        _Key('6', _KeyKind.digit, () => engine.inputDigit('6')),
        _op(CalcOp.subtract),
      ],
      [
        _Key('1', _KeyKind.digit, () => engine.inputDigit('1')),
        _Key('2', _KeyKind.digit, () => engine.inputDigit('2')),
        _Key('3', _KeyKind.digit, () => engine.inputDigit('3')),
        _op(CalcOp.add),
      ],
      [
        _Key(
          '√',
          _KeyKind.function,
          engine.squareRoot,
          semanticLabel: 'Square root',
        ),
        _Key('0', _KeyKind.digit, () => engine.inputDigit('0')),
        _Key(
          '.',
          _KeyKind.digit,
          engine.inputDecimalPoint,
          semanticLabel: 'Decimal point',
        ),
        _Key('=', _KeyKind.equals, engine.equals, semanticLabel: 'Equals'),
      ],
    ];

    return Column(
      children: [
        for (final row in rows)
          Expanded(
            child: Row(
              children: [
                for (final key in row)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: _CalculatorButton(data: key, onPressed: onPressed),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _CalculatorButton extends StatelessWidget {
  const _CalculatorButton({required this.data, required this.onPressed});

  final _Key data;
  final void Function(VoidCallback) onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final (Color background, Color foreground) = switch (data.kind) {
      _KeyKind.digit => (colors.surfaceContainerHigh, colors.onSurface),
      _KeyKind.function => (
        colors.secondaryContainer,
        colors.onSecondaryContainer,
      ),
      _KeyKind.operator =>
        data.isActive
            ? (colors.onPrimaryContainer, colors.primaryContainer)
            : (colors.primaryContainer, colors.onPrimaryContainer),
      _KeyKind.equals => (colors.primary, colors.onPrimary),
    };

    return Semantics(
      button: true,
      label: data.semanticLabel,
      child: FilledButton(
        onPressed: () => onPressed(data.onTap),
        style: FilledButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              data.label,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ),
    );
  }
}
