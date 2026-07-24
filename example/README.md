# text_autosize example

The example app in `lib/main.dart` shows `AutoSizeText` shrinking to fit a width
you can drag, across the cases that matter: a single line, wrapping to two
lines, a `minFontSize` floor with an ellipsis once it can shrink no further, and
an `AutoSizeGroup` keeping several texts at one shared size.

![The example app: text resizing to fit as the width changes](https://raw.githubusercontent.com/Yusufihsangorgel/text_autosize/main/doc/demo.gif)

```dart
// One line, shrink to fit.
const AutoSizeText('Resize me to fit', maxLines: 1);

// Stop shrinking at 18pt and show an ellipsis instead.
const AutoSizeText(longText, minFontSize: 18, overflow: TextOverflow.ellipsis);

// Keep several texts at the same size — the size of the most constrained one.
final group = AutoSizeGroup();
AutoSizeText('Label one', group: group, maxLines: 1);
AutoSizeText('A much longer label two', group: group, maxLines: 1);
```

Run it:

```
cd example
flutter run
```

The API follows `auto_size_text`, so a call site migrates by changing the
import. See the package README for the differences and for how an `AutoSizeGroup`
settles.
