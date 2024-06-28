import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../models/whiteboard/api/drawn.dart';
import '../models/whiteboard/api/point.dart';
import '../models/whiteboard/api/whiteboard.dart';

class WhiteboardPainter extends CustomPainter {
  final Whiteboard whiteboard;

  WhiteboardPainter({required this.whiteboard});

  Logger logger = Logger();

  @override
  void paint(Canvas canvas, Size size) {
    if (whiteboard.drawns == null) return;
    for (var drawer in whiteboard.drawns!) {
      _draw(canvas, size, drawer);
    }
  }

  void _draw(Canvas canvas, Size size, Drawn drawn) {
    if (drawn.points == null || drawn.points!.isEmpty) return;

    Paint paint = Paint()
      ..color = Colors.cyan
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0
      ..isAntiAlias = true;

    logger.i("Drawing ${drawn.points?.length} points");
    for (int i = 0; i < drawn.points!.length - 1; i++) {
      if (!drawn.points![i]!.isEndOfSubDrawing() && !drawn.points![i + 1]!.isEndOfSubDrawing()) {
        canvas.drawLine(drawn.points![i]!.toOffset(),
            drawn.points![i + 1]!.toOffset(), paint);
      }
    }
  }

  @override
  bool shouldRepaint(WhiteboardPainter oldDelegate) => true;
}
