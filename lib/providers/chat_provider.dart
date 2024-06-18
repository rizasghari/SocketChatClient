import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:socket_chat_client/models/socket_event.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/status.dart' as status;
import '../models/is_typing.dart';
import '../models/message.dart';
import '../services/api_service.dart';

class ChatProvider extends ChangeNotifier {
  late int conversationId;
  late int currentUserId;
  late IOWebSocketChannel socketChannel;
  final List<Message> _messages = [];
  bool _isFetching = true;
  bool _otherSideUserIsTyping = false;
  Logger logger = Logger();

  void initialize(
      int conversationId, IOWebSocketChannel socketChannel, int currentUserId) {
    this.conversationId = conversationId;
    this.socketChannel = socketChannel;
    this.currentUserId = currentUserId;
    _handleSocketEvents();
  }

  List<Message> get messages => _messages;

  bool get isFetching => _isFetching;

  bool get otherSideUserIsTyping => _otherSideUserIsTyping;

  void sendMessage(String content) {
    final event = {
      "event": "send_message",
      "conversation_id": conversationId,
      "payload": {
        "content": content,
      }
    };
    socketChannel.sink.add(jsonEncode(event));
  }

  void _handleSocketEvents() {
    socketChannel.stream.listen((event) {
      final decodedEvent = SocketEvent.fromJson(jsonDecode(event));
      switch (decodedEvent.event) {
        case 'send_message':
          _handleIncomingMessage(decodedEvent);
          break;
        case 'is_typing':
          _handleIsTypingEvent(decodedEvent);
          break;
        default:
          break;
      }
    });
  }

  void _handleIsTypingEvent(SocketEvent event) {
    logger.d("event: ${event.payload.toString()}");
    final isTyping = IsTyping.fromJson(event.payload);
    logger.d("isTyping: $isTyping");
    if (event.conversationId == conversationId &&
        isTyping.userId != currentUserId) {
      _otherSideUserIsTyping = isTyping.typingStatus;
      notifyListeners();
    }
  }

  void setIsTyping(bool typingStatus, userId) {
    logger.d("setIsTyping invoked with typingStatus:$typingStatus and userId:$userId");
    final isTypingPayload =
        IsTyping(typingStatus: typingStatus, userId: userId);
    final event = SocketEvent(
        event: "is_typing",
        conversationId: conversationId,
        payload: isTypingPayload.toMap());
    logger.d("event: $event");
    socketChannel.sink.add(jsonEncode(event.toMap()));
  }

  void _handleIncomingMessage(SocketEvent event) {
    final decodedMessage = Message.fromJson(event.payload);
    if (decodedMessage.conversationId == conversationId) {
      _messages.insert(0, decodedMessage);
      notifyListeners();
    }
  }

  Future<void> fetchConversationMessages(
      String jwtToken, int conversationId) async {
    await Future.delayed(const Duration(seconds: 1));
    final messages =
        await ApiService.fetchConversationMessages(jwtToken, conversationId);
    _isFetching = false;
    if (messages != null) {
      _messages.addAll(messages);
    }
    notifyListeners();
  }

  void reset() {
    _isFetching = true;
    _messages.clear();
    _otherSideUserIsTyping = false;
    socketChannel.sink.close(status.goingAway);
  }

  void handleSeenMessages(List<int> messageIndexes) {
    logger.d("handleSeenMessages invoked with messageIndexes:$messageIndexes");
    for (int index in messageIndexes) {
      // Check if the index is out of bounds
      if (index >= _messages.length || index < 0) {
        continue;
      }
      // Ignore own messages
      if (_messages[index].senderId == currentUserId) {
        continue;
      }
      // Check if the message has already been marked as read
      if (_messages[index].seenAt != null) {
        continue;
      }
      final message = _messages[index];
      message.seenAt = DateTime.now();
      notifyListeners();
    }
    // notifyListeners();
  }

  @override
  void dispose() {
    socketChannel.sink.close(status.goingAway);
    super.dispose();
  }
}
