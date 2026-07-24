## 1.0.2

- Add `example/README.md` for pub.dev's Example tab. It describes what the demo
  app shows — single line, wrapping, a minFontSize floor with ellipsis, and an
  AutoSizeGroup — with the demo gif and the key widget snippets. Docs only.

## 1.0.1

- Correct the measured numbers in the code comment and the 0.3.2 note. Both
  said the degenerate NaN-size layout collapses to `width 0.0, height 1.0`;
  re-instrumenting the shipped fit check shows the opposite — a zero *height*,
  not a zero width: `'hello'` measures `width 1.25, height 0.0`, and the width
  grows with the text while the height stays `0.0`. The mechanism is otherwise
  unchanged (a zero-height box within the width limit passes the check), and an
  empty string is the exception worth noting: it lays out to a NaN height,
  which the check waves through too. Docs only; no code change.

## 1.0.0

The API is stable. This release adds no features and changes no behaviour; it
settles the one question that was still open, so the surface can be frozen.

- Document and pin how an `AutoSizeGroup` settles. Each member measures itself
  against its own constraints alone, never against what the group has already
  agreed on, so reporting a size can only lower the group's minimum. The fixed
  point is therefore reached one frame after the members first appear, and a
  rebuild cannot feed back into a member's own candidate size — there is no
  oscillation to damp. The cost is that first frame: members build in tree
  order, so one that builds before a more constrained sibling lays out at its
  own larger size until the next frame. Tests now pin all three properties
  (settles by the second frame, stays settled across further frames, and grows
  back when the member setting the minimum is removed).
- `textScaleFactor` remains available and `@Deprecated`, for source
  compatibility with `auto_size_text`. It can be removed in a 2.0.0.

`AutoSizeGroup` is `final`. `AutoSizeText` is deliberately left open, because
`auto_size_text` and Flutter's own `Text` are, and this package is meant to be
a drop-in for the first.

## 0.3.2

- Correct the mechanism in the 0.3.1 note, which said each fit check "accepted
  the resulting NaN metrics because comparisons against NaN are false". I
  instrumented the shipped fit check to check that, and it is not what happens.
  The scaled font size is indeed NaN (`0 × Infinity`), but for ordinary text
  Flutter does not lay that out to NaN metrics: it collapses the degenerate
  layout to a zero-*height* one (measured for `'hello'`: `width` 1.25,
  `height` 0.0), and the fit check accepts it the ordinary way — a zero-height
  box within the width limit fits — so the search stops at the smallest
  candidate and renders at that size. The NaN never reaches the comparison. (An
  empty string is the exception: it lays out to a NaN *height*, which the check
  also accepts, since `NaN > maxHeight` is false — the very hazard below.) The observed defect (`fontSize: 0` rendering at 4.0 instead of
  0.0, with `minFontSize: 4`) and the fix are unchanged; only the explanation
  was wrong, and it came from an unverified guess about what the engine does
  with a NaN size. The `>` comparison against NaN is a genuine hazard, but it
  is not the one this bug hit.

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
