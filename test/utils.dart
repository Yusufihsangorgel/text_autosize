import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The font size at which a [Text] built by AutoSizeText actually renders.
///
/// AutoSizeText always passes an explicit [TextScaler] to the [Text] it
/// builds, so the effective size is the scaled style font size.
double effectiveFontSize(Text text) {
  final scaler = text.textScaler ?? TextScaler.noScaling;
  return scaler.scale(text.style!.fontSize!);
}

Future<void> pump({
  required WidgetTester tester,
  required Widget widget,
}) async {
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: Center(child: widget),
    ),
  );
}

Future<Text> pumpAndGetText({
  required WidgetTester tester,
  required Widget widget,
}) async {
  await pump(tester: tester, widget: widget);
  return tester.widget<Text>(find.byType(Text));
}

Future<void> pumpAndExpectFontSize({
  required WidgetTester tester,
  required double expectedFontSize,
  required Widget widget,
}) async {
  final text = await pumpAndGetText(tester: tester, widget: widget);
  expect(effectiveFontSize(text), expectedFontSize);
}

RichText getRichText(WidgetTester tester) =>
    tester.widget(find.byType(RichText));
