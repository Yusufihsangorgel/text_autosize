import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:text_autosize/text_autosize.dart';

import 'utils.dart';

void main() {
  testWidgets('uses the largest preset that fits', (tester) async {
    await pumpAndExpectFontSize(
      tester: tester,
      expectedFontSize: 100,
      widget: const SizedBox(
        width: 500,
        height: 100,
        child: AutoSizeText('XXXXX', presetFontSizes: [100, 50, 5]),
      ),
    );

    await pumpAndExpectFontSize(
      tester: tester,
      expectedFontSize: 50,
      widget: const SizedBox(
        width: 300,
        height: 100,
        child: AutoSizeText('XXXXX', presetFontSizes: [100, 50, 5]),
      ),
    );

    await pumpAndExpectFontSize(
      tester: tester,
      expectedFontSize: 5,
      widget: const SizedBox(
        width: 20,
        height: 100,
        child: AutoSizeText('XXXXX', presetFontSizes: [100, 50, 5]),
      ),
    );
  });

  testWidgets('falls back to the smallest preset when nothing fits', (
    tester,
  ) async {
    await pumpAndExpectFontSize(
      tester: tester,
      expectedFontSize: 10,
      widget: const SizedBox(
        width: 5,
        height: 5,
        child: AutoSizeText('XXXXX', presetFontSizes: [40, 20, 10]),
      ),
    );
  });

  testWidgets('rejects an empty presetFontSizes list', (tester) async {
    await tester.pumpWidget(
      const AutoSizeText('AutoSizeText Test', presetFontSizes: []),
    );
    expect(tester.takeException(), isAssertionError);
  });

  testWidgets('rejects presetFontSizes that are not descending', (
    tester,
  ) async {
    await tester.pumpWidget(
      const AutoSizeText('AutoSizeText Test', presetFontSizes: [5, 50]),
    );
    expect(tester.takeException(), isAssertionError);
  });
}
