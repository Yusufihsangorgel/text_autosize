import 'package:flutter/material.dart';
import 'package:text_autosize/text_autosize.dart';

void main() {
  runApp(const ExampleApp());
}

/// Demo app for the text_autosize package.
class ExampleApp extends StatelessWidget {
  /// Creates the demo app.
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'text_autosize example',
      theme: ThemeData(colorSchemeSeed: Colors.indigo),
      home: const DemoPage(),
    );
  }
}

/// Shows the main features of [AutoSizeText] with an adjustable width.
class DemoPage extends StatefulWidget {
  /// Creates the demo page.
  const DemoPage({super.key});

  @override
  State<DemoPage> createState() => _DemoPageState();
}

class _DemoPageState extends State<DemoPage> {
  final _group = AutoSizeGroup();
  double _width = 300;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('text_autosize')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Box width: ${_width.round()}'),
          Slider(
            min: 60,
            max: 340,
            value: _width,
            onChanged: (value) => setState(() => _width = value),
          ),
          const SizedBox(height: 16),
          _Demo(
            title: 'Single line',
            child: _box(
              height: 60,
              child: const AutoSizeText(
                'The quick brown fox',
                style: TextStyle(fontSize: 40),
                maxLines: 1,
              ),
            ),
          ),
          _Demo(
            title: 'maxLines: 2',
            child: _box(
              height: 80,
              child: const AutoSizeText(
                'The quick brown fox jumps over the lazy dog',
                style: TextStyle(fontSize: 30),
                maxLines: 2,
              ),
            ),
          ),
          _Demo(
            title: 'minFontSize: 18 with ellipsis',
            child: _box(
              height: 60,
              child: const AutoSizeText(
                'This text refuses to get smaller than 18',
                style: TextStyle(fontSize: 30),
                minFontSize: 18,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          _Demo(
            title: 'presetFontSizes: [40, 25, 10]',
            child: _box(
              height: 60,
              child: const AutoSizeText(
                'Only these three sizes are used',
                presetFontSizes: [40, 25, 10],
                maxLines: 1,
              ),
            ),
          ),
          _Demo(
            title: 'AutoSizeGroup keeps both labels in sync',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _box(
                  height: 50,
                  child: AutoSizeText(
                    'First label',
                    style: const TextStyle(fontSize: 30),
                    maxLines: 1,
                    group: _group,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: 220,
                  height: 50,
                  child: DecoratedBox(
                    decoration: BoxDecoration(border: Border.all()),
                    child: AutoSizeText(
                      'Second label in a fixed box',
                      style: const TextStyle(fontSize: 30),
                      maxLines: 1,
                      group: _group,
                    ),
                  ),
                ),
              ],
            ),
          ),
          _Demo(
            title: 'AutoSizeText.rich',
            child: _box(
              height: 60,
              child: const AutoSizeText.rich(
                TextSpan(
                  text: 'Mixed ',
                  children: [
                    TextSpan(text: 'sizes ', style: TextStyle(fontSize: 40)),
                    TextSpan(text: 'scale together'),
                  ],
                ),
                style: TextStyle(fontSize: 25),
                maxLines: 1,
              ),
            ),
          ),
          _Demo(
            title: 'overflowReplacement',
            child: _box(
              height: 60,
              child: const AutoSizeText(
                'This text is replaced when it cannot fit at minFontSize',
                style: TextStyle(fontSize: 30),
                minFontSize: 25,
                maxLines: 1,
                overflowReplacement: Text('Too narrow for the full text'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _box({required double height, required Widget child}) {
    return SizedBox(
      width: _width,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(border: Border.all()),
        child: child,
      ),
    );
  }
}

class _Demo extends StatelessWidget {
  const _Demo({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}
