import 'package:flutter/material.dart';

class WhiteboardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawLine(Offset(200, 40), Offset(30, 20), Paint()..color = Colors.red ..strokeWidth = 5);
  }

  @override
  bool shouldRepaint(WhiteboardPainter oldDelegate) => false;
}
