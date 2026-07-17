# text_autosize

A Flutter widget that automatically resizes text to fit within its bounds.

The API follows the `auto_size_text` package by Simon Leier, so existing code
migrates by changing the import. On top of the familiar API, this package is
built against current Flutter releases and handles `TextScaler` correctly,
including nonlinear system font scaling.

## Features

* Shrinks text until it fits the available width, height and `maxLines`.
* `minFontSize`, `maxFontSize` and `stepGranularity` control the search range.
* `presetFontSizes` restricts the text to a fixed list of sizes.
* `AutoSizeGroup` keeps several texts at the same size.
* `AutoSizeText.rich` resizes a whole `TextSpan` tree proportionally.
* `overflowReplacement` swaps in another widget when nothing fits.
* `textScaler` aware: the fitted size accounts for the user's font scale.
* Works inside `SelectionArea`, since it builds a regular `Text` widget.

## Usage

```dart
import 'package:text_autosize/text_autosize.dart';

AutoSizeText(
  'The text to display',
  style: TextStyle(fontSize: 20),
  maxLines: 2,
)
```

The widget behaves like `Text`, except that it lowers the font size until the
text fits the incoming constraints. It needs bounded constraints to resize
against, for example from a `SizedBox` or an `Expanded`.

### maxLines and minFontSize

```dart
AutoSizeText(
  'A single line that shrinks down to 10 before it ellipsizes',
  style: TextStyle(fontSize: 30),
  maxLines: 1,
  minFontSize: 10,
  overflow: TextOverflow.ellipsis,
)
```

### Preset font sizes

If only some sizes are allowed, pass them in descending order. The first size
that fits is used:

```dart
AutoSizeText(
  'One of three sizes',
  presetFontSizes: [40, 20, 14],
  maxLines: 1,
)
```

### Synchronizing several texts

Give all texts the same `AutoSizeGroup`. Every member renders at the size of
the most constrained one:

```dart
final group = AutoSizeGroup();

AutoSizeText('Label one', group: group, maxLines: 1);
AutoSizeText('A much longer label two', group: group, maxLines: 1);
```

### Rich text

```dart
AutoSizeText.rich(
  TextSpan(
    text: 'Mixed ',
    children: [
      TextSpan(text: 'sizes', style: TextStyle(fontSize: 40)),
    ],
  ),
  style: TextStyle(fontSize: 20),
  maxLines: 1,
)
```

All font sizes in the span tree are scaled by the same factor, so the
proportions of the spans are preserved.

### Overflow replacement

```dart
AutoSizeText(
  'A text that might not fit at minFontSize',
  minFontSize: 16,
  overflowReplacement: Text('Not enough room'),
)
```

## Migration from auto_size_text

1. Replace the dependency in `pubspec.yaml`:

   ```yaml
   dependencies:
     text_autosize: ^0.1.0
   ```

2. Replace the import. The class names `AutoSizeText` and `AutoSizeGroup` are
   unchanged:

   ```dart
   import 'package:text_autosize/text_autosize.dart';
   ```

3. Replace `textScaleFactor` with `textScaler`:

   ```dart
   // before
   AutoSizeText('Hello', textScaleFactor: 1.5)
   // after
   AutoSizeText('Hello', textScaler: TextScaler.linear(1.5))
   ```

Intentional behavior differences from `auto_size_text` 3.0.0:

* `minFontSize`, `maxFontSize` and `presetFontSizes` bound the logical
  (unscaled) font size. The user's font scale is applied on top, so text
  scaled up by the system still respects the accessibility setting.
* Rich text is measured with the fully resolved style, exactly as `Text.rich`
  renders it. The original measured the span's own style only, which could
  mismeasure spans that inherit their size from `DefaultTextStyle`.
* Measurement resolves `textAlign` and `textDirection` the same way the
  rendered `Text` does, instead of assuming left-aligned, left-to-right text.
* An `AutoSizeGroup` synchronizes the logical font size of its members. Each
  member still applies its own `TextScaler` when rendering.
* `presetFontSizes` must be in descending order; this is now checked with an
  assert instead of being silently required.
* `textWidthBasis`, `textHeightBehavior` and `selectionColor` are passed
  through to the built `Text`.

## How it works

The widget measures the text with a `TextPainter` against the incoming
constraints. If the preferred font size does not fit, a binary search runs
over the candidate sizes between `minFontSize` and the preferred size in
steps of `stepGranularity`, or over `presetFontSizes` if given. A build
therefore performs O(log n) text layouts for n candidate sizes, and a single
`TextPainter` instance is reused for all measurements.

## Limitations

* The widget only shrinks text below its preferred size. It does not grow
  text to fill extra space, except through `presetFontSizes`.
* Resizing needs a bounded constraint. In an unbounded context, such as the
  scroll direction of a `ListView` or inside an `UnconstrainedBox`, the text
  keeps its preferred size. This is safe but performs no resizing on that
  axis.
* The widget is built around a `LayoutBuilder`, so it cannot be used where
  intrinsic dimensions are required, for example inside `IntrinsicWidth` or
  `IntrinsicHeight`.
* `strutStyle` is passed through as given and is not resized with the text. A
  strut with a fixed font size puts a floor under the line height.

## Credits

The API follows the [auto_size_text](https://pub.dev/packages/auto_size_text)
package by Simon Leier.

## License

MIT. See [LICENSE](LICENSE).
