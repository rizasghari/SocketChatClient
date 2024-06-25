import 'package:flutter/material.dart';

import '../painters/whiteboard_painter.dart';

class WhiteboardScreen extends StatefulWidget {
  const WhiteboardScreen({super.key});

  @override
  State<StatefulWidget> createState() => _WhiteboardScreenState();
}

class _WhiteboardScreenState extends State<WhiteboardScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Whiteboard'),
      ),
      body: GestureDetector(
        onTap: () {},
        child: CustomPaint(
          painter: WhiteboardPainter(),
          size: const Size(double.infinity, double.infinity),
          child: ConstrainedBox(
            constraints: const BoxConstraints.expand(),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
