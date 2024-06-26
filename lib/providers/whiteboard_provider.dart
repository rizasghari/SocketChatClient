import 'package:flutter/material.dart';
import '../models/whiteboard/api/whiteboard_response.dart';
import '../models/whiteboard/ui/whiteboard.dart';
import '../models/whiteboard/api/whiteboard_request.dart';
import '../services/api_service.dart';

class WhiteboardProvider extends ChangeNotifier {
  late WhiteboardResponse _whiteboard;

  void setWhiteboard(WhiteboardResponse whiteboard) {
    _whiteboard = whiteboard;
    notifyListeners();
  }

  WhiteboardResponse get whiteboard => _whiteboard;

  void addMySidePoint(Offset? point) {

    notifyListeners();
  }

  void addOtherSidePoint(Offset? point) {

    notifyListeners();
  }

  Future<void> createWhiteboard(
      String token, int conversationId) async {
    await Future.delayed(const Duration(seconds: 3));
    var request = WhiteboardRequest(conversationId: conversationId);
    var whiteboard = await ApiService.createWhiteboard(token, request);
    if (whiteboard != null) {
      setWhiteboard(whiteboard);
      notifyListeners();
    }
  }

  void clear() {

    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
