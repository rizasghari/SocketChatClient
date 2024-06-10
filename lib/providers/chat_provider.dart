import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import '../models/message.dart';
import '../models/user.dart';

class ChatProvider extends ChangeNotifier {
  late User user;
  late int conversationId;
  late WebSocketChannel channel;
  final List<Message> _messages = [];

  void initialize(User user, int conversationId, WebSocketChannel channel) {
    this.user = user;
    this.conversationId = conversationId;
    this.channel = channel;
    channel.stream.listen((message) {
      final decodedMessage = Message.fromJson(jsonDecode(message)['payload']);
      if (decodedMessage.conversationId == conversationId) {
        _messages.add(decodedMessage);
        notifyListeners();
      }
    });
  }

  List<Message> get messages => _messages;

  void sendMessage(String content) {
    final message = {
      "event": "send_message",
      "conversation_id": conversationId,
      "payload": {
        "content": content,
      }
    };
    channel.sink.add(jsonEncode(message));
  }

  @override
  void dispose() {
    channel.sink.close(status.goingAway);
    super.dispose();
  }
}
