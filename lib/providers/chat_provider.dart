import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../models/socket_event.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/status.dart' as status;
import '../models/is_typing.dart';
import '../models/message.dart';
import '../models/seen.dart';
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
        case 'seen_message':
          _handleSeenEvent(decodedEvent);
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

  void _handleSeenEvent(SocketEvent event) {
    logger.d("event: ${event.payload.toString()}");
    final seen = Seen.fromJson(event.payload);
    logger.d("seen: $seen");
    if (event.conversationId == conversationId) {
      logger.d("messageIds: ${seen.messageIds}");
      for (var messageId in seen.messageIds) {
        _messages
            .firstWhere((message) =>
                message.id == messageId && message.senderId == currentUserId)
            .seenAt = DateTime.now();
      }
      notifyListeners();
    }
  }

  void sendIsTypingSocketEvent(bool typingStatus, int userId) {
    logger.d(
        "sendIsTypingSocketEvent invoked with typingStatus:$typingStatus and userId:$userId");
    final isTypingPayload =
        IsTyping(typingStatus: typingStatus, userId: userId);
    final event = SocketEvent(
        event: "is_typing",
        conversationId: conversationId,
        payload: isTypingPayload.toMap());
    logger.d("event: $event");
    socketChannel.sink.add(jsonEncode(event.toMap()));
  }

  void sendMessagesSeenStatusSocketEvent(List<int> messages) {
    logger.d("setIsTyping invoked with messages:$messages");
    final seenPayload = Seen(messageIds: messages);
    final event = SocketEvent(
        event: "seen_message",
        conversationId: conversationId,
        payload: seenPayload.toMap());
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
    if (messageIndexes.isEmpty) return;

    logger.d("messageIndexes Before filter: $messageIndexes");
    messageIndexes.removeWhere((n) => n < 0 || n >= _messages.length);
    messageIndexes.removeWhere((n) => _messages[n].senderId == currentUserId);
    messageIndexes.removeWhere((n) => _messages[n].seenAt != null);
    logger.d("messageIndexes After filter: $messageIndexes");

    if (messageIndexes.isEmpty) return;

    List<int> messageIds =
        messageIndexes.map((index) => _messages[index].id).toList();
    logger.d("messageIds: $messageIds");

    sendMessagesSeenStatusSocketEvent(messageIds);

    for (int index in messageIndexes) {
      _messages[index].seenAt == DateTime.now();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    socketChannel.sink.close();
    super.dispose();
  }
}
