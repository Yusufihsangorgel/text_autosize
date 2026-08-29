# text_autosize

## Purpose

`text_autosize` is a drop-in replacement for `auto_size_text` that shrinks
and reflows text until it fits a bounded box (`AutoSizeText`,
`AutoSizeGroup`). Skip it when a plain `Text` can wrap or scroll; skip
`FittedBox` when the text must reflow (`FittedBox` lays the child out
unconstrained and scales one unwrapped line as a picture);
`auto_size_text` has no `TextScaler` and throws on `WidgetSpan`.

## Usage

```dart
import 'package:text_autosize/text_autosize.dart';

SizedBox(
  width: 200,
  child: AutoSizeText(
    'The text to display',
    style: TextStyle(fontSize: 20),
    maxLines: 2,
  ),
)
```

Migrate from `auto_size_text` by changing the import to
`package:text_autosize/text_autosize.dart`. Names are unchanged.

## Contracts

**Parent bounds.** `AutoSizeText` is a `LayoutBuilder`. It resizes only
against a finite `maxWidth` / `maxHeight` (`SizedBox`, `Expanded`).
On an unbounded axis (`ListView` scroll direction,
`UnconstrainedBox`, a `Row` child without flex) it keeps the preferred
size and does not shrink on that axis.

**`minFontSize` / `maxFontSize` / `stepGranularity` / `presetFontSizes`.**
Defaults: 12, infinity, 1, unset. Preferred size is `style.fontSize`
(else 14) clamped to `[minFontSize, maxFontSize]`. The widget only
shrinks; it does not grow past preferred unless `presetFontSizes` is
set. Search is binary over that range in steps of `stepGranularity`.
`minFontSize` (and finite `maxFontSize`) must be multiples of
`stepGranularity` (≥ 0.1). If `presetFontSizes` is set it **wins**:
min/max/step are ignored. The list must be non-empty and strictly
descending; the largest fitting entry is used.

**`AutoSizeGroup`.** Members share one logical size: the smallest of
their individual fits. Each still applies its own `TextScaler`. Cost:
one extra frame to settle (tree order: a member that builds before a
tighter sibling paints at its own size first). Reporting can only lower
the group minimum, so it does not oscillate. Hold the instance on
`State`. Dispose unregisters; dropping the member that set the minimum
lets the rest grow on the next frame.

**`textScaler`.** `minFontSize` / `maxFontSize` / `presetFontSizes` bound
the logical size, not the on-screen size. Measurement uses `textScaler`,
else `textScaleFactor` as `TextScaler.linear`, else
`MediaQuery.textScalerOf`. The user's scale still grows the glyphs.
Setting both `textScaler` and `textScaleFactor` asserts. The inner
`Text` (`textKey`) stores the logical `fontSize` plus a `TextScaler`.

**Nothing fits.** Renders at `minFontSize` (or the smallest preset);
`overflow` then applies. If `overflowReplacement` is set and the fit
failed, that widget is shown instead. `overflow` and
`overflowReplacement` cannot both be set.

**`AutoSizeText.rich`.** Every span is scaled by the same factor. A
`WidgetSpan` is measured as a square of the candidate size (override
with `placeholderSize`) and painted into that box through a `FittedBox`.

## Mistakes

- **Unbounded constraints.** Symptom: text stays at `style.fontSize` and
  overflows or never shrinks. Fix: bound the axis (`SizedBox`,
  `Expanded`).
- **`AutoSizeGroup()` in `build`.** A new group each rebuild resets
  membership, so the extra settle frame never becomes the stable frame.
  Symptom: members flicker between individual and shared sizes;
  `pumpAndSettle` can hang. Fix: store the group on `State`.
- **Goldens or asserts on the first grouped frame.** Symptom: members
  disagree for one frame. Fix: `pump()` once more.
- **`FittedBox` around `AutoSizeText`.** Symptom: one scaled unwrapped
  line. Fix: drop the `FittedBox` and bound the box.
- **Inside `IntrinsicWidth` / `IntrinsicHeight`.** Symptom:
  `LayoutBuilder` throws. Fix: do not nest them.
- **`textKey` `style.fontSize` after migrating.** Symptom: expected
  scaled pixels, got the logical size. Fix: apply the inner `Text`'s
  `textScaler`.

## Layout

- `lib/text_autosize.dart` — public export: `AutoSizeText`, `AutoSizeGroup`
- `lib/src/auto_size_text.dart` — implementation
- `test/` — `flutter test --exclude-tags demo`
- `example/lib/main.dart` — `cd example && flutter run`

Requires Flutter >= 3.32.
