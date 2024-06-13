import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../models/conversation.dart';
import '../repositories/api_service.dart';

class ConversationsProvider extends ChangeNotifier {
  List<Conversation> _conversations = [];

  List<Conversation> get conversations => _conversations;
  
  static Logger logger = Logger();

  Future<void> fetchConversations(String token) async {
    logger.i('########################## Fetching conversations ##########################');
    logger.i('Fetching conversations with token: $token');
    _conversations = await ApiService.fetchConversations(token);
    notifyListeners();
  }
}
