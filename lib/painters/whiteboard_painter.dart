import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../models/whiteboard/api/whiteboard.dart';

class WhiteboardPainter extends CustomPainter {
  final Whiteboard whiteboard;

  WhiteboardPainter({required this.whiteboard});

  Logger logger = Logger();

  Paint defaultPaint = Paint()
    ..color = Colors.orange
    ..strokeWidth = 5.0
    ..filterQuality = FilterQuality.none
    ..blendMode = BlendMode.srcOver
    ..strokeCap = StrokeCap.butt
    ..strokeJoin = StrokeJoin.miter
    ..style = PaintingStyle.fill
    ..isAntiAlias = true;

  @override
  void paint(Canvas canvas, Size size) {
    for (var drawn in whiteboard.drawns) {
      if (drawn.subDrawns == null || drawn.subDrawns!.isEmpty) {
        continue;
      }
      logger.i("Drawing ${drawn.subDrawns?.length} subDrawns");
      for (int i = 0; i < drawn.subDrawns!.length - 1; i++) {
        logger.i("Drawing subDrawn ${drawn.subDrawns![i].id} - "
            "points: ${drawn.subDrawns![i].points.length - 1}");
        for (int j = 0; j < drawn.subDrawns![i].points.length - 1; j++) {
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
