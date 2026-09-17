# simplecalculator

A simple calculator built with Flutter, with the keys you would find on a basic
pocket calculator.

## Features

- Digits `0`–`9`, a decimal point and the four operations `+`, `−`, `×`, `÷`
- `=` with repeat: pressing it again repeats the last operation (`5 + 3 =` → 8,
  → 11, → 14)
- `AC` (all clear), backspace, `±` sign toggle, `%` and `√`
- Memory keys `MC`, `MR`, `M+`, `M−`, with an `M` indicator on the display
- A second display line showing the pending calculation, e.g. `12 +`
- Divide-by-zero and root-of-a-negative show `Error` until `AC` is pressed
- Physical keyboard support: digits, `+ - * /`, `Enter`/`=`, `.`, `%`,
  `Backspace`, `Delete` (clear entry) and `Esc` (all clear)

## Layout

| | | | |
|---|---|---|---|
| MC | MR | M+ | M− |
| AC | ± | % | ÷ |
| 7 | 8 | 9 | × |
| 4 | 5 | 6 | − |
| 1 | 2 | 3 | + |
| √ | 0 | . | = |

## Code

- [lib/calculator_engine.dart](lib/calculator_engine.dart) — all calculation
  state and logic, with no UI code, so it can be unit tested on its own.
- [lib/main.dart](lib/main.dart) — the Material 3 UI: display, keypad and
  keyboard handling.

## Running

```sh
flutter pub get
flutter run       # add -d chrome, -d windows, … to pick a device
flutter test
```
