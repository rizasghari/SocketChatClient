import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:socket_chat_client/models/whiteboard/whiteboard.dart';
import 'package:socket_chat_client/providers/whiteboard_provider.dart';

import '../models/whiteboard/whiteboard_drawer.dart';
import '../painters/whiteboard_painter.dart';

class WhiteboardScreen extends StatefulWidget {
  const WhiteboardScreen({super.key});

  @override
  State<StatefulWidget> createState() => _WhiteboardScreenState();
}

class _WhiteboardScreenState extends State<WhiteboardScreen> {
  late WhiteboardProvider _provider;
  late Whiteboard _whiteboard;

  @override
  void initState() {
    super.initState();
    _whiteboard = Whiteboard(
        mySide: WhiteboardDrawer(
            paint: Paint()
              ..strokeWidth = 5.0
              ..color = Colors.blueAccent
              ..style = PaintingStyle.stroke,
            points: []),
        otherSide: WhiteboardDrawer(
            paint: Paint()
              ..strokeWidth = 5.0
              ..color = Colors.redAccent
              ..style = PaintingStyle.stroke,
            points: []));
    _provider = WhiteboardProvider()..setWhiteboard(_whiteboard);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<WhiteboardProvider>.value(
        value: _provider,
        child: Scaffold(
            appBar: AppBar(
              title: const Text('Whiteboard'),
            ),
            body: Consumer<WhiteboardProvider>(
              builder: (context, drawer, child) {
                return GestureDetector(
                  onPanUpdate: (details) {
                    _provider.addMySidePoint(details.localPosition);
                  },
                  onPanEnd: (details) {
                    _provider.addMySidePoint(null);
                  },
                  child: CustomPaint(
                    painter:
                        WhiteboardPainter(whiteboard: _provider.whiteboard),
                    size: const Size(double.infinity, double.infinity),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints.expand(),
                    ),
                  ),
                );
              },
            )));
  }

  @override
  void dispose() {
    super.dispose();
  }
}
