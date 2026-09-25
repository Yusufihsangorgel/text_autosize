# Package engineering rules: text_autosize

Rules-Version: text_autosize/a5cfb183fdeb3e7fd9da684bd9c2b9eb3712bf173df8aec258179653fa67a886
Core-Version: 1
Core-Digest: 1825fa7ff346dca23e65b1b3bf9b2e3e06959f1414bae9952d596d2f62f09b8f
Survey-Digest: f90f45c8a172068c3ed3b9488ba5a7cb4e58efa93c380d2d9a70b399349ec35e
Evidence-Revision: dd5eda5
Verified-Revision: unverified

Read CONTRIBUTING.md and docs/engineering/debt.json before editing.

## Current architecture
HEAD dd5eda5 (2026-08-29), version 1.3.1, 38 commits. It is the API compatible successor of auto_size_text (flutter >=3.32.0, sdk ^3.8.0). The only dependency is the Flutter SDK. The whole implementation sits in one file: lib/src/auto_size_text.dart (958 lines). Contents: AutoSizeGroup. It shares the smallest size that fits across members and reports changes through a microtask. AutoSizeText first tries the preferred size inside a LayoutBuilder. If that does not fit, it steps by stepGranularity or binary searches over presetFontSizes. Every trial measurement (prob) uses a single reused TextPainter. _RatioTextScaler layers the found ratio on top of the ambient TextScaler. WidgetSpan placeholders are also sized. The group and the state talk through library private methods. Splitting the file would break that link. The strictest analysis settings of the six packages are here (strict-casts/inference/raw-types, public_member_api_docs). There is no hook/ or bin/. AGENTS.md is written for an agent that uses the package.

## Layers and responsibilities
- lib/text_autosize.dart: `export 'src/auto_size_text.dart' show AutoSizeGroup, AutoSizeText` and a migration note.
- lib/src/auto_size_text.dart:36-88: AutoSizeGroup: holds the fitting sizes of members, picks the smallest, requests a repaint through a microtask, and drops disposed members.
- lib/src/auto_size_text.dart:90-920: AutoSizeText constructors and _AutoSizeTextState: style resolution, validation, binary search, prob measurement, WidgetSpan placeholder sizing, Text/Text.rich production.
- lib/src/auto_size_text.dart:922-958: _RatioTextScaler: applies the found ratio on top of the ambient TextScaler.
- tool/, example/: The scaler curve figure; the demo app and example/test/scaler_capture_test.dart that produces the README figure.

## Public API and dependency direction
lib/text_autosize.dart exports only AutoSizeGroup and AutoSizeText. The AutoSizeText(data) and AutoSizeText.rich(textSpan) constructors carry the parameters of auto_size_text. placeholderSize and textScaler are added. textScaleFactor is @Deprecated ('Will be removed in 2.0.0.'). The only public member of AutoSizeGroup is its constructor. Private types: _AutoSizeTextState, _RatioTextScaler.

A single file. It imports only dart:async and package:flutter/widgets.dart (no Material in lib). Direction inside the file: AutoSizeText → _AutoSizeTextState → {private methods of AutoSizeGroup, _RatioTextScaler}. AutoSizeGroup also calls _AutoSizeTextState._notifySync. This mutual link stays inside the same library and is deliberate.

## Error, state and platform contracts
- API compatibility: names and defaults of auto_size_text are kept (minFontSize 12, stepGranularity 1, wrapWords true). The only difference is the use of TextScaler.
- Validation: asserts in _validateProperties name the parameter (:501-558). If the font size is degenerate (0, negative, infinite), no exception is thrown. The code returns without autosizing (:589-591, 899-901).
- Configuration: constructor parameters, the placeholderSize callback and a shared AutoSizeGroup object.
- Measure equals render principle: the prob span mirrors the inner span of Text/Text.rich (:568-574) and the same properties are applied to the painter (:807-814).
- Performance: a single TextPainter is reused (:423-429). There are O(log n) probes per build (:102-110).
- Deprecation: the @Deprecated message names the release that will remove it. The ignores sit only at call sites of that member.
- Streams/cancellation: group notification goes through scheduleMicrotask. Registration happens in initState and didUpdateWidget, removal in dispose. The TextPainter is disposed (:914-919). No FFI and no platform check. The scaler comes from MediaQuery.textScalerOf.

## Package rules
### text_autosize/TA-01 [MUST]
Keep AutoSizeText and AutoSizeGroup source compatible with auto_size_text: names, parameters and defaults (minFontSize 12, stepGranularity 1, wrapWords true). Record each intentional difference in README and CHANGELOG.
Reason: The library doc promises 'migration by changing only the import'. Defaults are part of this compatibility too.
Evidence: lib/text_autosize.dart:3-5; lib/src/auto_size_text.dart:98-100, 143-170, 182-209
Evidence role: current-pattern
Existing violation: none

### text_autosize/TA-02 [MUST]
Keep AutoSizeGroup and _AutoSizeTextState in one library. The group reaches its members through library-private methods, and splitting the file breaks that contract.
Reason: _register, _updateFontSize, _remove and _notifySync are private to the library. The single file is a load-bearing part of the architecture; splitting it either opens a public surface or requires part files.
Evidence: lib/src/auto_size_text.dart:40-87, 435, 443-444, 484-487, 910-912, 916
Evidence role: current-pattern
Existing violation: none

### text_autosize/TA-03 [MUST]
The fit probe measures what is rendered. Every property forwarded to Text or Text.rich in _buildText is also applied to the probe painter in _checkTextFits.
Reason: The comments explicitly target measurement and render being identical; a mismatch produces a wrong size. The 1.3.1 fix for 'inline widget was shrinking twice' was a bug of this class.
Evidence: lib/src/auto_size_text.dart:568-574, 797-858, 860-908; git 294d961
Evidence role: current-pattern
Existing violation: none

### text_autosize/TA-04 [MUST]
Express text scaling through TextScaler. minFontSize, maxFontSize and presetFontSizes bound the logical size, and the ambient scaler applies on top.
Reason: This is the difference that sets the package apart from auto_size_text. The README figure and text_scaler_test protect it.
Evidence: lib/src/auto_size_text.dart:354-367, 462-469, 922-958; test/text_scaler_test.dart; example/test/scaler_capture_test.dart
Evidence role: current-pattern
Existing violation: none

### text_autosize/TA-05 [MUST]
A deprecation names its replacement and the version it will be removed in. deprecated_member_use ignores appear only at call sites of that deprecated member.
Reason: The existing @Deprecated messages carry a version (99725b4). The ignores sit only on textScaleFactor calls and on the TextScaler.textScaleFactor override in Flutter.
Evidence: lib/src/auto_size_text.dart:162, 201, 375, 463, 515, 946; git 99725b4
Evidence role: current-pattern
Existing violation: none

### text_autosize/TA-06 [MUST]
Validate arguments in _validateProperties with asserts. Each message names the offending parameter.
Reason: Validation is gathered in one place; validation for a new parameter must be added in the same place.
Evidence: lib/src/auto_size_text.dart:471, 501-558
Evidence role: current-pattern
Existing violation: none

### text_autosize/TA-07 [MUST]
Keep the strict analyzer settings (strict-casts, strict-inference, strict-raw-types) and the lints public_member_api_docs, directives_ordering, prefer_final_locals and unnecessary_lambdas.
Reason: This package uses the strictest analysis settings of the six packages; loosening them creates debt.
Evidence: analysis_options.yaml:1-15
Evidence role: current-pattern
Existing violation: none

### text_autosize/TA-08 [MUST]
Code builds and tests pass on Flutter 3.32.0, the declared floor, and on latest stable. Raise the pubspec floors and the CI matrix before using a newer API.
Reason: The CI matrix actually runs the base version. Using an API that is absent in the base version breaks users on that version.
Evidence: pubspec.yaml environment (sdk ^3.8.0, flutter >=3.32.0); .github/workflows/ci.yaml matrix flutter-version ['', '3.32.0']
Evidence role: current-pattern
Existing violation: none

### text_autosize/TA-09 [MUST]
Tests drive the public library only, with no lib/src import, one file per feature and shared helpers in test/utils.dart. The README figure test in example/ keeps passing.
Reason: All tests are black box; the private classes are unreachable anyway. The figure step guarantees that the numbers in the README can still be produced by the code.
Evidence: test/*.dart (src import 0); test/utils.dart:1-43; .github/workflows/ci.yaml 'Render the README's scaler figure' step
Evidence role: current-pattern
Existing violation: none

### text_autosize/TA-10 [SHOULD]
Keep a build at O(log n) probe layouts through one reused TextPainter. Do not allocate painters or RegExps per probe.
Reason: The class doc promises this cost. The RegExp allocation at :817 is an exception to that promise (debt T4).
Evidence: lib/src/auto_size_text.dart:102-110, 423-429, 807-814, 817
Evidence role: both
Existing violation: text_autosize-D004

## Required verification
- Working directory: repository root; command: flutter pub get; conditions: ci.yaml job build; evidence: .github/workflows/ci.yaml:29.
- Working directory: repository root; command: dart format --output=none --set-exit-if-changed .; conditions: ci.yaml job build; evidence: .github/workflows/ci.yaml:33.
- Working directory: repository root; command: flutter analyze; conditions: ci.yaml job build; evidence: .github/workflows/ci.yaml:34.
- Working directory: repository root; command: flutter test --exclude-tags demo; conditions: ci.yaml job build; evidence: .github/workflows/ci.yaml:35.
- Working directory: example; command: flutter pub get; conditions: ci.yaml job build; evidence: .github/workflows/ci.yaml:39.
- Working directory: example; command: flutter analyze; conditions: ci.yaml job build; evidence: .github/workflows/ci.yaml:40.
- Working directory: example; command: flutter test --tags demo test/scaler_capture_test.dart; conditions: ci.yaml job build; evidence: .github/workflows/ci.yaml:49.
Not verified by the survey:
- Analysis, test and format were not run (read only). CI history was not measured (no network).
- The difference between the working tree and HEAD was not measured. Line evidence refers to HEAD dd5eda5.
- API compatibility with auto_size_text was not verified against the difference list in the README or the upstream source (the README body was not read, no network).
- Only the case counts of the test files and test/utils.dart were read. Test bodies were not read.
- Test coverage percentage and pub archive contents were not measured.

## Existing debt
The complete register is docs/engineering/debt.json.
- text_autosize-D001 | small | lib/src/auto_size_text.dart:162, 201, 375-376, 463-464, 515-516; test/text_scale_factor_test.dart:18, 46, 70 | planned removal (deprecation)
  Fix: In 2.0.0 remove the parameter, these two ignores and text_scale_factor_test; write a migration note in the CHANGELOG. The ignore at :946 depends on the Flutter TextScaler.textScaleFactor and stays separate.
  Closure: The 2.0.0 release removes the textScaleFactor parameter, its two ignores and text_scale_factor_test, and the CHANGELOG carries a migration note. The ignore for the Flutter TextScaler override at line 946 stays untouched.
- text_autosize-D002 | small | lib/src/auto_size_text.dart:589, 899 | duplicate logic
  Fix: Write a single private helper function; let both call sites use it.
  Closure: One private helper holds the degenerate base check and both call sites use it.
- text_autosize-D003 | medium | lib/src/auto_size_text.dart:560-665 | cognitive complexity (J2)
  Fix: Extract the binary search over the candidate list into a pure function that takes the fit check as a callback. Widget tests act as the safety net; add unit tests for boundary cases.
  Closure: The binary search over candidate sizes is a pure function taking the fit check as a callback, with unit tests for boundary cases. The widget tests keep passing.
- text_autosize-D004 | small | lib/src/auto_size_text.dart:817 | unnecessary allocation
  Fix: Move the RegExp into a static final field.
  Closure: The whitespace splitter RegExp lives in a static final field and no RegExp is allocated per probe.
- text_autosize-D005 | small | example/pubspec.yaml environment; pubspec.yaml environment | configuration drift
  Fix: Align the example flutter base to 3.32.0.
  Closure: example/pubspec.yaml declares flutter >=3.32.0 and an sdk constraint consistent with the package floor.
