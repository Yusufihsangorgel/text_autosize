Issue: #<number>

Checklist, matching CI. Run in the repository root:

- [ ] `flutter pub get`
- [ ] `dart format --output=none --set-exit-if-changed .`
- [ ] `flutter analyze`
- [ ] `flutter test --exclude-tags demo`

Run in `example/`:

- [ ] `flutter pub get`
- [ ] `flutter analyze`
- [ ] `flutter test --tags demo test/scaler_capture_test.dart`
- [ ] `CHANGELOG.md` entry added
