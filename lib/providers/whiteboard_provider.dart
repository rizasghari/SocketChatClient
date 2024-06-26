import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../models/whiteboard/api/whiteboard_response.dart';
import '../models/whiteboard/ui/whiteboard.dart';
import '../models/whiteboard/api/whiteboard_request.dart';
import '../services/api_service.dart';

class WhiteboardProvider extends ChangeNotifier {
  WhiteboardResponse? _whiteboard;

  var logger = Logger();

  void setWhiteboard({WhiteboardResponse? whiteboard, bool notify = true}) {
    _whiteboard = whiteboard;
    if (notify) {
      notifyListeners();
    }
  }

  WhiteboardResponse? get whiteboard => _whiteboard;

  void addMySidePoint(Offset? point) {
    notifyListeners();
  }

  void addOtherSidePoint(Offset? point) {
    notifyListeners();
  }

  Future<void> createWhiteboard(String token, int conversationId) async {
    await Future.delayed(const Duration(seconds: 3));
    var request = WhiteboardRequest(conversationId: conversationId);
    var whiteboard = await ApiService.createWhiteboard(token, request);
    if (whiteboard != null) {
      setWhiteboard(whiteboard: whiteboard);
    }
  }

  void clear() {
    logger.i("clear() / Before clear whiteboard id is: ${_whiteboard?.id}");
    setWhiteboard(whiteboard: null, notify: false);
    logger.i("clear() / After clear whiteboard id is: ${_whiteboard?.id}");
  }

  @override
  void dispose() {
    super.dispose();
  }
}
