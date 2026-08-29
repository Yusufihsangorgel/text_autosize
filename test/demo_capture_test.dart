// Captures the frames for doc/demo.gif. Not part of the regular test
// suite; run explicitly with:
//
//   flutter test --tags demo test/demo_capture_test.dart
//
// Frames are written to /tmp/demo_text_autosize/frame_NNN.png and
// assembled with ffmpeg (see doc/demo.gif in the README).
@Tags(['demo'])
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:text_autosize/text_autosize.dart';

const _captureKey = ValueKey('demo-capture');
final _frameDir = Directory('/tmp/demo_text_autosize');
int _frameIndex = 0;

const _headlineWords = [
  'Live',
  'metrics',
  'dashboard',
  'for',
  'your',
  'Flutter',
  'apps,',
  'updating',
  'in',
  'real',
  'time',
  'without',
  'dropping',
  'frames',
];

const _groupWords = [
  'Q3',
  'revenue',
  'report',
  'for',
  'the',
  'EMEA',
  'region,',
  'including',
  'renewals',
  'and churn',
];

void main() {
  testWidgets('captures autosize demo frames', (tester) async {
    if (_frameDir.existsSync()) _frameDir.deleteSync(recursive: true);
    _frameDir.createSync(recursive: true);

    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);
    await _loadRealFonts(tester);

    final step = ValueNotifier(0);
    addTearDown(step.dispose);
    await tester.pumpWidget(_DemoApp(step: step));

    // Steps 0-13 grow the headline word by word inside a fixed box; the
    // font steps down as it fills. Steps 14-23 grow the right-hand group
    // member; both group members shrink in sync.
    for (var i = 0; i < 24; i++) {
      step.value = i;
      // One frame for the text change, one for the group's deferred
      // synchronization pass.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      await _capture(tester);
    }
  });
}

/// The default test font renders every glyph as a box; load the SDK's
/// bundled Roboto and MaterialIcons so the captures look like a real app.
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
    final icons = FontLoader('MaterialIcons')
      ..addFont(read('MaterialIcons-Regular.otf'));
    await icons.load();
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

Future<void> _capture(WidgetTester tester) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_captureKey),
  );
  final name = 'frame_${'$_frameIndex'.padLeft(3, '0')}.png';
  _frameIndex++;
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      await File(
        '${_frameDir.path}/$name',
      ).writeAsBytes(data!.buffer.asUint8List());
    } finally {
      image.dispose();
    }
  });
}

class _DemoApp extends StatelessWidget {
  const _DemoApp({required this.step});

  final ValueNotifier<int> step;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: _captureKey,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorSchemeSeed: const Color(0xFF0EA5E9),
          fontFamily: 'Roboto',
        ),
        home: Scaffold(
          appBar: AppBar(title: const Text('text_autosize demo')),
          body: ValueListenableBuilder(
            valueListenable: step,
            builder: (context, value, _) => _DemoBody(step: value),
          ),
        ),
      ),
    );
  }
}

class _DemoBody extends StatefulWidget {
  const _DemoBody({required this.step});

  final int step;

  @override
  State<_DemoBody> createState() => _DemoBodyState();
}

class _DemoBodyState extends State<_DemoBody> {
  final AutoSizeGroup _group = AutoSizeGroup();

  String _take(List<String> words, int count) =>
      words.take(count.clamp(1, words.length)).join(' ');

  @override
  Widget build(BuildContext context) {
    final headline = _take(_headlineWords, widget.step + 1);
    final groupText = _take(_groupWords, widget.step - 13);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            title: 'AutoSizeText',
            subtitle: 'The font steps down as the text grows',
          ),
          const SizedBox(height: 10),
          _DemoBox(
            width: double.infinity,
            height: 130,
            child: AutoSizeText(
              headline,
              style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w600),
              maxLines: 2,
              minFontSize: 10,
            ),
          ),
          const SizedBox(height: 28),
          _CardHeader(
            title: 'AutoSizeGroup',
            subtitle:
                'One group, one font size: the most constrained '
                'member sets it for everyone',
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _DemoBox(
                  height: 96,
                  child: AutoSizeText(
                    'Revenue overview',
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    minFontSize: 8,
                    group: _group,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _DemoBox(
                  height: 96,
                  child: AutoSizeText(
                    groupText,
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    minFontSize: 8,
                    group: _group,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CardHeader extends StatelessWidget {
  const _CardHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.primary,
          ),
        ),
        Text(subtitle, style: theme.textTheme.bodySmall),
      ],
    );
  }
}

class _DemoBox extends StatelessWidget {
  const _DemoBox({required this.child, this.width, this.height});

  final Widget child;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Align(alignment: Alignment.centerLeft, child: child),
    );
  }
}
