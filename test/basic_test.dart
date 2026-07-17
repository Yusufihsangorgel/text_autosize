import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:text_autosize/text_autosize.dart';

import 'utils.dart';

void main() {
  testWidgets('only text', (tester) async {
    await pump(tester: tester, widget: const AutoSizeText('Some Text'));
  });

  testWidgets('only text (rich)', (tester) async {
    await pump(
      tester: tester,
      widget: const AutoSizeText.rich(TextSpan(text: 'Some Text')),
    );
  });

  testWidgets('uses style fontSize', (tester) async {
    await pumpAndExpectFontSize(
      tester: tester,
      expectedFontSize: 34,
      widget: const AutoSizeText('Some Text', style: TextStyle(fontSize: 34)),
    );
  });

  testWidgets('uses style fontSize (rich)', (tester) async {
    await pumpAndExpectFontSize(
      tester: tester,
      expectedFontSize: 35,
      widget: const AutoSizeText.rich(
        TextSpan(text: 'Some Text'),
        style: TextStyle(fontSize: 35),
      ),
    );
  });

  testWidgets('shrinks the font size when the box is narrow', (tester) async {
    final text = await pumpAndGetText(
      tester: tester,
      widget: const SizedBox(
        width: 100,
        child: AutoSizeText(
          'XXXXXXXXXX',
          style: TextStyle(fontSize: 40),
          maxLines: 1,
          minFontSize: 1,
        ),
      ),
    );
    expect(text.style!.fontSize!, lessThan(40));
    expect(effectiveFontSize(text), 10);
  });

  testWidgets('respects inherited style and DefaultTextStyle', (tester) async {
    const defaultStyle = TextStyle(fontSize: 20, color: Colors.yellow);
    final text = await pumpAndGetText(
      tester: tester,
      widget: const DefaultTextStyle(
        style: defaultStyle,
        textAlign: TextAlign.right,
        softWrap: false,
        overflow: TextOverflow.ellipsis,
        maxLines: 17,
        child: AutoSizeText('AutoSizeText Test'),
      ),
    );
    expect(text.style, defaultStyle);

    final richText = getRichText(tester);
    expect(richText.textAlign, TextAlign.right);
    expect(richText.softWrap, false);
    expect(richText.overflow, TextOverflow.ellipsis);
    expect(richText.maxLines, 17);
  });

  testWidgets('applies scale even if the initial fontSize fits', (
    tester,
  ) async {
    await pumpAndExpectFontSize(
      tester: tester,
      expectedFontSize: 60,
      widget: const AutoSizeText(
        'Some Text',
        style: TextStyle(fontSize: 15),
        textScaler: TextScaler.linear(4),
      ),
    );
  });

  testWidgets('uses textKey', (tester) async {
    final textKey = GlobalKey();
    final text = await pumpAndGetText(
      tester: tester,
      widget: AutoSizeText('A text with key', textKey: textKey),
    );
    expect(text.key, textKey);
  });

  testWidgets('passes textWidthBasis, textHeightBehavior and selectionColor '
      'through to the built Text', (tester) async {
    const heightBehavior = TextHeightBehavior(applyHeightToFirstAscent: false);
    const selectionColor = Color(0xFF123456);
    final text = await pumpAndGetText(
      tester: tester,
      widget: const AutoSizeText(
        'Some Text',
        textWidthBasis: TextWidthBasis.longestLine,
        textHeightBehavior: heightBehavior,
        selectionColor: selectionColor,
      ),
    );
    expect(text.textWidthBasis, TextWidthBasis.longestLine);
    expect(text.textHeightBehavior, heightBehavior);
    expect(text.selectionColor, selectionColor);
  });
}
