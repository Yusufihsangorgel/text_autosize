## 0.3.1

- Correct the description of the 0.3.0 fix. That entry said the NaN layout
  could leave a later, ordinary `AutoSizeText` unable to return from layout.
  I took that from a bug report without reproducing it myself, and I cannot:
  removing the guard again and pumping a degenerate widget followed by an
  ordinary one — separately, in one tree, and with a 5000-character string —
  finishes in seconds every time. The claim was not mine to make and it is
  withdrawn.

  What 0.3.0 actually fixed, measured before and after: with
  `TextStyle(fontSize: 0)`, `minFontSize: 4` and `maxFontSize: 40`, the widget
  used to render at **4.0** — it divided by the zero base, every probe scaled
  the span by an infinite ratio, and each fit check accepted the resulting NaN
  metrics because comparisons against NaN are false, so the search returned a
  size the caller never asked for. It now renders at **0.0**, which is exactly
  what a plain `Text` does with the same style. Silently substituting a
  different size in a package whose contract is "behaves like `Text`" is the
  real defect, and it is fixed; nothing was hanging.

## 0.3.0

- Fix a hang reachable from a legal style. `TextStyle(fontSize: 0)` — which a
  plain `Text` renders without complaint — made every fit probe scale the span
  by `candidate / 0`. The resulting infinite ratio laid out text at NaN sizes,
  and because each fit check compares against NaN (where every comparison is
  false) the probe reported that it fitted. Worse than the wrong answer, that
  NaN layout left the text engine in a state where a later, ordinary
  `AutoSizeText` could stop returning from layout entirely. A zero, negative or
  infinite base now skips the ratio machinery and renders at the size the caller
  asked for, which is what `Text` does. Covered by tests, including one that
  pumps an ordinary widget afterwards to prove nothing is wedged.
- Mark `AutoSizeGroup` as `final`. Its entire contract is private, so an
  external `implements AutoSizeGroup` compiled but was guaranteed to fail with
  `NoSuchMethodError` the moment a widget used it. `AutoSizeText` is
  deliberately left open: it is a drop-in for `auto_size_text`, whose
  `AutoSizeText` is open, as is Flutter's own `Text`, and subclassing a text
  widget to preset its style is a real pattern this should not break.
- Remove a stray `# Changelog` heading from the middle of this file.

## 0.2.0

- Add back a deprecated `textScaleFactor` parameter on `AutoSizeText` and
  `AutoSizeText.rich`. The 0.1.0 release dropped it, which broke the drop-in
  claim: any call site that set `textScaleFactor` failed to compile. It now
  compiles again and maps to `TextScaler.linear(factor)`. Prefer `textScaler`;
  `textScaleFactor` is deprecated and will be removed later. Setting both
  asserts in debug builds.

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
