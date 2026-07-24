import 'dart:async';

import 'package:flutter/widgets.dart';

/// Synchronizes the font size of multiple [AutoSizeText] widgets.
///
/// Give the same [AutoSizeGroup] instance to every [AutoSizeText] that should
/// share a font size. The group settles on the largest size at which all of
/// its members fit, which is the size of the most constrained member.
///
/// The group synchronizes the logical (unscaled) font size. Each member still
/// applies its own [TextScaler] when rendering.
///
/// Members deregister themselves when they are disposed, so a group can be
/// kept alive across route changes without leaking widget state.
final class AutoSizeGroup {
  /// Creates a group that synchronizes the font size of its members.
  AutoSizeGroup();

  final _listeners = <_AutoSizeTextState, double>{};
  var _widgetsNotified = false;
  var _fontSize = double.infinity;

  void _register(_AutoSizeTextState text) {
    _listeners[text] = double.infinity;
  }

  void _updateFontSize(_AutoSizeTextState text, double maxFontSize) {
    final oldFontSize = _fontSize;
    if (maxFontSize <= _fontSize) {
      _fontSize = maxFontSize;
      _listeners[text] = maxFontSize;
    } else if (_listeners[text] == _fontSize) {
      _listeners[text] = maxFontSize;
      _fontSize = double.infinity;
      for (final size in _listeners.values) {
        if (size < _fontSize) {
          _fontSize = size;
        }
      }
    } else {
      _listeners[text] = maxFontSize;
    }

    if (oldFontSize != _fontSize) {
      _widgetsNotified = false;
      scheduleMicrotask(_notifyListeners);
    }
  }

  void _notifyListeners() {
    if (_widgetsNotified) {
      return;
    }
    _widgetsNotified = true;

    for (final textState in _listeners.keys) {
      if (textState.mounted) {
        textState._notifySync();
      }
    }
  }

  void _remove(_AutoSizeTextState text) {
    _updateFontSize(text, double.infinity);
    _listeners.remove(text);
  }
}

/// A widget that automatically resizes text to fit within its bounds.
///
/// [AutoSizeText] measures its text against the incoming constraints and
/// lowers the font size until the text fits. All size constraints as well as
/// [maxLines] are taken into account. If the text still overflows at
/// [minFontSize], it is rendered at [minFontSize] and either truncated
/// according to [overflow] or replaced by [overflowReplacement].
///
/// The API follows the `auto_size_text` package. The main difference is that
/// text scaling is expressed through [textScaler] instead of the removed
/// `textScaleFactor`, so nonlinear system font scaling is applied correctly.
///
/// ## How the size is found
///
/// The widget first checks whether the preferred font size (the style's font
/// size clamped to [minFontSize] and [maxFontSize]) already fits. If it does
/// not, a binary search runs over the candidate sizes between [minFontSize]
/// and the preferred size, in steps of [stepGranularity], or over
/// [presetFontSizes] if given. Each probe is one [TextPainter] layout, so a
/// build performs O(log n) text layouts for n candidate sizes. A single
/// [TextPainter] instance is reused for all probes.
///
/// ## Limitations
///
/// * The widget only shrinks text. It never grows text beyond the preferred
///   font size (except through [presetFontSizes], which may contain larger
///   values).
/// * Resizing needs a bounded constraint to resize against. Inside an
///   unbounded context (for example the scroll direction of a [ListView], or
///   an [UnconstrainedBox]) the text always fits and keeps its preferred
///   size. This does not crash, but no resizing happens on that axis.
/// * [AutoSizeText] is built around a [LayoutBuilder] and therefore cannot be
///   used where intrinsic dimensions are required, such as inside
///   [IntrinsicWidth] or [IntrinsicHeight].
/// * [strutStyle] is passed through as given and is not resized together with
///   the text. A strut with a fixed font size puts a floor under the line
///   height regardless of the fitted font size.
/// * [softWrap] affects rendering but not measurement, so text that is fitted
///   with wrapping in mind can still overflow horizontally when soft wrapping
///   is disabled.
/// * With [wrapWords] set to false, the longest-word check measures the words
///   with the base style only; per-span font sizes of rich text are not
///   considered in that check.
class AutoSizeText extends StatefulWidget {
  /// Creates an [AutoSizeText] widget.
  ///
  /// If the [style] argument is null, the text will use the style from the
  /// closest enclosing [DefaultTextStyle].
  const AutoSizeText(
    String this.data, {
    super.key,
    this.textKey,
    this.style,
    this.strutStyle,
    this.minFontSize = 12,
    this.maxFontSize = double.infinity,
    this.stepGranularity = 1,
    this.presetFontSizes,
    this.group,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.wrapWords = true,
    this.overflow,
    this.overflowReplacement,
    this.textScaler,
    @Deprecated('Use textScaler instead. Will be removed in a future release.')
    this.textScaleFactor,
    this.maxLines,
    this.semanticsLabel,
    this.textWidthBasis,
    this.textHeightBehavior,
    this.selectionColor,
  }) : textSpan = null;

  /// Creates an [AutoSizeText] widget with a [TextSpan].
  ///
  /// The [textSpan] is measured with the fully resolved style, exactly as
  /// [Text.rich] renders it, and all font sizes within the span tree are
  /// scaled proportionally when the text is resized.
  const AutoSizeText.rich(
    TextSpan this.textSpan, {
    super.key,
    this.textKey,
    this.style,
    this.strutStyle,
    this.minFontSize = 12,
    this.maxFontSize = double.infinity,
    this.stepGranularity = 1,
    this.presetFontSizes,
    this.group,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.wrapWords = true,
    this.overflow,
    this.overflowReplacement,
    this.textScaler,
    @Deprecated('Use textScaler instead. Will be removed in a future release.')
    this.textScaleFactor,
    this.maxLines,
    this.semanticsLabel,
    this.textWidthBasis,
    this.textHeightBehavior,
    this.selectionColor,
  }) : data = null;

  /// The default font size if none is specified.
  static const double _defaultFontSize = 14;

  /// Sets the key for the resulting [Text] widget.
  ///
  /// This allows you to find the actual [Text] widget built by [AutoSizeText].
  final Key? textKey;

  /// The text to display.
  ///
  /// This will be null if a [textSpan] is provided instead.
  final String? data;

  /// The text to display as a [TextSpan].
  ///
  /// This will be null if [data] is provided instead.
  final TextSpan? textSpan;

  /// If non-null, the style to use for this text.
  ///
  /// If the style's "inherit" property is true, the style will be merged with
  /// the closest enclosing [DefaultTextStyle]. Otherwise, the style will
  /// replace the closest enclosing [DefaultTextStyle].
  final TextStyle? style;

  /// The strut style to use. Strut style defines the strut, which sets minimum
  /// vertical layout metrics.
  ///
  /// Omitting or providing null will disable strut.
  ///
  /// The strut is not resized together with the text. See the class-level
  /// limitations for details.
  final StrutStyle? strutStyle;

  /// The minimum text size constraint to be used when auto-sizing text.
  ///
  /// Ignored if [presetFontSizes] is set.
  final double minFontSize;

  /// The maximum text size constraint to be used when auto-sizing text.
  ///
  /// Ignored if [presetFontSizes] is set.
  final double maxFontSize;

  /// The step size in which the font size is being adapted to constraints.
  ///
  /// The text scales uniformly in a range between [minFontSize] and
  /// [maxFontSize], in increments of [stepGranularity].
  ///
  /// Most of the time you don't want a step granularity below 1.0.
  ///
  /// Ignored if [presetFontSizes] is set.
  final double stepGranularity;

  /// Predefines all the possible font sizes.
  ///
  /// The sizes have to be in descending order. The first (largest) size that
  /// fits is used.
  final List<double>? presetFontSizes;

  /// Synchronizes the size of multiple [AutoSizeText] widgets.
  ///
  /// If you want multiple [AutoSizeText] widgets to have the same text size,
  /// give all of them the same [AutoSizeGroup] instance. All of them will
  /// have the size of the smallest member.
  final AutoSizeGroup? group;

  /// How the text should be aligned horizontally.
  final TextAlign? textAlign;

  /// The directionality of the text.
  ///
  /// This decides how [textAlign] values like [TextAlign.start] and
  /// [TextAlign.end] are interpreted.
  ///
  /// This is also used to disambiguate how to render bidirectional text. For
  /// example, if the [data] is an English phrase followed by a Hebrew phrase,
  /// in a [TextDirection.ltr] context the English phrase will be on the left
  /// and the Hebrew phrase to its right, while in a [TextDirection.rtl]
  /// context, the English phrase will be on the right and the Hebrew phrase
  /// on its left.
  ///
  /// Defaults to the ambient [Directionality], if any.
  final TextDirection? textDirection;

  /// Used to select a font when the same Unicode character can
  /// be rendered differently, depending on the locale.
  ///
  /// It's rarely necessary to set this property. By default its value
  /// is inherited from the enclosing app with
  /// `Localizations.localeOf(context)`.
  final Locale? locale;

  /// Whether the text should break at soft line breaks.
  ///
  /// If false, the glyphs in the text will be positioned as if there was
  /// unlimited horizontal space.
  final bool? softWrap;

  /// Whether words which don't fit in one line should be wrapped.
  ///
  /// If false, the font size is lowered as far as possible until all words
  /// fit into a single line.
  final bool wrapWords;

  /// How visual overflow should be handled.
  ///
  /// Defaults to retrieving the value from the nearest [DefaultTextStyle]
  /// ancestor.
  final TextOverflow? overflow;

  /// If the text is overflowing and does not fit its bounds, this widget is
  /// displayed instead.
  final Widget? overflowReplacement;

  /// The font scaling strategy to use when laying out and rendering the text.
  ///
  /// The scaler is taken into account when measuring: the fitted font size is
  /// chosen so that the scaled text fits the available space. [minFontSize],
  /// [maxFontSize] and [presetFontSizes] bound the logical (unscaled) font
  /// size, so the rendered text still grows with the user's system font
  /// scale.
  ///
  /// If null, the ambient [MediaQuery] scaler is used, or
  /// [TextScaler.noScaling] if there is no [MediaQuery] in scope.
  ///
  /// Replaces the `textScaleFactor` parameter of the `auto_size_text`
  /// package. Use `TextScaler.linear(factor)` for a fixed factor.
  final TextScaler? textScaler;

  /// The number of font pixels for each logical pixel.
  ///
  /// Kept for source compatibility with the `auto_size_text` package so that
  /// existing call sites still compile. A non-null value is treated as
  /// `TextScaler.linear(textScaleFactor)`. Setting both [textScaler] and
  /// [textScaleFactor] is not allowed.
  @Deprecated('Use textScaler instead. Will be removed in a future release.')
  final double? textScaleFactor;

  /// An optional maximum number of lines for the text to span, wrapping if
  /// necessary. If the text exceeds the given number of lines, it will be
  /// resized according to the specified bounds and if necessary truncated
  /// according to [overflow].
  ///
  /// If this is 1, text will not wrap. Otherwise, text will be wrapped at the
  /// edge of the box.
  ///
  /// If this is null, but there is an ambient [DefaultTextStyle] that
  /// specifies an explicit number for its [DefaultTextStyle.maxLines], then
  /// the [DefaultTextStyle] value will take precedence. You can use a
  /// [RichText] widget directly to entirely override the [DefaultTextStyle].
  final int? maxLines;

  /// An alternative semantics label for this text.
  ///
  /// If present, the semantics of this widget will contain this value instead
  /// of the actual text. This will overwrite any of the semantics labels
  /// applied directly to the [TextSpan]s.
  ///
  /// This is useful for replacing abbreviations or shorthands with the full
  /// text value:
  ///
  /// ```dart
  /// AutoSizeText(r'$$', semanticsLabel: 'Double dollars')
  /// ```
  final String? semanticsLabel;

  /// Defines how to measure the width of the rendered text.
  final TextWidthBasis? textWidthBasis;

  /// Defines how to apply [TextStyle.height] over and under text.
  final TextHeightBehavior? textHeightBehavior;

  /// The color to use when painting the selection.
  ///
  /// [AutoSizeText] builds a regular [Text] widget, so it participates in
  /// [SelectionArea] and [SelectableRegion] like any other text.
  final Color? selectionColor;

  @override
  State<AutoSizeText> createState() => _AutoSizeTextState();
}

class _AutoSizeTextState extends State<AutoSizeText> {
  /// A single painter reused for every fit probe of this widget.
  ///
  /// The text direction set here is a placeholder; every probe overwrites
  /// all relevant properties before layout.
  final TextPainter _textPainter = TextPainter(
    textDirection: TextDirection.ltr,
  );

  @override
  void initState() {
    super.initState();

    widget.group?._register(this);
  }

  @override
  void didUpdateWidget(AutoSizeText oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.group != widget.group) {
      oldWidget.group?._remove(this);
      widget.group?._register(this);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, size) {
        final defaultTextStyle = DefaultTextStyle.of(context);

        var style = widget.style;
        if (style == null || style.inherit) {
          style = defaultTextStyle.style.merge(style);
        }
        if (style.fontSize == null) {
          style = style.copyWith(fontSize: AutoSizeText._defaultFontSize);
        }

        final maxLines = widget.maxLines ?? defaultTextStyle.maxLines;
        // ignore: deprecated_member_use_from_same_package
        final textScaleFactor = widget.textScaleFactor;
        final textScaler =
            widget.textScaler ??
            (textScaleFactor != null
                ? TextScaler.linear(textScaleFactor)
                : MediaQuery.textScalerOf(context));

        _validateProperties(style, maxLines);

        final (fontSize, textFits) = _calculateFontSize(
          size,
          style,
          maxLines,
          textScaler,
          defaultTextStyle,
          context,
        );

        Widget text;

        final group = widget.group;
        if (group != null) {
          group._updateFontSize(this, fontSize);
          text = _buildText(group._fontSize, style, maxLines, textScaler);
        } else {
          text = _buildText(fontSize, style, maxLines, textScaler);
        }

        final overflowReplacement = widget.overflowReplacement;
        if (overflowReplacement != null && !textFits) {
          return overflowReplacement;
        }
        return text;
      },
    );
  }

  void _validateProperties(TextStyle style, int? maxLines) {
    assert(
      widget.overflow == null || widget.overflowReplacement == null,
      'Either overflow or overflowReplacement must be null.',
    );
    assert(
      maxLines == null || maxLines > 0,
      'MaxLines must be greater than or equal to 1.',
    );
    assert(
      widget.key == null || widget.key != widget.textKey,
      'Key and textKey must not be equal.',
    );
    assert(
      // ignore: deprecated_member_use_from_same_package
      widget.textScaler == null || widget.textScaleFactor == null,
      'textScaler and textScaleFactor must not both be set. '
      'textScaleFactor is deprecated; use textScaler.',
    );

    final presetFontSizes = widget.presetFontSizes;
    if (presetFontSizes == null) {
      assert(
        widget.stepGranularity >= 0.1,
        'StepGranularity must be greater than or equal to 0.1. It is not a '
        'good idea to resize the font with a higher accuracy.',
      );
      assert(
        widget.minFontSize >= 0,
        'MinFontSize must be greater than or equal to 0.',
      );
      assert(widget.maxFontSize > 0, 'MaxFontSize has to be greater than 0.');
      assert(
        widget.minFontSize <= widget.maxFontSize,
        'MinFontSize must be smaller or equal than maxFontSize.',
      );
      assert(
        widget.minFontSize / widget.stepGranularity % 1 == 0,
        'MinFontSize must be a multiple of stepGranularity.',
      );
      if (widget.maxFontSize != double.infinity) {
        assert(
          widget.maxFontSize / widget.stepGranularity % 1 == 0,
          'MaxFontSize must be a multiple of stepGranularity.',
        );
      }
    } else {
      assert(presetFontSizes.isNotEmpty, 'PresetFontSizes must not be empty.');
      assert(() {
        for (var i = 0; i < presetFontSizes.length - 1; i++) {
          if (presetFontSizes[i] <= presetFontSizes[i + 1]) {
            return false;
          }
        }
        return true;
      }(), 'PresetFontSizes must be in descending order.');
    }
  }

  (double, bool) _calculateFontSize(
    BoxConstraints size,
    TextStyle style,
    int? maxLines,
    TextScaler textScaler,
    DefaultTextStyle defaultTextStyle,
    BuildContext context,
  ) {
    // Mirrors the span that Text/Text.rich builds internally, so the fit
    // probes measure exactly what will be rendered.
    final span = TextSpan(
      style: style,
      text: widget.data,
      children: widget.textSpan == null ? null : <TextSpan>[widget.textSpan!],
    );

    final baseFontSize = style.fontSize!;

    // Every probe below scales the span by `candidate / baseFontSize`. A base
    // that is zero, negative or non-finite makes that ratio infinite or NaN,
    // and a span laid out at a NaN size reports NaN metrics, which the fit
    // check reads as "it fits" because every comparison against NaN is false.
    // A plain Text renders such a style without complaint, so match it: use
    // the size the caller asked for and do not autosize.
    if (!baseFontSize.isFinite || baseFontSize <= 0) {
      return (baseFontSize, true);
    }

    final textAlign =
        widget.textAlign ?? defaultTextStyle.textAlign ?? TextAlign.start;
    final textDirection = widget.textDirection ?? Directionality.of(context);
    final textWidthBasis =
        widget.textWidthBasis ?? defaultTextStyle.textWidthBasis;
    final textHeightBehavior =
        widget.textHeightBehavior ??
        defaultTextStyle.textHeightBehavior ??
        DefaultTextHeightBehavior.maybeOf(context);

    bool checkFontSize(double fontSize) {
      return _checkTextFits(
        span,
        _RatioTextScaler.compose(textScaler, fontSize / baseFontSize),
        maxLines,
        size,
        textAlign: textAlign,
        textDirection: textDirection,
        textWidthBasis: textWidthBasis,
        textHeightBehavior: textHeightBehavior,
      );
    }

    int left;
    int right;

    final presetFontSizes = widget.presetFontSizes?.reversed.toList();
    if (presetFontSizes == null) {
      final defaultFontSize = baseFontSize.clamp(
        widget.minFontSize,
        widget.maxFontSize,
      );
      if (checkFontSize(defaultFontSize)) {
        return (defaultFontSize, true);
      }

      left = (widget.minFontSize / widget.stepGranularity).floor();
      right = (defaultFontSize / widget.stepGranularity).ceil();
    } else {
      left = 0;
      right = presetFontSizes.length - 1;
    }

    var lastValueFits = false;
    while (left <= right) {
      final mid = (left + (right - left) / 2).floor();
      final double candidate;
      if (presetFontSizes == null) {
        candidate = mid * widget.stepGranularity;
      } else {
        candidate = presetFontSizes[mid];
      }
      if (checkFontSize(candidate)) {
        left = mid + 1;
        lastValueFits = true;
      } else {
        right = mid - 1;
      }
    }

    if (!lastValueFits) {
      right += 1;
    }

    final double fontSize;
    if (presetFontSizes == null) {
      fontSize = right * widget.stepGranularity;
    } else {
      fontSize = presetFontSizes[right];
    }

    return (fontSize, lastValueFits);
  }

  bool _checkTextFits(
    TextSpan text,
    TextScaler textScaler,
    int? maxLines,
    BoxConstraints constraints, {
    required TextAlign textAlign,
    required TextDirection textDirection,
    required TextWidthBasis textWidthBasis,
    required TextHeightBehavior? textHeightBehavior,
  }) {
    final painter = _textPainter
      ..textAlign = textAlign
      ..textDirection = textDirection
      ..textScaler = textScaler
      ..locale = widget.locale
      ..strutStyle = widget.strutStyle
      ..textWidthBasis = textWidthBasis
      ..textHeightBehavior = textHeightBehavior;

    if (!widget.wrapWords) {
      final words = text.toPlainText().split(RegExp(r'\s+'));

      painter
        ..text = TextSpan(style: text.style, text: words.join('\n'))
        ..maxLines = words.length
        ..layout(maxWidth: constraints.maxWidth);

      if (painter.didExceedMaxLines || painter.width > constraints.maxWidth) {
        return false;
      }
    }

    painter
      ..text = text
      ..maxLines = maxLines
      ..layout(maxWidth: constraints.maxWidth);

    return !(painter.didExceedMaxLines ||
        painter.height > constraints.maxHeight ||
        painter.width > constraints.maxWidth);
  }

  Widget _buildText(
    double fontSize,
    TextStyle style,
    int? maxLines,
    TextScaler textScaler,
  ) {
    final data = widget.data;
    if (data != null) {
      return Text(
        data,
        key: widget.textKey,
        style: style.copyWith(fontSize: fontSize),
        strutStyle: widget.strutStyle,
        textAlign: widget.textAlign,
        textDirection: widget.textDirection,
        locale: widget.locale,
        softWrap: widget.softWrap,
        overflow: widget.overflow,
        textScaler: textScaler,
        maxLines: maxLines,
        semanticsLabel: widget.semanticsLabel,
        textWidthBasis: widget.textWidthBasis,
        textHeightBehavior: widget.textHeightBehavior,
        selectionColor: widget.selectionColor,
      );
    }
    return Text.rich(
      widget.textSpan!,
      key: widget.textKey,
      style: style,
      strutStyle: widget.strutStyle,
      textAlign: widget.textAlign,
      textDirection: widget.textDirection,
      locale: widget.locale,
      softWrap: widget.softWrap,
      overflow: widget.overflow,
      // Same degenerate-base guard as the fit probes: with a zero or
      // non-finite base the ratio is infinite or NaN, which would scale the
      // span to NaN metrics. Fall back to the ambient scaler.
      textScaler: (!style.fontSize!.isFinite || style.fontSize! <= 0)
          ? textScaler
          : _RatioTextScaler.compose(textScaler, fontSize / style.fontSize!),
      maxLines: maxLines,
      semanticsLabel: widget.semanticsLabel,
      textWidthBasis: widget.textWidthBasis,
      textHeightBehavior: widget.textHeightBehavior,
      selectionColor: widget.selectionColor,
    );
  }

  void _notifySync() {
    setState(() {});
  }

  @override
  void dispose() {
    widget.group?._remove(this);
    _textPainter.dispose();
    super.dispose();
  }
}

/// A [TextScaler] that multiplies every font size by [ratio] before applying
/// the [parent] scaler.
///
/// This is how [AutoSizeText] resizes rich text: the whole span tree is
/// scaled proportionally, and the ambient scaler (which may be nonlinear) is
/// applied on top of the already resized font sizes.
class _RatioTextScaler extends TextScaler {
  const _RatioTextScaler(this.parent, this.ratio);

  final TextScaler parent;
  final double ratio;

  /// Returns [parent] unchanged if [ratio] is 1, otherwise wraps it.
  static TextScaler compose(TextScaler parent, double ratio) {
    if (ratio == 1.0) {
      return parent;
    }
    return _RatioTextScaler(parent, ratio);
  }

  @override
  double scale(double fontSize) => parent.scale(fontSize * ratio);

  @override
  // ignore: deprecated_member_use
  double get textScaleFactor => parent.textScaleFactor * ratio;

  @override
  bool operator ==(Object other) {
    return other is _RatioTextScaler &&
        other.parent == parent &&
        other.ratio == ratio;
  }

  @override
  int get hashCode => Object.hash(parent, ratio);
}
