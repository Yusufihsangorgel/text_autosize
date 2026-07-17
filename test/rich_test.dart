import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:text_autosize/text_autosize.dart';

import 'utils.dart';

void main() {
  testWidgets('rich text shrinks to fit', (tester) async {
    await pumpAndExpectFontSize(
      tester: tester,
      expectedFontSize: 20,
      widget: const SizedBox(
        width: 100,
        child: AutoSizeText.rich(
          TextSpan(text: 'XXXXX'),
          style: TextStyle(fontSize: 60),
          maxLines: 1,
        ),
      ),
    );
  });

  testWidgets('rich text scales all spans proportionally', (tester) async {
    await pump(
      tester: tester,
      widget: const SizedBox(
        width: 60,
        child: AutoSizeText.rich(
          TextSpan(
            children: [
              TextSpan(text: 'XX', style: TextStyle(fontSize: 20)),
              TextSpan(text: 'XX', style: TextStyle(fontSize: 40)),
            ],
          ),
          style: TextStyle(fontSize: 20),
          maxLines: 1,
          minFontSize: 1,
        ),
      ),
    );

    // The span is 120 logical pixels wide at full size, so it has to be
    // scaled by 0.5 to fit the 60 pixel box. Both spans keep their ratio.
    final richText = getRichText(tester);
    expect(richText.textScaler.scale(20), 10);
    expect(richText.textScaler.scale(40), 20);
    expect(tester.getSize(find.byType(RichText)).width, 60);
  });

  testWidgets('rich text keeps the original span instance', (tester) async {
    const span = TextSpan(text: 'XXXXX');
    await pump(
      tester: tester,
      widget: const SizedBox(
        width: 100,
        child: AutoSizeText.rich(
          span,
          style: TextStyle(fontSize: 60),
          maxLines: 1,
        ),
      ),
    );

    // Text.rich wraps the given span instead of copying it, so gesture
    // recognizers and nested spans survive the resizing.
    final root = getRichText(tester).text as TextSpan;
    expect(root.children!.single, same(span));
  });

  testWidgets('rich text respects minFontSize', (tester) async {
    await pumpAndExpectFontSize(
      tester: tester,
      expectedFontSize: 15,
      widget: const SizedBox(
        width: 10,
        height: 10,
        child: AutoSizeText.rich(
          TextSpan(text: 'AutoSizeText Test'),
          style: TextStyle(fontSize: 25),
          minFontSize: 15,
        ),
      ),
    );
  });
}
