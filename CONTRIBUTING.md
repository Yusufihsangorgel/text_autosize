# Contributing to text_autosize

## Support

One maintainer looks after this package, best effort. There is no promised
response time and no release schedule.

## Bug reports

A good bug report contains:

* The text_autosize version your app resolves, from `pubspec.lock`.
* The full output of `flutter --version`.
* The platform it ran on: Android, iOS, Linux, macOS, web, or Windows.
* A minimal reproduction, the smallest code that shows the problem.

## Setup

Install Flutter. This package needs:

* Dart SDK `^3.8.0`
* Flutter `>=3.32.0`

## Checks

Run these in the repository root. CI runs the same four commands:

```
flutter pub get
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test --exclude-tags demo
```

Then, in `example/`, CI also runs:

```
flutter pub get
flutter analyze
flutter test --tags demo test/scaler_capture_test.dart
```

## Pull requests

* One change per pull request.
* Add an entry to `CHANGELOG.md`.
* Link the issue, for example `Fixes #12`.
