import 'package:flutter/material.dart';
import 'package:socket_chat_client/models/whiteboard/whiteboard.dart';

class WhiteboardProvider extends ChangeNotifier {
  late Whiteboard _whiteboard;

  void setWhiteboard(Whiteboard whiteboard) {
    _whiteboard = whiteboard;
    notifyListeners();
  }

  Whiteboard get whiteboard => _whiteboard;

  void addMySidePoint(Offset? point) {
    _whiteboard.mySide.points.add(point);
    notifyListeners();
  }

  void addOtherSidePoint(Offset? point) {
    _whiteboard.otherSide.points.add(point);
    notifyListeners();
  }

  void clear() {
    _whiteboard.mySide.points.clear();
    _whiteboard.otherSide.points.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
