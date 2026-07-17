import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:text_autosize/text_autosize.dart';

import 'utils.dart';

/// A monotonic but nonlinear scaler, similar in spirit to the system
/// nonlinear font scaling on Android 14 and later.
class _AffineTextScaler extends TextScaler {
  const _AffineTextScaler(this.multiplier, this.offset);

  final double multiplier;
  final double offset;

  @override
  double scale(double fontSize) => fontSize * multiplier + offset;

  @override
  double get textScaleFactor => multiplier;
}

void main() {
  testWidgets('accounts for the MediaQuery textScaler when fitting', (
    tester,
  ) async {
    final text = await pumpAndGetText(
      tester: tester,
      widget: MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2)),
        child: const SizedBox(
          width: 100,
          child: AutoSizeText(
            'XXXXX',
            style: TextStyle(fontSize: 60),
            maxLines: 1,
            minFontSize: 1,
          ),
        ),
      ),
    );

    // Five glyphs at scaled size must fit into 100 pixels, so the logical
    // font size lands on 10 and the rendered size on 20.
    expect(text.style!.fontSize, 10);
    expect(effectiveFontSize(text), 20);
  });

  testWidgets('the textScaler parameter overrides the MediaQuery scaler', (
    tester,
  ) async {
    final text = await pumpAndGetText(
      tester: tester,
      widget: MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(3)),
        child: const SizedBox(
          width: 100,
          child: AutoSizeText(
            'XXXXX',
            style: TextStyle(fontSize: 60),
            maxLines: 1,
            minFontSize: 1,
            textScaler: TextScaler.noScaling,
          ),
        ),
      ),
    );

    expect(text.style!.fontSize, 20);
    expect(effectiveFontSize(text), 20);
  });

  testWidgets('accounts for the textScaler in rich text', (tester) async {
    final text = await pumpAndGetText(
      tester: tester,
      widget: MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2)),
        child: const SizedBox(
          width: 100,
          child: AutoSizeText.rich(
            TextSpan(text: 'XXXXX'),
            style: TextStyle(fontSize: 60),
            maxLines: 1,
            minFontSize: 1,
          ),
        ),
      ),
    );

    expect(effectiveFontSize(text), 20);
    expect(tester.getSize(find.byType(RichText)).width, lessThanOrEqualTo(100));
  });

  testWidgets('supports nonlinear scalers without overflowing', (tester) async {
    final text = await pumpAndGetText(
      tester: tester,
      widget: const SizedBox(
        width: 100,
        child: AutoSizeText(
          'XXXXX',
          style: TextStyle(fontSize: 60),
          maxLines: 1,
          minFontSize: 1,
          textScaler: _AffineTextScaler(1.5, 5),
        ),
      ),
    );

    // The largest logical size k with 5 * (1.5 * k + 5) <= 100 is 10.
    expect(text.style!.fontSize, 10);
    expect(effectiveFontSize(text), 20);
    expect(tester.getSize(find.byType(RichText)).width, lessThanOrEqualTo(100));
  });
}
