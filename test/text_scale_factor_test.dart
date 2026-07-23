import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:text_autosize/text_autosize.dart';

import 'utils.dart';

void main() {
  testWidgets('textScaleFactor applies a linear scaler', (tester) async {
    final text = await pumpAndGetText(
      tester: tester,
      widget: const SizedBox(
        width: 100,
        child: AutoSizeText(
          'XXXXX',
          style: TextStyle(fontSize: 60),
          maxLines: 1,
          minFontSize: 1,
          // ignore: deprecated_member_use_from_same_package
          textScaleFactor: 2,
        ),
      ),
    );

    // Five glyphs at scaled size must fit into 100 pixels, so the logical
    // font size lands on 10 and the rendered size on 20, matching a
    // TextScaler.linear(2).
    expect(text.textScaler, TextScaler.linear(2));
    expect(text.style!.fontSize, 10);
    expect(effectiveFontSize(text), 20);
  });

  testWidgets('textScaleFactor overrides the MediaQuery scaler', (
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
            // ignore: deprecated_member_use_from_same_package
            textScaleFactor: 1,
          ),
        ),
      ),
    );

    expect(text.textScaler, TextScaler.linear(1));
    expect(effectiveFontSize(text), 20);
  });

  testWidgets('setting both textScaler and textScaleFactor asserts', (
    tester,
  ) async {
    await pump(
      tester: tester,
      widget: const SizedBox(
        width: 100,
        child: AutoSizeText(
          'XXXXX',
          style: TextStyle(fontSize: 60),
          maxLines: 1,
          minFontSize: 1,
          textScaler: TextScaler.noScaling,
          // ignore: deprecated_member_use_from_same_package
          textScaleFactor: 2,
        ),
      ),
    );

    expect(tester.takeException(), isAssertionError);
  });
}
