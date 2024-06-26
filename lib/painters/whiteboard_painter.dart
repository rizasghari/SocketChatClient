import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:socket_chat_client/models/whiteboard/ui/whiteboard_drawer.dart';

import '../models/whiteboard/ui/whiteboard.dart';

class WhiteboardPainter extends CustomPainter {
  final Whiteboard whiteboard;
  WhiteboardPainter({required this.whiteboard});

  Logger logger = Logger();

  @override
  void paint(Canvas canvas, Size size) {
    _draw(canvas, size, whiteboard.mySide);
    _draw(canvas, size, whiteboard.otherSide);
  }

  void _draw(Canvas canvas, Size size, WhiteboardDrawer drawer) {
    logger.i("Drawing ${drawer.points.length} points");
    if (drawer.points.isEmpty) return;
    for (int i = 0; i < drawer.points.length - 1; i++) {
      if (drawer.points[i] != null && drawer.points[i + 1] != null) {
        canvas.drawLine(drawer.points[i]!, drawer.points[i + 1]!, drawer.paint);
      }
    }
  }

  @override
  bool shouldRepaint(WhiteboardPainter oldDelegate) => true;
}
