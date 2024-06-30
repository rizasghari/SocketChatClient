import 'dart:ui';
import 'package:flutter/material.dart';

import '../models/whiteboard/api/drawing_paint.dart';

extension PaintExtension on Paint {
  Map<String, dynamic> toMap() => <String, dynamic>{
        'color': color.value,
        'strokeWidth': strokeWidth,
        'style': style.name,
        'strokeCap': strokeCap.name,
        'strokeJoin': strokeJoin.name,
        'filterQuality': filterQuality.name,
        'blendMode': blendMode.name,
        'isAntiAlias': isAntiAlias
      };

  Paint fromJson(DrawingPaint customPaint) {
    late PaintingStyle paintingStyle;
    switch (customPaint.paintingStyle) {
      case 'fill':
        paintingStyle = PaintingStyle.fill;
      case 'stroke':
        paintingStyle = PaintingStyle.stroke;
    }

    late StrokeCap strokeCap;
    switch (customPaint.strokeCap) {
      case 'butt':
        strokeCap = StrokeCap.butt;
      case 'round':
        strokeCap = StrokeCap.round;
      case 'square':
        strokeCap = StrokeCap.square;
    }

    late StrokeJoin strokeJoin;
    switch (customPaint.strokeJoin) {
      case 'bevel':
        strokeJoin = StrokeJoin.bevel;
      case 'round':
        strokeJoin = StrokeJoin.round;
      case 'miter':
        strokeJoin = StrokeJoin.miter;
    }

    late FilterQuality filterQuality;
    switch (customPaint.filterQuality) {
      case 'low':
        filterQuality = FilterQuality.low;
      case 'medium':
        filterQuality = FilterQuality.medium;
      case 'high':
        filterQuality = FilterQuality.high;
    }

    late BlendMode blendMode;
    switch (customPaint.blendMode) {
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
    }

    return Paint()
      ..color = Color(customPaint.color)
      ..strokeWidth = customPaint.strokeWidth
      ..style = paintingStyle
      ..strokeCap = strokeCap
      ..strokeJoin = strokeJoin
      ..filterQuality = filterQuality
      ..blendMode = blendMode
      ..isAntiAlias = customPaint.isAntiAlias;
  }
}
