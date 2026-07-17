import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:text_autosize/text_autosize.dart';

import 'utils.dart';

void main() {
  testWidgets('only steps in multiples of stepGranularity', (tester) async {
    // 'XXXXX' at font size k is 5 * k wide. In a 130 wide box the largest
    // fitting size is 26, but with a granularity of 10 the widget has to
    // settle for 20.
    await pumpAndExpectFontSize(
      tester: tester,
      expectedFontSize: 20,
      widget: const SizedBox(
        width: 130,
        child: AutoSizeText(
          'XXXXX',
          style: TextStyle(fontSize: 40),
          maxLines: 1,
          minFontSize: 10,
          stepGranularity: 10,
        ),
      ),
    );
  });

  testWidgets('supports fractional stepGranularity', (tester) async {
    // The largest fitting size in a 102 wide box is 20.4, which is a
    // multiple of 0.2. The comparison needs a tolerance because the size is
    // the product of the step count and the granularity, computed in binary
    // floating point.
    final text = await pumpAndGetText(
      tester: tester,
      widget: const SizedBox(
        width: 102,
        child: AutoSizeText(
          'XXXXX',
          style: TextStyle(fontSize: 40),
          maxLines: 1,
          minFontSize: 10,
          stepGranularity: 0.2,
        ),
      ),
    );
    expect(effectiveFontSize(text), moreOrLessEquals(20.4));
  });

  testWidgets('rejects minFontSize that is not a multiple of stepGranularity', (
    tester,
  ) async {
    await tester.pumpWidget(
      const AutoSizeText(
        'AutoSizeText Test',
        minFontSize: 5,
        stepGranularity: 2,
      ),
    );
    expect(tester.takeException(), isAssertionError);
  });
}
