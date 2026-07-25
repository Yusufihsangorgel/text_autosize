import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:text_autosize/text_autosize.dart';

import 'utils.dart';

void main() {
  _degenerateBaseFontSizeTests();
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
    // The callback type is inferred to avoid naming SelectedContent, which
    // has moved between libraries across Flutter releases.
    String? selectedText;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SelectionArea(
            onSelectionChanged: (content) => selectedText = content?.plainText,
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
    expect(selectedText, 'Hello');
  });
}

void _degenerateBaseFontSizeTests() {
  group('a degenerate base font size', () {
    // A zero base made the fit probes scale the span by fontSize / 0, laying
    // out NaN-sized text that every fit check accepted, which then wedged a
    // later, ordinary layout. Plain Text renders these styles without
    // complaint, so AutoSizeText has to as well.
    // NaN is deliberately absent: a plain Text asserts on it inside Flutter's
    // own widget_span, so matching Text means throwing there too.
    //
    // Which sizes a plain Text accepts is not fixed across Flutter versions:
    // 3.32.0 asserts `fontSize >= 0` inside TextScaler, and later releases
    // render a negative size without complaint. Rather than pin a list per
    // version, each case renders a plain Text with the same style first and
    // holds AutoSizeText to whatever that did. The contract is parity with
    // Text, so the control is the specification.
    for (final base in <double>[0, -4, double.infinity]) {
      testWidgets('$base renders and does not wedge a later layout', (
        tester,
      ) async {
        Widget framed(Widget child) => MaterialApp(
          home: Scaffold(body: SizedBox(width: 130, height: 60, child: child)),
        );

        // What a plain Text does with this style on this Flutter version.
        await tester.pumpWidget(
          framed(Text('hello', style: TextStyle(fontSize: base))),
        );
        final plainThrew = tester.takeException() != null;

        await tester.pumpWidget(
          framed(AutoSizeText('hello', style: TextStyle(fontSize: base))),
        );
        expect(
          tester.takeException() != null,
          plainThrew,
          reason: plainThrew
              ? 'a plain Text rejects fontSize $base here, so AutoSizeText '
                    'must reject it too'
              : 'a plain Text renders fontSize $base here, so AutoSizeText '
                    'must render it too',
        );
        if (plainThrew) return; // nothing wedged; Flutter refused it up front

        // The layout that used to hang: an ordinary AutoSizeText pumped after
        // the degenerate one.
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 130,
                height: 60,
                child: AutoSizeText(
                  'hello again',
                  style: const TextStyle(fontSize: 12),
                  minFontSize: 4,
                ),
              ),
            ),
          ),
        );
        expect(tester.takeException(), isNull);
        expect(find.text('hello again'), findsOneWidget);
      });
    }

    testWidgets('a zero base on the rich constructor also survives', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 130,
              height: 60,
              child: AutoSizeText.rich(
                TextSpan(text: 'rich'),
                style: TextStyle(fontSize: 0),
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });
}
