## 0.1.3

- Install instructions now say `pub add` instead of pinning a version. The
  pinned number was stale by several releases and would have been stale again
  after the next one: the README ships frozen in the archive, so a hand-edited
  version line is wrong the moment anything is published. This one cannot go
  out of date.

## 0.1.2

- Docs: tightened the README wording and visuals.

## 0.1.1

- Expand the package description to name what the package does in the
  words people search for. No code changes.

# Changelog

## 0.1.0

Initial release. The API follows `auto_size_text` 3.0.0, with these changes:

* `textScaler` replaces `textScaleFactor`. The fitted font size accounts for
  the ambient `MediaQuery` scaler, including nonlinear scalers.
* Rich text is measured with the fully resolved style, matching how
  `Text.rich` renders it.
* Measurement resolves `textAlign` and `textDirection` like the rendered
  `Text` instead of assuming left-aligned, left-to-right text.
* A single `TextPainter` is reused for all fit measurements of a widget.
* `textWidthBasis`, `textHeightBehavior` and `selectionColor` are passed
  through to the built `Text`.
* `presetFontSizes` are asserted to be in descending order.
