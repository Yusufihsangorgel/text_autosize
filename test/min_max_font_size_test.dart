import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:text_autosize/text_autosize.dart';

import 'utils.dart';

void main() {
  testWidgets('forces valid min and max fontSize', (tester) async {
    await tester.pumpWidget(
      const AutoSizeText(
        'AutoSizeText Test',
        style: TextStyle(fontSize: 25),
        minFontSize: -1,
      ),
    );
    expect(tester.takeException(), isAssertionError);

    await tester.pumpWidget(
      const AutoSizeText(
        'AutoSizeText Test',
        style: TextStyle(fontSize: 25),
        maxFontSize: 0,
      ),
    );
    expect(tester.takeException(), isAssertionError);

    await tester.pumpWidget(
      const AutoSizeText(
        'AutoSizeText Test',
        style: TextStyle(fontSize: 25),
        minFontSize: 20,
        maxFontSize: 10,
      ),
    );
    expect(tester.takeException(), isAssertionError);
  });

  testWidgets('respects minFontSize and overflows below it', (tester) async {
    final text = await pumpAndGetText(
      tester: tester,
      widget: const SizedBox(
        width: 10,
        height: 10,
        child: AutoSizeText(
          'AutoSizeText Test',
          style: TextStyle(fontSize: 25),
          minFontSize: 15,
        ),
      ),
    );
    // The text cannot fit at 15, but the size never drops below minFontSize.
    // Rendering is left to the Text widget, which clips or truncates
    // according to its overflow behavior.
    expect(effectiveFontSize(text), 15);
  });

  testWidgets('is larger than minFontSize if there is enough space', (
    tester,
  ) async {
    await pumpAndExpectFontSize(
      tester: tester,
      expectedFontSize: 30,
      widget: const SizedBox(
        width: 120,
        height: 40,
        child: AutoSizeText(
          'XXXX',
          style: TextStyle(fontSize: 30),
          minFontSize: 15,
        ),
      ),
    );
  });

  testWidgets('respects maxFontSize', (tester) async {
    await pumpAndExpectFontSize(
      tester: tester,
      expectedFontSize: 20,
      widget: const DefaultTextStyle(
        style: TextStyle(fontSize: 30),
        child: AutoSizeText('AutoSizeText Test', maxFontSize: 20),
      ),
    );

    await pumpAndExpectFontSize(
      tester: tester,
      expectedFontSize: 20,
      widget: const AutoSizeText(
        'AutoSizeText Test',
        style: TextStyle(fontSize: 30),
        maxFontSize: 20,
      ),
    );

    await pumpAndExpectFontSize(
      tester: tester,
      expectedFontSize: 20,
      widget: const AutoSizeText(
        'AutoSizeText Test',
        style: TextStyle(fontSize: 20),
        maxFontSize: 30,
      ),
    );
  });
}
