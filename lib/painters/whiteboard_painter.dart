import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../models/whiteboard/api/drawn.dart';
import '../models/whiteboard/api/whiteboard.dart';

class WhiteboardPainter extends CustomPainter {
  final Whiteboard whiteboard;

  WhiteboardPainter({required this.whiteboard});

  Logger logger = Logger();

  Paint defaultPaint = Paint()
    ..color = Colors.orange
    ..strokeCap = StrokeCap.butt
    ..strokeJoin = StrokeJoin.miter
    ..style = PaintingStyle.fill
    ..strokeWidth = 5.0
    ..filterQuality = FilterQuality.none
    ..blendMode = BlendMode.srcOver
    ..isAntiAlias = true;

  @override
  void paint(Canvas canvas, Size size) {
    if (whiteboard.drawns == null) return;
    for (var drawer in whiteboard.drawns!) {
      _draw(canvas, size, drawer);
    }
  }

  void _draw(Canvas canvas, Size size, Drawn drawn) {
    if (drawn.subDrawns == null || drawn.subDrawns!.isEmpty) {
      logger.i("Skipping drawing ${drawn.id} subDrawns due to empty list");
      return;
    }
    logger.i("Drawing ${drawn.subDrawns?.length} subDrawns");
    for (int i = 0; i < drawn.subDrawns!.length - 1; i++) {
      logger.i("Drawing subDrawn ${drawn.subDrawns![i].id} - "
          "points: ${drawn.subDrawns![i].points.length - 1}");
      for (int j = 0; j < drawn.subDrawns![i].points.length; j++) {
        if (!drawn.subDrawns![i].points[j].isEndOfSubDrawing() &&
            !drawn.subDrawns![i].points[j + 1].isEndOfSubDrawing()) {
          var paint = drawn.subDrawns![i].paint.toPaint();
          paint ??= defaultPaint;
          canvas.drawLine(drawn.subDrawns![i].points[j].toOffset(),
              drawn.subDrawns![i].points[j + 1].toOffset(), paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(WhiteboardPainter oldDelegate) => true;
}
