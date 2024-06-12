import 'package:flutter/material.dart';
import '../models/conversation.dart';
import '../repositories/api_service.dart';

class ConversationsProvider extends ChangeNotifier {
  List<Conversation> _conversations = [];

  List<Conversation> get conversations => _conversations;

  Future<void> fetchConversations(String token) async {
    _conversations = await ApiService.fetchConversations(token);
    notifyListeners();
  }
}
