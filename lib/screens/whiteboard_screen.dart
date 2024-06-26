import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:socket_chat_client/models/whiteboard/ui/whiteboard.dart';
import 'package:socket_chat_client/providers/whiteboard_provider.dart';

import '../models/whiteboard/ui/whiteboard_drawer.dart';
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
    _provider = WhiteboardProvider();
    //..setWhiteboard();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<WhiteboardProvider>.value(
        value: _provider,
        child: Scaffold(
            appBar: AppBar(
              title: const Text('Live Whiteboard'),
              flexibleSpace: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue, Colors.purple],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(
                    Icons.delete,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    _provider.clear();
                  },
                ),
              ],
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
                  // child: CustomPaint(
                  //   painter:
                  //       WhiteboardPainter(whiteboard: _provider.whiteboard),
                  //   size: const Size(double.infinity, double.infinity),
                  //   child: ConstrainedBox(
                  //     constraints: const BoxConstraints.expand(),
                  //   ),
                  // ),
                );
              },
            )));
  }

  @override
  void dispose() {
    super.dispose();
  }
}
