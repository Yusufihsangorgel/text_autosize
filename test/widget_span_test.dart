import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:text_autosize/text_autosize.dart';

Finder _autoSizeText() => find.byType(AutoSizeText);

Finder _innerText() =>
    find.descendant(of: _autoSizeText(), matching: find.byType(Text));

/// The [RenderParagraph] that laid out the [AutoSizeText] span, not an
/// [Icon]'s inner [RichText].
RenderParagraph _spanParagraph(WidgetTester tester) {
  final fitted = tester.renderObject(find.byType(FittedBox).first);
  RenderObject? node = fitted.parent;
  while (node != null && node is! RenderParagraph) {
    node = node.parent;
  }
  return node! as RenderParagraph;
}

/// Visual size of the root style, after the inner [Text]'s scaler.
double _visualEm(WidgetTester tester) {
  final text = tester.widget<Text>(_innerText());
  return text.textScaler!.scale(text.style!.fontSize!);
}

/// Sizes of the inline widgets after Flutter's widget-span scaler.
///
/// That scaler is what occupies the line. Reading the inner [SizedBox]
/// width instead would miss a double-shrink: the box is in the span's
/// logical coordinates, then scaled again.
List<Size> _placeholderPaintSizes(WidgetTester tester) {
  final sizes = <Size>[];
  _spanParagraph(tester).visitChildren((child) {
    sizes.add((child as RenderBox).size);
  });
  return sizes;
}

Widget _host({
  required double width,
  double height = 60,
  required InlineSpan span,
  Size Function(WidgetSpan, double)? placeholderSize,
  int? maxLines = 1,
  TextStyle style = const TextStyle(fontSize: 40),
  TextScaler? textScaler,
  bool tight = true,
}) {
  final child = AutoSizeText.rich(
    span as TextSpan,
    maxLines: maxLines,
    minFontSize: 4,
    stepGranularity: 1,
    style: style,
    placeholderSize: placeholderSize,
    textScaler: textScaler,
  );
  final boxed = tight
      ? SizedBox(width: width, height: height, child: child)
      : ConstrainedBox(
          constraints: BoxConstraints(maxWidth: width, maxHeight: height),
          child: child,
        );
  return MaterialApp(
    home: Scaffold(body: Center(child: boxed)),
  );
}

const _rich = TextSpan(
  children: [
    TextSpan(text: 'ab '),
    WidgetSpan(child: Icon(Icons.star, size: 24)),
    TextSpan(text: ' cd'),
  ],
);

void main() {
  testWidgets('a WidgetSpan lays out instead of throwing', (tester) async {
    await tester.pumpWidget(_host(width: 200, span: _rich));
    expect(tester.takeException(), isNull);
    expect(find.byIcon(Icons.star), findsOneWidget);
  });

  testWidgets('a WidgetSpan rich text fits the given bounds', (tester) async {
    const width = 100.0;
    const height = 40.0;
    await tester.pumpWidget(
      _host(width: width, height: height, span: _rich, tight: false),
    );

    final paragraph = _spanParagraph(tester);
    expect(paragraph.didExceedMaxLines, isFalse);
    expect(paragraph.size.width, lessThanOrEqualTo(width + 0.001));
    expect(paragraph.size.height, lessThanOrEqualTo(height + 0.001));
  });

  testWidgets('the fitted size responds to the constraint', (tester) async {
    await tester.pumpWidget(_host(width: 300, span: _rich, tight: false));
    final roomy = _visualEm(tester);

    await tester.pumpWidget(_host(width: 90, span: _rich, tight: false));
    final tight = _visualEm(tester);

    expect(roomy, 40);
    expect(tight, lessThan(roomy));
    expect(tight, greaterThanOrEqualTo(4));
  });

  testWidgets('the placeholder counts against the width', (tester) async {
    // Same text, same box: the version carrying an icon has less room for
    // glyphs, so it has to settle smaller. If the placeholder were measured
    // as zero-width the two would agree.
    await tester.pumpWidget(_host(width: 120, span: _rich));
    final withIcon = _visualEm(tester);

    await tester.pumpWidget(
      _host(
        width: 120,
        span: const TextSpan(children: [TextSpan(text: 'ab  cd')]),
      ),
    );
    final withoutIcon = _visualEm(tester);

    expect(withIcon, lessThan(withoutIcon));
  });

  testWidgets('a wider placeholder forces a smaller font', (tester) async {
    await tester.pumpWidget(_host(width: 120, span: _rich));
    final square = _visualEm(tester);

    await tester.pumpWidget(
      _host(
        width: 120,
        span: _rich,
        placeholderSize: (span, fontSize) => Size(fontSize * 4, fontSize),
      ),
    );
    final wide = _visualEm(tester);

    expect(wide, lessThan(square));
  });

  testWidgets('the painted placeholder is one visual em', (tester) async {
    await tester.pumpWidget(_host(width: 140, span: _rich));
    final em = _visualEm(tester);
    expect(em, lessThan(40));

    final painted = _placeholderPaintSizes(tester).single;
    expect(painted.width, closeTo(em, 0.001));
    expect(painted.height, closeTo(em, 0.001));
  });

  testWidgets('the placeholder shrinks with the text', (tester) async {
    await tester.pumpWidget(_host(width: 300, span: _rich));
    final roomy = _placeholderPaintSizes(tester).single.width;

    await tester.pumpWidget(_host(width: 90, span: _rich));
    final tight = _placeholderPaintSizes(tester).single.width;

    expect(tight, lessThan(roomy));
    expect(tight, closeTo(_visualEm(tester), 0.001));
  });

  testWidgets('the chosen size does not depend on the base style', (
    tester,
  ) async {
    // Placeholders live in the span's logical font-size coordinates and are
    // scaled by the same ratio as the glyphs. Measuring them at the base
    // style without that ratio would make a span declared at 40 shrink
    // further than the same span declared at 20.
    Future<double> chosenWith(double base) async {
      await tester.pumpWidget(
        _host(
          width: 110,
          span: _rich,
          style: TextStyle(fontSize: base),
        ),
      );
      return _visualEm(tester);
    }

    expect(await chosenWith(40), closeTo(await chosenWith(20), 0.001));
  });

  testWidgets('the child is fitted into the measured box', (tester) async {
    await tester.pumpWidget(_host(width: 110, span: _rich));
    final em = _visualEm(tester);
    expect(em, lessThan(24));

    final fitted = find.ancestor(
      of: find.byIcon(Icons.star),
      matching: find.byType(FittedBox),
    );
    expect(fitted, findsOneWidget);
    expect(tester.widget<FittedBox>(fitted.first).fit, BoxFit.contain);

    final painted = _placeholderPaintSizes(tester).single;
    expect(painted.width, closeTo(em, 0.001));
    expect(painted.height, closeTo(em, 0.001));
  });

  testWidgets(
    'the child intrinsic size is ignored: an 80 px child occupies one em',
    (tester) async {
      const bulky = TextSpan(
        children: [
          TextSpan(text: 'ab '),
          WidgetSpan(
            child: SizedBox(
              width: 80,
              height: 80,
              child: ColoredBox(color: Color(0xFFFF0000)),
            ),
          ),
          TextSpan(text: ' cd'),
        ],
      );

      await tester.pumpWidget(_host(width: 140, span: bulky));
      final em = _visualEm(tester);
      expect(em, lessThan(80));

      final painted = _placeholderPaintSizes(tester).single;
      expect(painted.width, closeTo(em, 0.001));
      expect(painted.height, closeTo(em, 0.001));
      expect(painted.width, isNot(closeTo(80, 0.5)));
    },
  );

  testWidgets('placeholderSize is honoured in the painted geometry', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        width: 200,
        span: _rich,
        placeholderSize: (span, fontSize) => Size(fontSize * 3, fontSize),
      ),
    );
    final em = _visualEm(tester);
    final painted = _placeholderPaintSizes(tester).single;
    expect(painted.width, closeTo(em * 3, 0.001));
    expect(painted.height, closeTo(em, 0.001));
  });

  testWidgets('the placeholder tracks the scaled em, not the logical one', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        width: 300,
        span: _rich,
        style: const TextStyle(fontSize: 20),
        textScaler: const TextScaler.linear(2),
      ),
    );

    // Plenty of width, so the logical size stays 20 and the glyphs paint at 40.
    expect(_visualEm(tester), 40);
    final painted = _placeholderPaintSizes(tester).single;
    expect(painted.width, closeTo(40, 0.001));
    expect(painted.height, closeTo(40, 0.001));
  });

  testWidgets('shrinking under a text scaler still keeps one visual em', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(width: 110, span: _rich, textScaler: const TextScaler.linear(2)),
    );

    final em = _visualEm(tester);
    expect(em, lessThan(80));
    final painted = _placeholderPaintSizes(tester).single;
    expect(painted.width, closeTo(em, 0.001));
    expect(painted.height, closeTo(em, 0.001));
  });

  testWidgets('a WidgetSpan inside a larger span gets that span\'s em', (
    tester,
  ) async {
    const nested = TextSpan(
      children: [
        TextSpan(text: 'a '),
        TextSpan(
          style: TextStyle(fontSize: 80),
          children: [WidgetSpan(child: Icon(Icons.star, size: 24))],
        ),
        TextSpan(text: ' b'),
      ],
    );

    await tester.pumpWidget(
      _host(
        width: 400,
        height: 200,
        span: nested,
        style: const TextStyle(fontSize: 20),
      ),
    );

    // Root stays at 20; the inner span is 4×, so the placeholder is 80.
    expect(_visualEm(tester), 20);
    final painted = _placeholderPaintSizes(tester).single;
    expect(painted.width, closeTo(80, 0.001));
    expect(painted.height, closeTo(80, 0.001));
  });

  testWidgets('two WidgetSpans each occupy one em', (tester) async {
    const two = TextSpan(
      children: [
        WidgetSpan(child: Icon(Icons.star, size: 24)),
        TextSpan(text: ' x '),
        WidgetSpan(child: Icon(Icons.bolt, size: 24)),
      ],
    );

    await tester.pumpWidget(_host(width: 200, span: two));
    final em = _visualEm(tester);
    final painted = _placeholderPaintSizes(tester);
    expect(painted, hasLength(2));
    expect(painted[0].width, closeTo(em, 0.001));
    expect(painted[1].width, closeTo(em, 0.001));
  });

  testWidgets('plain rich text is untouched by any of this', (tester) async {
    const span = TextSpan(
      children: [
        TextSpan(text: 'ab '),
        TextSpan(
          text: 'cd',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
    await tester.pumpWidget(_host(width: 120, span: span));
    expect(tester.takeException(), isNull);
    expect(find.byType(Icon), findsNothing);

    final richText = find.descendant(
      of: _autoSizeText(),
      matching: find.byType(RichText),
    );
    expect(richText, findsOneWidget);
    final root = tester.widget<RichText>(richText).text as TextSpan;
    expect(root.children!.single, same(span));
  });
}
