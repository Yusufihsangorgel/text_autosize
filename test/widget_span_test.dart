import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:text_autosize/text_autosize.dart';

/// The font size the widget settled on, read off the `Text` it built.
double _renderedFontSize(WidgetTester tester) {
  final text = tester.widget<Text>(find.byType(Text));
  return text.textScaler!.scale(text.style?.fontSize ?? 14);
}

Widget _host({
  required double width,
  required InlineSpan span,
  Size Function(WidgetSpan, double)? placeholderSize,
  int? maxLines = 1,
}) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: width,
          height: 60,
          child: AutoSizeText.rich(
            span as TextSpan,
            maxLines: maxLines,
            minFontSize: 4,
            stepGranularity: 1,
            style: const TextStyle(fontSize: 40),
            placeholderSize: placeholderSize,
          ),
        ),
      ),
    ),
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

  testWidgets('the placeholder counts against the width', (tester) async {
    // Same text, same box: the version carrying an icon has less room for
    // glyphs, so it has to settle smaller. If the placeholder were measured as
    // zero-width the two would agree.
    await tester.pumpWidget(_host(width: 120, span: _rich));
    final withIcon = _renderedFontSize(tester);

    await tester.pumpWidget(
      _host(
        width: 120,
        span: const TextSpan(children: [TextSpan(text: 'ab  cd')]),
      ),
    );
    final withoutIcon = _renderedFontSize(tester);

    expect(withIcon, lessThan(withoutIcon));
  });

  testWidgets('a wider placeholder forces a smaller font', (tester) async {
    await tester.pumpWidget(_host(width: 120, span: _rich));
    final square = _renderedFontSize(tester);

    await tester.pumpWidget(
      _host(
        width: 120,
        span: _rich,
        placeholderSize: (span, fontSize) => Size(fontSize * 4, fontSize),
      ),
    );
    final wide = _renderedFontSize(tester);

    expect(wide, lessThan(square));
  });

  testWidgets('the box on screen is the box that was measured', (tester) async {
    await tester.pumpWidget(_host(width: 140, span: _rich));
    final fontSize = _renderedFontSize(tester);

    // The icon is painted into a SizedBox of exactly the measured square, so
    // the fit the probes found is the fit on screen.
    final box = tester.widget<SizedBox>(
      find
          .ancestor(
            of: find.byIcon(Icons.star),
            matching: find.byType(SizedBox),
          )
          .first,
    );
    expect(box.width, closeTo(fontSize, 0.001));
    expect(box.height, closeTo(fontSize, 0.001));
  });

  testWidgets('the placeholder shrinks with the text', (tester) async {
    await tester.pumpWidget(_host(width: 300, span: _rich));
    final roomy = tester
        .widget<SizedBox>(
          find
              .ancestor(
                of: find.byIcon(Icons.star),
                matching: find.byType(SizedBox),
              )
              .first,
        )
        .width!;

    await tester.pumpWidget(_host(width: 90, span: _rich));
    final tight = tester
        .widget<SizedBox>(
          find
              .ancestor(
                of: find.byIcon(Icons.star),
                matching: find.byType(SizedBox),
              )
              .first,
        )
        .width!;

    expect(tight, lessThan(roomy));
  });

  testWidgets('the chosen size does not depend on the base style', (
    tester,
  ) async {
    // The probes measure the placeholder at the size they are testing, not at
    // the style's size. Measuring at the base instead would make a span
    // declared at 40 shrink further than the same span declared at 20, because
    // the placeholder would be measured three times too wide on the way down.
    Future<double> chosenWith(double base) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 110,
                height: 60,
                child: AutoSizeText.rich(
                  _rich,
                  maxLines: 1,
                  minFontSize: 4,
                  stepGranularity: 1,
                  style: TextStyle(fontSize: base),
                ),
              ),
            ),
          ),
        ),
      );
      return _renderedFontSize(tester);
    }

    expect(await chosenWith(40), closeTo(await chosenWith(20), 0.001));
  });

  testWidgets('the child is scaled into the measured box', (tester) async {
    await tester.pumpWidget(_host(width: 110, span: _rich));
    final fontSize = _renderedFontSize(tester);

    // The icon asks for 24 logical pixels. The box it was measured into is the
    // font size, which is smaller here, and a FittedBox is what makes the two
    // agree on screen instead of letting the icon paint past its placeholder.
    expect(fontSize, lessThan(24));
    final fitted = find.ancestor(
      of: find.byIcon(Icons.star),
      matching: find.byType(FittedBox),
    );
    expect(fitted, findsOneWidget);
    expect(tester.widget<FittedBox>(fitted.first).fit, BoxFit.contain);
    expect(tester.getSize(fitted.first).width, closeTo(fontSize, 0.001));
  });

  testWidgets('plain rich text is untouched by any of this', (tester) async {
    await tester.pumpWidget(
      _host(
        width: 120,
        span: const TextSpan(
          children: [
            TextSpan(text: 'ab '),
            TextSpan(
              text: 'cd',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    // No placeholder in the tree means no SizedBox wrapper was introduced.
    expect(find.byType(Icon), findsNothing);
  });
}
