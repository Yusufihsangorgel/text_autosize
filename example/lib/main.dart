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
          _Demo(
            title: 'System font scale: measured, not multiplied',
            child: const TextScalerPanel(),
          ),
          const Divider(height: 40),
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
            title: 'An icon in the sentence',
            child: _box(
              height: 60,
              child: const AutoSizeText.rich(
                TextSpan(
                  children: [
                    TextSpan(text: 'Signed in as '),
                    WidgetSpan(child: Icon(Icons.verified)),
                    TextSpan(text: ' ada@example.com'),
                  ],
                ),
                style: TextStyle(fontSize: 40),
                maxLines: 1,
              ),
            ),
          ),
          _Demo(
            title: 'A wide placeholder, through placeholderSize',
            child: _box(
              height: 60,
              child: AutoSizeText.rich(
                const TextSpan(
                  children: [
                    TextSpan(text: 'Build '),
                    WidgetSpan(
                      child: ColoredBox(
                        color: Colors.green,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6),
                          child: Text(
                            'passing',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                    TextSpan(text: ' on main'),
                  ],
                ),
                style: const TextStyle(fontSize: 40),
                maxLines: 1,
                placeholderSize: (span, fontSize) =>
                    Size(fontSize * 3.4, fontSize),
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

/// Shows why a fitted font size has to be measured with the real [TextScaler]
/// rather than derived from a single scale factor.
///
/// The user's font scale reaches a widget as a [TextScaler] on [MediaQuery],
/// and a [TextScaler] is a function, not a multiplication: `scale(fontSize)`
/// may grow small text by more than large text. So a "scale factor" is only a
/// sample of that function at one font size.
///
/// Shrinking is what makes such a sample wrong. The factor describes the curve
/// at the size the text *started* at, and fitting moves the text to a different
/// size, where the curve says something else. [AutoSizeText] calls `scale` on
/// every candidate size it measures, so the size it settles on is the size that
/// really fits. [SingleFactorText] beside it takes the sample instead, and
/// under a curve its text spills out of the box it was fitted to.
///
/// Drag the scale down to 1.0, or switch to the linear curve, and the two sides
/// agree exactly: the difference only exists under a nonlinear scaler.
class TextScalerPanel extends StatefulWidget {
  /// Creates the panel.
  const TextScalerPanel({
    super.key,
    this.initialScale = 1.6,
    this.initialNonlinear = true,
  });

  /// The font scale the panel starts at.
  final double initialScale;

  /// Whether the panel starts on the nonlinear curve rather than a linear
  /// scaler.
  final bool initialNonlinear;

  @override
  State<TextScalerPanel> createState() => _TextScalerPanelState();
}

class _TextScalerPanelState extends State<TextScalerPanel> {
  /// A category chip: the box is fixed by the design, the label is not.
  static const _label = 'Kitchen & Dining';
  static const _style = TextStyle(fontSize: 40, fontWeight: FontWeight.w600);

  /// Lower than a real chip would use, on purpose.
  ///
  /// A floor is a second thing that can decide the fitted size, and once both
  /// sides are pinned to it they agree for a reason that has nothing to do with
  /// the scaler. Wide glyphs, a longer translation or a narrower box all push a
  /// fit toward the floor, so it is set well below where a normal font at this
  /// box size lands: measured with Roboto at a 2.0x scale, the fit settles
  /// around 11 pt.
  static const _minFontSize = 6.0;

  /// The box both sides are fitted into.
  ///
  /// The width is the binding constraint. The height is deliberately generous,
  /// so that only the width decides the fitted size and the two sides stay
  /// comparable: [SingleFactorText] measures width only, and a height that
  /// pinched one side and not the other would show a difference that has
  /// nothing to do with the scaler.
  static const _boxWidth = 200.0;
  static const _boxHeight = 96.0;

  /// Keys on the [Text] each side builds, so the fitted size can be read back
  /// from what was actually rendered instead of recomputed here.
  final _autoTextKey = GlobalKey();
  final _sampledTextKey = GlobalKey();

  late double _scale;
  late bool _nonlinear;

  ({double logical, double rendered})? _autoFit;
  ({double logical, double rendered})? _sampledFit;

  @override
  void initState() {
    super.initState();
    _scale = widget.initialScale;
    _nonlinear = widget.initialNonlinear;
  }

  @override
  Widget build(BuildContext context) {
    final scaler = _nonlinear
        ? NonlinearTextScaler(_scale)
        : TextScaler.linear(_scale);

    // The fitted sizes only exist after layout, so read them once this frame
    // is done. _readFits is careful not to turn that into a loop.
    WidgetsBinding.instance.addPostFrameCallback((_) => _readFits());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('User font scale'),
            const Spacer(),
            Text('${_scale.toStringAsFixed(1)}x'),
          ],
        ),
        Slider(
          min: 1,
          max: 2,
          divisions: 10,
          value: _scale,
          onChanged: (value) => setState(() => _scale = value),
        ),
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: false, label: Text('Linear')),
            ButtonSegment(value: true, label: Text('Nonlinear')),
          ],
          selected: {_nonlinear},
          onSelectionChanged: (selection) =>
              setState(() => _nonlinear = selection.first),
        ),
        const SizedBox(height: 16),
        // Everything below is identical on both sides: same string, same style,
        // same box, same minFontSize, same 1 pt steps. The only difference is
        // how each one consults the scaler.
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _side(
              title: 'AutoSizeText',
              subtitle: 'scale() per candidate',
              fit: _autoFit,
              scaler: scaler,
              child: AutoSizeText(
                _label,
                style: _style,
                maxLines: 1,
                minFontSize: _minFontSize,
                // No textScaler argument: the ambient MediaQuery scaler is
                // picked up and used for measuring as well as rendering.
                // textKey exposes the Text that gets built, which is where
                // the readout below comes from.
                textKey: _autoTextKey,
              ),
            ),
            _side(
              title: 'One sampled factor',
              // The size the sample is taken at is the style's own, so read it
              // from there rather than repeating it here.
              subtitle: 'scale() once, at ${_style.fontSize!.round()} pt',
              fit: _sampledFit,
              scaler: scaler,
              child: SingleFactorText(
                _label,
                style: _style,
                minFontSize: _minFontSize,
                textKey: _sampledTextKey,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _side({
    required String title,
    required String subtitle,
    required ({double logical, double rendered})? fit,
    required TextScaler scaler,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    return SizedBox(
      width: _boxWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.labelLarge),
          Text(subtitle, style: theme.textTheme.bodySmall),
          const SizedBox(height: 6),
          Container(
            height: _boxHeight,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              border: Border.all(color: theme.colorScheme.outline),
            ),
            // Clip, so text that does not fit is cut off at the border the
            // fit was supposed to respect instead of painting over its
            // neighbour.
            clipBehavior: Clip.hardEdge,
            child: MediaQuery(
              // On a device this scaler arrives from the platform and applies
              // to the whole tree. Overriding it here is what lets the slider
              // stand in for a system setting, and it is also how you test
              // against a scale your own device cannot produce. It is scoped
              // to the box on purpose: the labels around it stay legible while
              // the specimen inside grows.
              data: MediaQuery.of(context).copyWith(textScaler: scaler),
              child: child,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            fit == null
                ? 'measuring'
                : 'fits ${fit.logical.toStringAsFixed(0)} pt, '
                      'renders ${fit.rendered.toStringAsFixed(1)} pt',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  /// Reads back what each side actually rendered.
  ///
  /// Both inner [Text] widgets are keyed, so the numbers come from the widgets
  /// that were built rather than from a second copy of the fitting logic here:
  /// `style.fontSize` is the logical size the fit settled on, and applying the
  /// [Text]'s own scaler to it gives the size on screen.
  ///
  /// This runs after every frame, so it must only call [setState] when a
  /// number actually changed. Calling it unconditionally would schedule
  /// another frame, which would call it again, and the panel would spin.
  void _readFits() {
    if (!mounted) {
      return;
    }
    final auto = _fitOf(_autoTextKey);
    final sampled = _fitOf(_sampledTextKey);
    if (auto == _autoFit && sampled == _sampledFit) {
      return;
    }
    setState(() {
      _autoFit = auto;
      _sampledFit = sampled;
    });
  }

  static ({double logical, double rendered})? _fitOf(GlobalKey key) {
    final built = key.currentWidget;
    if (built is! Text) {
      return null;
    }
    final logical = built.style?.fontSize;
    if (logical == null) {
      return null;
    }
    final scaler = built.textScaler ?? TextScaler.noScaling;
    return (logical: logical, rendered: scaler.scale(logical));
  }
}

/// Fits text by sampling the scaler once, the way code written against a
/// single scale factor does.
///
/// This is the side of the panel that gets it wrong, on purpose. It is not a
/// competing package: it is the shortcut a single-number API invites. The
/// framework says as much about its own `TextScaler.textScaleFactor`, which is
/// documented as an estimate that "may not reflect the exact text scaling
/// strategy this TextScaler represents, especially when this TextScaler is not
/// linear".
///
/// The measurement is the naive one: sample the scale once at the style's font
/// size, then treat every candidate as `candidate * factor`. Under a linear
/// scaler that is exactly right, which is why both sides of the panel agree
/// there. Under a curve it is right only at the size the sample was taken at,
/// and shrinking walks away from that size. It then renders with the real
/// scaler, because that is what [MediaQuery] hands every [Text] — measured
/// with the estimate, rendered with the curve, and the gap is what overflows.
///
/// It considers width and a single line only, which is all the comparison
/// needs. [AutoSizeText] also handles height, `maxLines`, `presetFontSizes`,
/// rich text and groups.
///
/// What it does *not* get wrong is the style: it resolves the enclosing
/// [DefaultTextStyle] before measuring, exactly as the real widget does. That
/// matters for honesty here. An unmerged style measures the fallback font
/// instead of the app's, which makes the two sides differ for a reason that
/// has nothing to do with the scaler.
class SingleFactorText extends StatelessWidget {
  /// Creates the single-factor text.
  ///
  /// [style] must set a font size: that is the size the sample is taken at.
  const SingleFactorText(
    this.data, {
    super.key,
    required this.style,
    required this.minFontSize,
    this.textKey,
  });

  /// The text to fit.
  final String data;

  /// The style to fit, including the font size to start from.
  final TextStyle style;

  /// The smallest font size to try.
  final double minFontSize;

  /// Key for the [Text] this widget builds.
  final Key? textKey;

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);

    // Measure the style that will actually be drawn, not the one passed in.
    // A Text merges its style with the enclosing DefaultTextStyle, so that is
    // where the font family comes from; measuring the unmerged style measures
    // the platform's fallback font and gets a width for text nobody will see.
    // AutoSizeText resolves the style the same way before it measures.
    final resolved = DefaultTextStyle.of(context).style.merge(style);
    final base = resolved.fontSize!;

    // The one sample, taken before anything shrinks. This number describes the
    // scaler at 40 pt and nowhere else.
    final factor = scaler.scale(base) / base;

    return LayoutBuilder(
      builder: (context, constraints) {
        final painter = TextPainter(
          textDirection: TextDirection.ltr,
          maxLines: 1,
          textScaler: TextScaler.linear(factor),
        );
        var fitted = minFontSize;
        try {
          for (var candidate = base; candidate >= minFontSize; candidate -= 1) {
            painter
              ..text = TextSpan(
                text: data,
                style: resolved.copyWith(fontSize: candidate),
              )
              ..layout();
            if (painter.width <= constraints.maxWidth) {
              fitted = candidate;
              break;
            }
          }
        } finally {
          painter.dispose();
        }

        return Text(
          data,
          key: textKey,
          style: style.copyWith(fontSize: fitted),
          // The real scaler. Nothing here is dishonest about rendering; the
          // mistake was made while measuring.
          textScaler: scaler,
          maxLines: 1,
          softWrap: false,
        );
      },
    );
  }
}

/// A stand-in for nonlinear system font scaling.
///
/// Platforms that scale nonlinearly give body text the user's full setting and
/// hold large text back: a heading that is already 40 pt does not need to
/// double to stay readable, while 12 pt body copy does.
///
/// This class has that shape in the simplest form that stays monotonic. The
/// setting applies in full up to [_fullyScaledUpTo] points; above that the text
/// gains a fixed number of points instead of a fixed proportion. At a 2.0x
/// setting, 14 pt renders at 28 pt (2.00x) and 40 pt renders at 60 pt (1.50x).
///
/// It is a stand-in, not a copy of any platform's table. All the panel needs is
/// that `scale` is a curve; which curve it is does not matter.
class NonlinearTextScaler extends TextScaler {
  /// Creates a scaler that applies [scaleSetting] in full to small text.
  const NonlinearTextScaler(this.scaleSetting) : assert(scaleSetting >= 1);

  /// The scale the user asked for. Small text gets all of it.
  final double scaleSetting;

  /// The font size up to which [scaleSetting] applies in full.
  static const double _fullyScaledUpTo = 20;

  @override
  double scale(double fontSize) {
    final scaledPart = fontSize < _fullyScaledUpTo
        ? fontSize
        : _fullyScaledUpTo;
    return fontSize + (scaleSetting - 1) * scaledPart;
  }

  @override
  // One number cannot describe a curve, which is the whole point of the panel.
  // The setting is the closest estimate available: exact for text at or below
  // _fullyScaledUpTo, and too large for anything bigger.
  double get textScaleFactor => scaleSetting;

  // TextScaler equality decides whether text rebuilds, and a fresh scaler is
  // built on every frame of a slider drag, so comparing by value keeps the
  // drag from rebuilding text that has not changed.
  @override
  bool operator ==(Object other) =>
      other is NonlinearTextScaler && other.scaleSetting == scaleSetting;

  @override
  int get hashCode => scaleSetting.hashCode;

  @override
  String toString() =>
      'nonlinear (${scaleSetting}x up to $_fullyScaledUpTo pt)';
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
