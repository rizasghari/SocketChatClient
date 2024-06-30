import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:web_socket_channel/io.dart';
import '../models/whiteboard/api/drawing_paint.dart';
import '../callbacks/whiteboard_change_callback.dart';
import '../models/whiteboard/api/sub_drawn.dart';
import '../models/whiteboard/socket/whiteboard_event.dart';
import '../models/whiteboard/socket/whiteboard_payload.dart';
import '../models/user.dart';
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

  DrawingPaint selectedPaint = DrawingPaint(
    color: Colors.orange.value,
    strokeWidth: 5.0,
    strokeCap: StrokeCap.butt.name,
    strokeJoin: StrokeJoin.miter.name,
    paintingStyle: PaintingStyle.fill.name,
    filterQuality: FilterQuality.none.name,
    blendMode: BlendMode.srcOver.name,
    isAntiAlias: true,
  );

  List<Point> currentDrawing = [];

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
    if (initSocket) await initWebSocket();
  }

  Future<void> initWebSocket() async {
    String? apiHost = await LocalStorage.getString('api_host')
        .then((value) => value == null ? '10.0.2.2' : value.trim());
    String? jwtToken = await LocalStorage.getString('jwt_token');
    if (jwtToken == null || apiHost == null || _whiteboard == null) return;
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
      final decodedEvent = WhiteboardEvent.fromJson(jsonDecode(event));
      logger.d("decodedEvent: ${decodedEvent.payload}");
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

  void _handleUpdateWhiteboardEvent(WhiteboardEvent event) {
    if (_whiteboard == null || event.payload.drawerUserId == _currentUserId) {
      return;
    }
    _updateOtherSidePoints(event.payload);
  }

  void _updateOtherSidePoints(WhiteboardPayload payload) {
    for (int i = 0; i < _whiteboard!.drawns.length; i++) {
      if (_whiteboard!.drawns[i].drawerUserId == payload.drawerUserId) {
        var subDrawn = SubDrawn(
            id: payload.subDrawnId,
            drawnId: payload.drawnId,
            points: payload.points,
            paint: payload.paint);
        _whiteboard!.drawns[i].subDrawns ??= [];
        _whiteboard!.drawns[i].subDrawns!.add(subDrawn);
        notifyListeners();
        break;
      }
    }
  }

  void updateMySidePoints(
      {Offset offset = Offset.zero, bool sendEvent = true}) {
    if (_whiteboard == null) return;
    for (int i = 0; i < _whiteboard!.drawns.length; i++) {
      if (_whiteboard!.drawns[i].drawerUserId == _currentUserId) {
        if (sendEvent) {
          logger.i("before: currentDrawing length: ${currentDrawing.length}");
          var subDrawn = SubDrawn(
              drawnId: _whiteboard!.drawns[i].id,
              points: currentDrawing,
              paint: selectedPaint);
          _whiteboard!.drawns[i].subDrawns ??= [];
          _whiteboard!.drawns[i].subDrawns!.add(subDrawn);
          logger.i("SubDrawns: ${_whiteboard!.drawns[i].subDrawns!.length}");
          sendUpdateWhiteboardSocketEvent(subDrawn);
          notifyListeners();
        } else {
          currentDrawing.add(Point.fromOffset(offset));
        }
        break;
      }
    }
  }

  void sendUpdateWhiteboardSocketEvent(SubDrawn subDrawn) {
    var payload = WhiteboardPayload(
        drawnId: subDrawn.drawnId,
        drawerUserId: _currentUserId!,
        whiteboardId: _whiteboard!.id,
        points: subDrawn.points,
        paint: subDrawn.paint);
    final event = WhiteboardEvent(event: "update_whiteboard", payload: payload);
    if (_socketChannel == null ||
        _socketChannel?.sink == null ||
        _socketChannel?.closeCode != null) {
    } else {
      _socketChannel?.sink.add(jsonEncode(event.toMap()));
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
