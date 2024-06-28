import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:socket_chat_client/callbacks/whiteboard_change_callback.dart';
import 'package:socket_chat_client/models/whiteboard/socket/whiteboard_socket_event.dart';
import 'package:socket_chat_client/models/whiteboard/socket/whiteboard_socket_event_payload.dart';
import 'package:web_socket_channel/io.dart';
import '../models/user.dart';
import '../models/whiteboard/api/drawn.dart';
import '../models/whiteboard/api/point.dart';
import '../models/whiteboard/api/whiteboard.dart';
import '../models/whiteboard/api/whiteboard_request.dart';
import '../services/api_service.dart';
import '../services/local_storage_service.dart';

class WhiteboardProvider extends ChangeNotifier {
  WhiteboardChangeCallback? whiteboardChanged;

  Whiteboard? _whiteboard;
  int? _currentUserId;
  User? _otherSideUser;

  Whiteboard? get whiteboard => _whiteboard;

  User? get otherSideUser => _otherSideUser;

  IOWebSocketChannel? _socketChannel;

  IOWebSocketChannel? get socketChannel => _socketChannel;

  var logger = Logger();

  void setWhiteboard(
      {Whiteboard? whiteboard,
      int? currentUserId,
      bool notify = true,
      initSocket = true,
      User? otherSideUser}) async {

    _whiteboard = whiteboard;
    if (whiteboard != null) whiteboardChanged?.call(whiteboard);

    _currentUserId = currentUserId;
    _otherSideUser = otherSideUser;

    if (notify) notifyListeners();

    if (initSocket) await _initWebSocket();
  }

  Future<void> initWebSocket() async {
    await _initWebSocket();
  }

  Future<void> _initWebSocket() async {
    String? apiHost = await LocalStorage.getString('api_host')
        .then((value) => value == null ? '10.0.2.2' : value.trim());
    String? jwtToken = await LocalStorage.getString('jwt_token');
    if (jwtToken == null || apiHost == null || _whiteboard == null) {
      logger.i(
          "Failed to init web socket because jwtToken, apiHost or whiteboard is null\n"
          "jwtToken: $jwtToken\napiHost: $apiHost\nwhiteboard: $_whiteboard");
      return;
    }
    String socketUrl = 'ws://$apiHost:8000/ws/whiteboard?id=${_whiteboard!.id}';
    _socketChannel = IOWebSocketChannel.connect(
      Uri.parse(socketUrl),
      headers: {
        'Authorization': jwtToken,
      },
    );
    await _socketChannel?.ready;
    _handleSocketEvents();
  }

  void _handleSocketEvents() {
    _socketChannel?.stream.listen((event) {
      final decodedEvent = WhiteboardSocketEvent.fromJson(jsonDecode(event));
      logger.d("decodedEvent: ${decodedEvent.payload.whiteboardId}");
      switch (decodedEvent.event) {
        case 'update_whiteboard':
          _handleUpdateWhiteboardEvent(decodedEvent);
          break;
        default:
          logger.i("Unknown whiteboard socket event: ${decodedEvent.event}");
          break;
      }
    });
  }

  void _handleUpdateWhiteboardEvent(WhiteboardSocketEvent event) {
    if (event.payload.drawerUserId == _currentUserId) {
      return;
    }
    final drawn = Drawn(
      id: event.payload.id,
      whiteboardId: event.payload.whiteboardId,
      drawerUserId: event.payload.drawerUserId,
      points: event.payload.points,
    );
    _updateOtherSidePoints(drawn);
  }

  void sendUpdateWhiteboardSocketEvent(Drawn drawn) {
    final payload = WhiteboardSocketEventPayload(
        id: drawn.id,
        whiteboardId: drawn.whiteboardId,
        drawerUserId: drawn.drawerUserId,
        points: drawn.points);
    final event =
        WhiteboardSocketEvent(event: "update_whiteboard", payload: payload);

    if (_socketChannel == null ||
        _socketChannel?.sink == null ||
        _socketChannel?.closeCode != null) {
    } else {
      _socketChannel?.sink.add(jsonEncode(event.toMap()));
    }
  }

  void _updateOtherSidePoints(Drawn drawn) {
    if (_whiteboard == null) return;
    _updateOtherSideDrawn(drawn);
    notifyListeners();
  }

  void updateMySidePoints({Offset? offset, bool sendEvent = true}) {
    if (_whiteboard == null) return;
    _updateMyDrawn(offset, sendEvent);
    notifyListeners();
  }

  void _updateMyDrawn(Offset? offset, bool sendEvent) {
    for (var drawn in _whiteboard!.drawns!) {
      if (drawn.drawerUserId == _currentUserId) {
        drawn.points ??= [];
        if (offset == null) {
          drawn.points?.add(null);
        } else {
          drawn.points?.add(Point.fromOffset(offset));
        }
        if (sendEvent) sendUpdateWhiteboardSocketEvent(drawn);
        break;
      }
    }
  }

  void _updateOtherSideDrawn(Drawn drawn) {
    for (int i = 0; i < _whiteboard!.drawns!.length; i++) {
      if (_whiteboard!.drawns![i].drawerUserId == drawn.drawerUserId) {
        drawn.points ??= [];
        _whiteboard!.drawns![i].points = drawn.points;
        break;
      }
    }
  }

  Future<void> createOrGetExistingWhiteboard(
      int conversationId, currentUserId, User? otherSideUser) async {
    await Future.delayed(const Duration(seconds: 1));
    String? jwtToken = await LocalStorage.getString('jwt_token');
    if (jwtToken == null) {
      logger.e("createWhiteboard: jwtToken is null");
      return;
    }
    var request = WhiteboardRequest(conversationId: conversationId);
    var whiteboard = await ApiService.createWhiteboard(jwtToken, request);
    if (whiteboard != null) {
      setWhiteboard(
          whiteboard: whiteboard,
          currentUserId: currentUserId,
          otherSideUser: otherSideUser);
    }
  }

  void clear() {
    setWhiteboard(whiteboard: null, notify: false, initSocket: false);
    _socketChannel?.sink.close(1000, "Connection closed");
    _socketChannel = null;
  }

  @override
  void dispose() {
    clear();
    super.dispose();
  }
}
