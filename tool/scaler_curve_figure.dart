// Draws why a scale *factor* is the wrong thing to hold onto.
//
//   dart run tool/scaler_curve_figure.dart
//
// The README says this package handles `TextScaler` correctly "including
// nonlinear system font scaling", and that `auto_size_text` reads the
// deprecated scalar instead. Both true, and both invisible: the words describe
// a function, and a function is a shape.
//
// The shape is the argument. A `TextScaler` maps a font size to a painted
// size. Sampling it once gives a number that is right at the size the text
// started at -- and fitting moves the text somewhere else, where the curve
// says something different. The example's panel shows this live; this is the
// still.
//
// The curve is `NonlinearTextScaler` from `example/lib/main.dart`, reimplemented
// here so the tool has no dependency on the example, with the same constants.
// It is a stand-in for a platform table, not a copy of one, and the figure
// says so.
import 'dart:io';

/// The user's setting. Small text gets all of it.
const setting = 2.0;

/// Above this many points the text gains a fixed number of points rather than
/// a fixed proportion, which is what makes the curve a curve.
const fullyScaledUpTo = 20.0;

double scale(double fontSize) =>
    fontSize +
    (setting - 1) * (fontSize < fullyScaledUpTo ? fontSize : fullyScaledUpTo);

/// The size the label starts at, before anything is fitted.
const startSize = 40.0;

/// Where the fit settles once the box is applied. Measured by the example's
/// panel with this curve and its 200pt-wide box.
const fittedSize = 14.0;

const bg = '#14161C';
const ink = '#d8dee9';
const dim = '#8b93a3';
const grid = '#262c37';
const truth = '#8ee0a1'; // what the platform paints
const sampled = '#ff8f6b'; // what one factor predicts

void main() {
  const left = 74.0, right = 150.0, top = 104.0, bottom = 66.0;
  const plotW = 470.0, plotH = 300.0;
  const maxIn = 48.0;
  final maxOut = scale(maxIn);
  final width = left + plotW + right;
  final height = top + plotH + bottom;

  double px(double pt) => left + pt / maxIn * plotW;
  double py(double pt) => top + plotH - pt / maxOut * plotH;

  // One factor sampled at the starting size, used as a straight multiplier.
  final factor = scale(startSize) / startSize;

  final svg = StringBuffer()
    ..writeln(
      '<svg xmlns="http://www.w3.org/2000/svg" '
      'width="${width.toStringAsFixed(0)}" height="${height.toInt()}" '
      'viewBox="0 0 ${width.toStringAsFixed(0)} ${height.toInt()}">',
    )
    ..writeln('  <rect width="100%" height="100%" fill="$bg"/>')
    ..writeln(
      '  <text x="$left" y="32" fill="$ink" font-size="15" '
      'font-family="Menlo, monospace">a TextScaler is a function, not a '
      'multiplication</text>',
    )
    ..writeln(
      '  <text x="$left" y="52" fill="$dim" font-size="11.5" '
      'font-family="Menlo, monospace">at a ${setting}x setting, on a curve '
      'that gives small text the whole setting</text>',
    )
    ..writeln(
      '  <text x="$left" y="68" fill="$dim" font-size="11.5" '
      'font-family="Menlo, monospace">and holds large text back — a '
      'stand-in for a platform table, not a copy of one</text>',
    );

  for (var pt = 0.0; pt <= maxOut; pt += 20) {
    final y = py(pt);
    svg
      ..writeln(
        '  <line x1="$left" y1="$y" x2="${left + plotW}" y2="$y" '
        'stroke="$grid" stroke-width="1"/>',
      )
      ..writeln(
        '  <text x="${left - 10}" y="${y + 4}" fill="$dim" '
        'font-size="10.5" font-family="Menlo, monospace" '
        'text-anchor="end">${pt.toInt()}</text>',
      );
  }
  for (var pt = 0.0; pt <= maxIn; pt += 8) {
    svg.writeln(
      '  <text x="${px(pt)}" y="${top + plotH + 20}" fill="$dim" '
      'font-size="10.5" font-family="Menlo, monospace" '
      'text-anchor="middle">${pt.toInt()}</text>',
    );
  }
  svg
    ..writeln(
      '  <text x="${left + plotW / 2}" y="${top + plotH + 42}" '
      'fill="$dim" font-size="11" font-family="Menlo, monospace" '
      'text-anchor="middle">font size asked for (pt)</text>',
    )
    ..writeln(
      '  <text x="20" y="${top + plotH / 2}" fill="$dim" '
      'font-size="11" font-family="Menlo, monospace" '
      'transform="rotate(-90 20 ${top + plotH / 2})" '
      'text-anchor="middle">painted (pt)</text>',
    );

  String curve(double Function(double) f) {
    final points = <String>[];
    for (var pt = 0.0; pt <= maxIn; pt += 1) {
      points.add(
        '${px(pt).toStringAsFixed(1)},${py(f(pt)).toStringAsFixed(1)}',
      );
    }
    return points.join(' L ');
  }

  svg
    ..writeln(
      '  <path d="M ${curve(scale)}" fill="none" stroke="$truth" '
      'stroke-width="2.5"/>',
    )
    ..writeln(
      '  <path d="M ${curve((pt) => pt * factor)}" fill="none" '
      'stroke="$sampled" stroke-width="2" stroke-dasharray="6 4"/>',
    );

  // Where the factor was taken, and where the text actually ended up.
  for (final (pt, label) in [
    (startSize, 'sampled here'),
    (fittedSize, 'fitted here'),
  ]) {
    svg
      ..writeln(
        '  <line x1="${px(pt)}" y1="$top" x2="${px(pt)}" '
        'y2="${top + plotH}" stroke="$dim" stroke-width="1" '
        'stroke-dasharray="2 4"/>',
      )
      ..writeln(
        '  <text x="${px(pt)}" y="${top - 8}" fill="$dim" '
        'font-size="10.5" font-family="Menlo, monospace" '
        'text-anchor="middle">$label</text>',
      );
  }

  final actual = scale(fittedSize);
  final predicted = fittedSize * factor;
  svg
    ..writeln(
      '  <circle cx="${px(fittedSize)}" cy="${py(actual)}" r="4" '
      'fill="$truth"/>',
    )
    ..writeln(
      '  <circle cx="${px(fittedSize)}" cy="${py(predicted)}" r="4" '
      'fill="$sampled"/>',
    )
    ..writeln(
      '  <text x="${left + plotW + 14}" y="${py(scale(maxIn))}" '
      'fill="$truth" font-size="11.5" font-family="Menlo, monospace">'
      'what is painted</text>',
    )
    ..writeln(
      '  <text x="${left + plotW + 14}" y="${py(maxIn * factor)}" '
      'fill="$sampled" font-size="11.5" font-family="Menlo, monospace">'
      'one factor, ${factor.toStringAsFixed(2)}x</text>',
    )
    ..writeln(
      '  <text x="${left + plotW + 14}" y="${py(predicted) + 4}" '
      'fill="$sampled" font-size="11" font-family="Menlo, monospace">'
      'predicts ${predicted.toStringAsFixed(0)} pt</text>',
    )
    ..writeln(
      '  <text x="${left + plotW + 14}" y="${py(actual) + 4}" '
      'fill="$truth" font-size="11" font-family="Menlo, monospace">'
      'paints ${actual.toStringAsFixed(0)} pt</text>',
    )
    ..writeln(
      '  <text x="${width / 2}" y="${height - 14}" fill="$dim" '
      'font-size="11" font-family="Menlo, monospace" text-anchor="middle">'
      'the factor is exact where it was taken and wrong everywhere else; '
      'fitting moves the text</text>',
    )
    ..writeln('</svg>');

  File('doc/scaler-curve.svg').writeAsStringSync(svg.toString());
  stdout
    ..writeln('wrote doc/scaler-curve.svg')
    ..writeln(
      '  factor sampled at ${startSize.toInt()} pt: '
      '${factor.toStringAsFixed(2)}x',
    )
    ..writeln(
      '  at the fitted ${fittedSize.toInt()} pt it predicts '
      '${predicted.toStringAsFixed(0)} pt; the curve paints '
      '${actual.toStringAsFixed(0)} pt',
    )
    ..writeln(
      'render: rsvg-convert -z 2 doc/scaler-curve.svg '
      '-o doc/scaler-curve.png',
    );
}
