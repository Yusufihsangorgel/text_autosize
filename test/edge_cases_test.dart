import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:text_autosize/text_autosize.dart';

import 'utils.dart';

void main() {
  testWidgets('handles empty text', (tester) async {
    // An empty text still occupies one line of height, so the box has to be
    // one line high for the default font size to fit.
    await pumpAndExpectFontSize(
      tester: tester,
      expectedFontSize: 14,
      widget: const SizedBox(width: 10, height: 50, child: AutoSizeText('')),
    );
  });

  testWidgets('shrinks empty text when the line height does not fit', (
    tester,
  ) async {
    await pumpAndExpectFontSize(
      tester: tester,
      expectedFontSize: 8,
      widget: const SizedBox(
        width: 10,
        height: 8,
        child: AutoSizeText('', minFontSize: 1),
      ),
    );
  });

  testWidgets('keeps the preferred size under unbounded width constraints', (
    tester,
  ) async {
    await pumpAndExpectFontSize(
      tester: tester,
      expectedFontSize: 30,
      widget: const UnconstrainedBox(
        child: AutoSizeText(
          'XXXXX',
          style: TextStyle(fontSize: 30),
          maxLines: 1,
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps the preferred size under unbounded height constraints', (
    tester,
  ) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: const MediaQueryData(),
          child: ListView(
            children: const [
              AutoSizeText('XXXXX XXXXX XXXXX', style: TextStyle(fontSize: 30)),
            ],
          ),
        ),
      ),
    );
    final text = tester.widget<Text>(find.byType(Text));
    expect(effectiveFontSize(text), 30);
    expect(tester.takeException(), isNull);
  });

  testWidgets('works inside a SelectionArea', (tester) async {
    SelectedContent? selectedContent;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SelectionArea(
            onSelectionChanged: (content) => selectedContent = content,
            child: const Center(child: AutoSizeText('Hello world')),
          ),
        ),
      ),
    );

    // Long press selects the word under the pointer, which proves that the
    // Text built by AutoSizeText registers with the enclosing SelectionArea.
    await tester.longPressAt(
      tester.getTopLeft(find.text('Hello world')) + const Offset(5, 5),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(selectedContent?.plainText, 'Hello');
  });
}
