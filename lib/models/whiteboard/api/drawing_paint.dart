import 'dart:ui';

import 'package:logger/logger.dart';

class DrawingPaint {
  final int color;
  final double strokeWidth;
  final String paintingStyle;
  final String strokeCap;
  final String strokeJoin;
  final String filterQuality;
  final String blendMode;
  final bool isAntiAlias;

  var logger = Logger();

  DrawingPaint(
      {required this.color,
      required this.strokeWidth,
      required this.paintingStyle,
      required this.strokeCap,
      required this.strokeJoin,
      required this.filterQuality,
      required this.blendMode,
      required this.isAntiAlias});

  factory DrawingPaint.fromJson(Map<String, dynamic> json) {
    return DrawingPaint(
        color: json['color'],
        strokeWidth: json['stroke_width'].toDouble(),
        paintingStyle: json['painting_style'],
        strokeCap: json['stroke_cap'],
        strokeJoin: json['stroke_join'],
        filterQuality: json['filter_quality'],
        blendMode: json['blend_mode'],
        isAntiAlias: json['is_anti_alias']);
  }

  Map<String, dynamic> toMap() {
    return {
      'color': color,
      'stroke_width': strokeWidth,
      'painting_style': paintingStyle,
      'stroke_cap': strokeCap,
      'stroke_join': strokeJoin,
      'filter_quality': filterQuality,
      'blend_mode': blendMode,
      'is_anti_alias': isAntiAlias
    };
  }

  Paint? toPaint() {
    try {
      late PaintingStyle paintingStyle;
      switch (this.paintingStyle) {
        case 'fill':
          paintingStyle = PaintingStyle.fill;
        case 'stroke':
          paintingStyle = PaintingStyle.stroke;
        default:
          paintingStyle = PaintingStyle.fill;
      }

      late StrokeCap strokeCap;
      switch (this.strokeCap) {
        case 'butt':
          strokeCap = StrokeCap.butt;
        case 'round':
          strokeCap = StrokeCap.round;
        case 'square':
          strokeCap = StrokeCap.square;
        default:
          strokeCap = StrokeCap.butt;
      }

      late StrokeJoin strokeJoin;
      switch (this.strokeJoin) {
        case 'bevel':
          strokeJoin = StrokeJoin.bevel;
        case 'round':
          strokeJoin = StrokeJoin.round;
        case 'miter':
          strokeJoin = StrokeJoin.miter;
        default:
          strokeJoin = StrokeJoin.miter;
      }

      late FilterQuality filterQuality;
      switch (this.filterQuality) {
        case 'low':
          filterQuality = FilterQuality.low;
        case 'medium':
          filterQuality = FilterQuality.medium;
        case 'high':
          filterQuality = FilterQuality.high;
        default:
          filterQuality = FilterQuality.none;
      }

      late BlendMode blendMode;
      switch (this.blendMode) {
        case 'clear':
          blendMode = BlendMode.clear;
        case 'src':
          blendMode = BlendMode.src;
        case 'dst':
          blendMode = BlendMode.dst;
        case 'srcOver':
          blendMode = BlendMode.srcOver;
        case 'dstOver':
          blendMode = BlendMode.dstOver;
        case 'srcIn':
          blendMode = BlendMode.srcIn;
        case 'dstIn':
          blendMode = BlendMode.dstIn;
        case 'srcOut':
          blendMode = BlendMode.srcOut;
        case 'dstOut':
          blendMode = BlendMode.dstOut;
        default:
          blendMode = BlendMode.srcOver;
      }

      return Paint()
        ..color = Color(color)
        ..strokeWidth = strokeWidth
        ..style = paintingStyle
        ..strokeCap = strokeCap
        ..strokeJoin = strokeJoin
        ..filterQuality = filterQuality
        ..blendMode = blendMode
        ..isAntiAlias = isAntiAlias;
    } catch (e) {
      logger.e(e.toString());
    }
    return null;
  }

  @override
  String toString() {
    return 'CustomPaint color: ${color.toString()} strokeWidth: '
        '${strokeWidth.toString()} paintingStyle: ${paintingStyle.toString()} '
        'strokeCap: ${strokeCap.toString()} strokeJoin: ${strokeJoin.toString()} '
        'filterQuality: ${filterQuality.toString()} blendMode: '
        '${blendMode.toString()} isAntiAlias: ${isAntiAlias.toString()}';
  }
}
