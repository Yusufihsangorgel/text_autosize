import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:text_autosize/text_autosize.dart';

import 'utils.dart';

void main() {
  testWidgets('overflow replacement is visible on overflow', (tester) async {
    final text = await pumpAndGetText(
      tester: tester,
      widget: const SizedBox(
        width: 100,
        height: 20,
        child: AutoSizeText(
          'XXXXXX',
          overflowReplacement: Text('OVERFLOW!'),
          minFontSize: 20,
        ),
      ),
    );
    expect(text.data, 'OVERFLOW!');
  });

  testWidgets('overflow replacement is not visible without overflow', (
    tester,
  ) async {
    final text = await pumpAndGetText(
      tester: tester,
      widget: const SizedBox(
        width: 100,
        height: 20,
        child: AutoSizeText(
          'XXXXX',
          style: TextStyle(fontSize: 20),
          overflowReplacement: Text('OVERFLOW!'),
        ),
      ),
    );
    expect(text.data, 'XXXXX');
  });
}
