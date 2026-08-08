# text_autosize example

The example app in `lib/main.dart` shows `AutoSizeText` shrinking to fit a width
you can drag, across the cases that matter: a single line, wrapping to two
lines, a `minFontSize` floor with an ellipsis once it can shrink no further, and
an `AutoSizeGroup` keeping several texts at one shared size.

It opens on the panel that shows why the fitted size has to be measured with the
real `TextScaler`. Two identical boxes hold the same label with the same
`minFontSize` and step size, and differ only in how they consult the scaler: one
is an `AutoSizeText`, the other derives its fit from a single factor sampled at
the style's font size. Drag the scale up on the nonlinear curve and the second
one overflows the box it was fitted to; drag it back to 1.0, or switch to a
linear scaler, and both agree exactly. Each box reports the size it settled on
and the size it renders at, read back from the `Text` that was built.

![Two identical boxes at a 2.0x nonlinear font scale: the measured fit stays inside, the single-factor fit is cut off](https://raw.githubusercontent.com/Yusufihsangorgel/text_autosize/main/doc/scaler.png)

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
