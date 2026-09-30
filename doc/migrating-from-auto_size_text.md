# Migrating from auto_size_text

This guide is for an app that already uses `auto_size_text` and wants to move
to `text_autosize`. It was checked against the source of `auto_size_text`
3.0.0 and against this package's `lib/` and `test/`.

For most code the move is the import. The parts that are not the import are
listed under [Differences](#differences).

## Steps

1. Swap the dependency.

   ```sh
   flutter pub remove auto_size_text
   flutter pub add text_autosize
   ```

2. Change the import in every file that uses it.

   ```dart
   // Before
   import 'package:auto_size_text/auto_size_text.dart';

   // After
   import 'package:text_autosize/text_autosize.dart';
   ```

3. Replace `textScaleFactor:` with `textScaler:`. The old name still compiles
   and behaves as `TextScaler.linear(factor)`, but it is marked `@Deprecated`
   here.

4. Run your tests. Look first at any test that reads the built `Text` through
   `textKey` and checks `style.fontSize`, and at any code that subclasses
   `AutoSizeGroup`. Both are covered below.

## Mapping

| `auto_size_text` | `text_autosize` | Notes |
| --- | --- | --- |
| `AutoSizeText(String, ...)` | `AutoSizeText(String, ...)` | Same name and same positional argument. |
| `AutoSizeText.rich(TextSpan, ...)` | `AutoSizeText.rich(TextSpan, ...)` | A `WidgetSpan` in the tree no longer throws. See [Differences](#differences). |
| `AutoSizeGroup()` | `AutoSizeGroup()` | Same constructor. The class is `final` here. |
| `textKey`, `style`, `strutStyle`, `group`, `textAlign`, `textDirection`, `locale`, `softWrap`, `overflow`, `overflowReplacement`, `maxLines`, `semanticsLabel` | same names | No change in meaning. |
| `minFontSize` (12), `maxFontSize` (infinity), `stepGranularity` (1), `wrapWords` (true) | same names and same defaults | The same asserts apply: min and max must be multiples of the step, and the step must be at least 0.1. |
| `presetFontSizes` | `presetFontSizes` | Must be strictly descending here. The debug assert is new. |
| `textScaleFactor` | `textScaler: TextScaler.linear(factor)` | `textScaleFactor` still compiles here and is deprecated. Setting both asserts. |
| (none) | `textScaler` | Any `TextScaler`, including a nonlinear one. Defaults to the `MediaQuery` scaler. |
| (none) | `textWidthBasis`, `textHeightBehavior`, `selectionColor` | The first two are used in the fit. All three are passed to the built `Text`. |
| (none) | `placeholderSize` (`AutoSizeText.rich` only) | Size of the box each `WidgetSpan` occupies, in font-size units. |

## Example

Before, with `auto_size_text`:

```dart
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';

class MenuTile extends StatefulWidget {
  const MenuTile({super.key});

  @override
  State<MenuTile> createState() => _MenuTileState();
}

class _MenuTileState extends State<MenuTile> {
  final _group = AutoSizeGroup();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 40,
            child: AutoSizeText(
              'Kitchen & Dining',
              style: const TextStyle(fontSize: 30),
              maxLines: 1,
              minFontSize: 12,
              group: _group,
              textScaleFactor: 1.2,
            ),
          ),
          SizedBox(
            height: 40,
            child: AutoSizeText(
              'Home',
              style: const TextStyle(fontSize: 30),
              maxLines: 1,
              minFontSize: 12,
              group: _group,
              textScaleFactor: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
```

After, with `text_autosize`. Two lines differ from the version above: the
import and the scale argument.

```dart
import 'package:flutter/material.dart';
import 'package:text_autosize/text_autosize.dart';

class MenuTile extends StatefulWidget {
  const MenuTile({super.key});

  @override
  State<MenuTile> createState() => _MenuTileState();
}

class _MenuTileState extends State<MenuTile> {
  final _group = AutoSizeGroup();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 40,
            child: AutoSizeText(
              'Kitchen & Dining',
              style: const TextStyle(fontSize: 30),
              maxLines: 1,
              minFontSize: 12,
              group: _group,
              textScaler: const TextScaler.linear(1.2),
            ),
          ),
          SizedBox(
            height: 40,
            child: AutoSizeText(
              'Home',
              style: const TextStyle(fontSize: 30),
              maxLines: 1,
              minFontSize: 12,
              group: _group,
              textScaler: const TextScaler.linear(1.2),
            ),
          ),
        ],
      ),
    );
  }
}
```

The "after" file is also in the repository as
[`example/lib/migrating_from_auto_size_text.dart`](../example/lib/migrating_from_auto_size_text.dart).
Most apps do not pass a scale at all and let `MediaQuery` supply it. In that
case only the import changes.

## Differences

What `auto_size_text` does that this package does not:

* `AutoSizeGroup` can be subclassed. Here it is a `final class` and an
  `extends AutoSizeGroup` will not compile.
* `textScaleFactor` is not marked deprecated in its `AutoSizeText`. Here it is
  marked `@Deprecated` and named for removal in 2.0.0.
* It does not check the order of `presetFontSizes`. Here an unsorted or
  repeated list fails an assert in debug builds.
* It declares Dart `>=2.12.0 <3.0.0` in its pubspec. This package needs Dart
  3.8 and Flutter 3.32 or later. An app pinned to an older Flutter cannot take
  the swap.
* When you pass neither `textAlign` nor `textDirection`, it measures as
  left-aligned, left-to-right text. This package measures with the resolved
  alignment and the ambient `Directionality`, as the built `Text` does.
* When the `TextSpan` of `AutoSizeText.rich` has its own style, it measures
  with that style alone. This package measures with the fully resolved style.
  A span that inherits its size from `DefaultTextStyle` can settle at a
  different size.

What this package does that `auto_size_text` does not:

* It measures each candidate size with the `TextScaler`. `auto_size_text` reads
  one number from `MediaQuery.textScaleFactorOf`. Under a linear scaler one
  number describes the scale fully and this difference disappears. Under a
  nonlinear scaler the fitted size can differ.
* A `WidgetSpan` inside `AutoSizeText.rich` is measured and painted. Pumping
  one in `auto_size_text` 3.0.0 throws
  `'dimensions != null': is not true`. Here the child occupies one em of the
  surrounding span unless `placeholderSize` says otherwise. The child's own
  size is ignored.
* `textWidthBasis`, `textHeightBehavior` and `selectionColor` exist and are
  passed to the built `Text`.
* The built `Text` carries the logical font size and a `TextScaler`. For a
  plain string, `auto_size_text` builds a `Text` with a font size that already
  includes the scale and a `textScaleFactor` of 1. A test that reads
  `style.fontSize` through `textKey` now sees the logical value.
* A base font size that is zero, negative or not finite is drawn at the size
  you gave and not fitted.

Both share these limits: the widget only shrinks, it needs bounded
constraints, it cannot sit inside `IntrinsicWidth` or `IntrinsicHeight`, and
`softWrap: false` is not part of the measurement. The README lists them under
[Limitations](../README.md#limitations).
