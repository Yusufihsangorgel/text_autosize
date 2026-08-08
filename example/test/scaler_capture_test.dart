// Renders TextScalerPanel to the still image used in the README, and prints
// the fitted sizes both sides settle on. Not part of any regular suite; run it
// from the example directory with:
//
//   flutter test --tags demo test/scaler_capture_test.dart
//
// It writes <system temp>/text_autosize_scaler/scaler.png and prints the path.
// Copy that over doc/scaler.png to update the README image.
@Tags(['demo'])
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:text_autosize_example/main.dart';

const _captureKey = ValueKey('scaler-capture');

void main() {
  testWidgets('captures the TextScaler panel', (tester) async {
    tester.view.physicalSize = const Size(1000, 1040);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await _loadRealFonts(tester);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorSchemeSeed: const Color(0xFF3F51B5),
          fontFamily: 'Roboto',
        ),
        home: Scaffold(
          // A scroll view for the same reason the demo app uses a ListView:
          // it leaves the panel's height unbounded, so the captured boundary
          // is exactly as tall as the panel and no taller.
          body: SingleChildScrollView(
            child: RepaintBoundary(
              key: _captureKey,
              // toImage renders only this subtree, so the Scaffold's
              // background is not part of the capture. Paint one here, or the
              // image gets a transparent background and the dark text
              // disappears against a dark page.
              child: const ColoredBox(
                color: Colors.white,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  // The scale the panel starts at for the still image. 2.0 is
                  // the top of the slider, where the sides differ most.
                  child: TextScalerPanel(initialScale: 2),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    // The panel reads the fitted sizes back after the first frame, so the
    // readouts are only on screen from the second one.
    await tester.pump();

    for (final text in tester.widgetList<Text>(find.byType(Text))) {
      final data = text.data;
      if (data != null && data.startsWith('fits ')) {
        // ignore: avoid_print
        print('readout: $data');
      }
    }

    final dir = Directory('${Directory.systemTemp.path}/text_autosize_scaler');
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    final file = File('${dir.path}/scaler.png');
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(_captureKey),
    );
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2);
      try {
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        await file.writeAsBytes(data!.buffer.asUint8List());
      } finally {
        image.dispose();
      }
    });
    // ignore: avoid_print
    print('wrote ${file.path}');
  });
}

/// The default test font draws every glyph as a box; load the SDK's bundled
/// Roboto so the capture looks like a real app.
Future<void> _loadRealFonts(WidgetTester tester) async {
  await tester.runAsync(() async {
    final fonts = _materialFontsDir();
    Future<ByteData> read(String name) async =>
        ByteData.sublistView(await File('${fonts.path}/$name').readAsBytes());
    final roboto = FontLoader('Roboto')
      ..addFont(read('Roboto-Regular.ttf'))
      ..addFont(read('Roboto-Medium.ttf'))
      ..addFont(read('Roboto-Bold.ttf'));
    await roboto.load();
  });
}

Directory _materialFontsDir() {
  var dir = File(Platform.resolvedExecutable).parent;
  while (true) {
    final fonts = Directory('${dir.path}/bin/cache/artifacts/material_fonts');
    if (fonts.existsSync()) {
      return fonts;
    }
    final parent = dir.parent;
    if (parent.path == dir.path) {
      throw StateError('material_fonts not found above $dir');
    }
    dir = parent;
  }
}
