import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:text_autosize/text_autosize.dart';

import 'utils.dart';

void main() {
  testWidgets('respects maxLines', (tester) async {
    await pump(
      tester: tester,
      widget: const AutoSizeText(
        'XXXXX',
        style: TextStyle(fontSize: 27),
        maxLines: 1,
      ),
    );
    var height = tester.getSize(find.byType(RichText)).height;
    expect(height, 27);

    await pump(
      tester: tester,
      widget: const SizedBox(
        width: 75,
        child: AutoSizeText(
          'XXX XXX',
          style: TextStyle(fontSize: 25),
          maxLines: 2,
        ),
      ),
    );
    height = tester.getSize(find.byType(RichText)).height;
    expect(height, 50);
  });

  testWidgets('takes maxLines from DefaultTextStyle when parameter is null', (
    tester,
  ) async {
    await pumpAndExpectFontSize(
      tester: tester,
      expectedFontSize: 9,
      widget: const DefaultTextStyle(
        style: TextStyle(fontSize: 20),
        maxLines: 1,
        child: SizedBox(
          width: 99,
          child: AutoSizeText('XXXXX XXXXX', minFontSize: 1),
        ),
      ),
    );
  });
}
