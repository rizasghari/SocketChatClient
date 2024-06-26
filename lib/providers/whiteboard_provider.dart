import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:socket_chat_client/models/whiteboard/socket/whiteboard_socket_event.dart';
import 'package:socket_chat_client/models/whiteboard/socket/whiteboard_socket_event_payload.dart';
import 'package:web_socket_channel/io.dart';
import '../models/whiteboard/api/drawn.dart';
import '../models/whiteboard/api/point.dart';
import '../models/whiteboard/api/whiteboard.dart';
import '../models/whiteboard/api/whiteboard_request.dart';
import '../services/api_service.dart';
import '../services/local_storage_service.dart';

class WhiteboardProvider extends ChangeNotifier {
  Whiteboard? _whiteboard;

  Whiteboard? get whiteboard => _whiteboard;

  int? _currentUserId;

  late IOWebSocketChannel _socketChannel;
  var logger = Logger();

  void setWhiteboard(
      {Whiteboard? whiteboard, int? currentUserId, bool notify = true}) async {
    _whiteboard = whiteboard;
    _currentUserId = currentUserId;
    if (notify) {
      notifyListeners();
    }
    await _initializeWithSocket();
  }

  Future<void> _initializeWithSocket() async {
    String? apiHost = await LocalStorage.getString('api_host')
        .then((value) => value == null ? '10.0.2.2' : value.trim());

    String? jwtToken = await LocalStorage.getString('jwt_token');

    String socketUrl = 'ws://$apiHost:8000/ws/whiteboard?id=${_whiteboard!.id}';
    _socketChannel = IOWebSocketChannel.connect(
      Uri.parse(socketUrl),
      headers: {
        'Authorization': jwtToken,
      },
    );
    await _socketChannel.ready;
    _handleSocketEvents();
  }

  void _handleSocketEvents() {
    _socketChannel.stream.listen((event) {
      final decodedEvent = WhiteboardSocketEvent.fromJson(jsonDecode(event));
      switch (decodedEvent.event) {
        case 'update_whiteboard':
          _handleUpdateWhiteboardEvent(decodedEvent);
          break;
        default:
          logger.i("Unknown event: ${decodedEvent.event}");
          break;
      }
    });
  }

  void _handleUpdateWhiteboardEvent(WhiteboardSocketEvent decodedEvent) {
    //
  }

  void sendUpdateWhiteboardSocketEvent() {
    // final payload = WhiteboardSocketEventPayload(
    //     whiteboardId: _whiteboard!.id,
    //     drawerUserId: _whiteboard!.drawerUserId!,
    //     points: _whiteboard!.points);
    // final event =
    //     WhiteboardSocketEvent(event: "update_whiteboard", payload: payload);
    // logger.d("event: $event");
    // _socketChannel.sink.add(jsonEncode(event.toMap()));
  }

  void updateMySidePoint(Offset? offset) {
    if (_whiteboard == null) return;
    if (_whiteboard!.drawns == null || _whiteboard!.drawns!.isEmpty) {
      createMyDrawnForFirstTime(offset);
    } else if (_whiteboard!.drawns!.length == 1) {
      if (_whiteboard!.drawns![0].drawerUserId == _currentUserId) {
        _updateMyExistingDrawn(offset);
      } else {
        createMyDrawnForFirstTime(offset);
      }
    } else if (_whiteboard!.drawns!.length > 1) {
      _updateMyExistingDrawn(offset);
    }

    notifyListeners();
  }

  void _updateMyExistingDrawn(Offset? point) {
    try {
      _whiteboard!.drawns!
          .firstWhere((d) => d.drawerUserId == _currentUserId)
          .points
          ?.add(Point.fromOffset(point!));
    } catch (e) {
      logger.e(e);
    }
    // sendUpdateWhiteboardSocketEvent();
  }

  void createMyDrawnForFirstTime(Offset? offset) {
    _whiteboard!.drawns = [];
    var points = [];
    if (offset != null) {
      points.add(Point.fromOffset(offset));
    } else {
      points.add(null);
    }
    var drawn = Drawn(
        whiteboardId: _whiteboard!.id,
        drawerUserId: _currentUserId!,
        points: []);
    _whiteboard!.drawns!.add(drawn);
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
