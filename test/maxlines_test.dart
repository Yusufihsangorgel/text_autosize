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

  testWidgets('an explicit maxLines wins over DefaultTextStyle', (
    tester,
  ) async {
    // The mirror of the test above, and the direction Flutter's own Text
    // takes: maxLines ?? defaultTextStyle.maxLines. Without it the two could
    // be swapped and only the fallback case would notice.
    //
    // maxLines: 1 in a 99px box shrinks the text to 9; deferring to the
    // ambient 5 would leave it at its natural size.
    await pumpAndExpectFontSize(
      tester: tester,
      expectedFontSize: 9,
      widget: const DefaultTextStyle(
        style: TextStyle(fontSize: 20),
        maxLines: 5,
        child: SizedBox(
          width: 99,
          child: AutoSizeText('XXXXX XXXXX', maxLines: 1, minFontSize: 1),
        ),
      ),
    );
  });
}
