import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
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
          logger.d("event update_whiteboard");
          _handleUpdateWhiteboardEvent(decodedEvent);
          break;
        default:
          logger.i("Unknown whiteboard socket event: ${decodedEvent.event}");
          break;
      }
    });
  }

  void _handleUpdateWhiteboardEvent(WhiteboardSocketEvent event) {
    logger
        .d("_handleUpdateWhiteboardEvent / event: ${event.payload.toString()}");
    logger.d("_handleUpdateWhiteboardEvent / _currentUserId: $_currentUserId");
    if (event.payload.drawerUserId == _currentUserId) {
      logger.i("_handleUpdateWhiteboardEvent / Own side update, ignore");
      return;
    }
    logger.d(
        "_handleUpdateWhiteboardEvent / other side event: ${event.payload.toString()}");
    final drawn = Drawn(
      whiteboardId: event.payload.whiteboardId,
      drawerUserId: event.payload.drawerUserId,
      points: event.payload.points,
    );
    _updateOtherSidePoints(drawn);
  }

  void sendUpdateWhiteboardSocketEvent(Drawn drawn) {
    final payload = WhiteboardSocketEventPayload(
        whiteboardId: drawn.whiteboardId,
        drawerUserId: drawn.drawerUserId,
        points: drawn.points);
    final event =
        WhiteboardSocketEvent(event: "update_whiteboard", payload: payload);
    logger.d("event: $event");

    if (_socketChannel == null ||
        _socketChannel?.sink == null ||
        _socketChannel?.closeCode != null) {
      logger.e("sendUpdateWhiteboardSocketEvent: Lost connection to socket");
    } else {
      _socketChannel?.sink.add(jsonEncode(event.toMap()));
    }
  }

  void _updateOtherSidePoints(Drawn drawn) {
    if (_whiteboard == null) return;

    logger.t("Whiteboard Drawns length: ${_whiteboard?.drawns?.length}");

    if (_whiteboard!.drawns == null || _whiteboard!.drawns!.isEmpty) {
      logger.d("_updateOtherSidePoints C1");
      _createOtherSideDrawnForFirstTime(drawn);
    } else if (_whiteboard!.drawns!.length == 1) {
      if (_whiteboard!.drawns![0].drawerUserId != _currentUserId) {
        logger.d("_updateOtherSidePoints C2.1");
        _updateOtherSideExistingDrawn(drawn);
      } else {
        logger.d("_updateOtherSidePoints C2.2");
        _createOtherSideDrawnForFirstTime(drawn);
      }
    } else if (_whiteboard!.drawns!.length > 1) {
      logger.d("_updateOtherSidePoints C3");
      _updateOtherSideExistingDrawn(drawn);
    } else {
      logger.d("_updateOtherSidePoints C4");
    }

    notifyListeners();
  }

  void updateMySidePoints({Offset? offset, bool sendEvent = true}) {
    if (_whiteboard == null) return;
    if (_whiteboard!.drawns == null || _whiteboard!.drawns!.isEmpty) {
      _createMyDrawnForFirstTime(offset, sendEvent);
    } else if (_whiteboard!.drawns!.length == 1) {
      if (_whiteboard!.drawns![0].drawerUserId == _currentUserId) {
        _updateMyExistingDrawn(offset, sendEvent);
      } else {
        _createMyDrawnForFirstTime(offset, sendEvent);
      }
    } else if (_whiteboard!.drawns!.length > 1) {
      _updateMyExistingDrawn(offset, sendEvent);
    }

    notifyListeners();
  }

  void _updateMyExistingDrawn(Offset? offset, bool sendEvent) {
    for (var drawn in _whiteboard!.drawns!) {
      if (drawn.drawerUserId == _currentUserId) {
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

  void _createMyDrawnForFirstTime(Offset? offset, bool sendEvent) {
    if (_whiteboard == null) return;
    if (_whiteboard!.drawns == null || _whiteboard!.drawns!.isEmpty) {
      _whiteboard!.drawns = [];
    }
    var points = <Point?>[];
    if (offset != null) {
      points.add(Point.fromOffset(offset));
    } else {
      points.add(null);
    }
    var drawn = Drawn(
        whiteboardId: _whiteboard!.id,
        drawerUserId: _currentUserId!,
        points: points);
    _whiteboard!.drawns!.add(drawn);

    if (sendEvent) sendUpdateWhiteboardSocketEvent(drawn);
  }

  void _createOtherSideDrawnForFirstTime(Drawn drawn) {
    if (_whiteboard == null) return;
    logger.i("_createOtherSideDrawnForFirstTime / Drawn: ${drawn.toString()}");
    if (_whiteboard!.drawns == null || _whiteboard!.drawns!.isEmpty) {
      _whiteboard!.drawns = [];
    }
    _whiteboard!.drawns!.add(drawn);
    logger.t("Whiteboard Drawns length: ${_whiteboard?.drawns?.length}");
    notifyListeners();
  }

  void _updateOtherSideExistingDrawn(Drawn drawn) {
    logger
        .i("_updateOtherSideExistingDrawn / Input Drawn: ${drawn.toString()}");
    for (int i = 0; i < _whiteboard!.drawns!.length; i++) {
      logger.t("Exiting Drawn Item: ${_whiteboard?.drawns![i].toString()}");
      if (_whiteboard!.drawns![i].drawerUserId == drawn.drawerUserId) {
        logger.d("_updateOtherSideExistingDrawn");
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
      setWhiteboard(whiteboard: whiteboard, currentUserId: currentUserId);
    }
  }

  void clear() {
    logger.i("clear() / Before clear whiteboard id is: ${_whiteboard?.id}");
    setWhiteboard(whiteboard: null, notify: false);
    logger.i("clear() / After clear whiteboard id is: ${_whiteboard?.id}");
    _socketChannel?.sink.close(1000, "Connection closed");
    _socketChannel = null;
  }

  @override
  void dispose() {
    clear();
    super.dispose();
  }
}
