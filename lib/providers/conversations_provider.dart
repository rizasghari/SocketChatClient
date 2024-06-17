import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../models/conversation.dart';
import '../services/api_service.dart';
import '../utils.dart';

class ConversationsProvider extends ChangeNotifier {
  List<Conversation> _conversations = [];

  List<Conversation> get conversations => _conversations;
  
  static Logger logger = Logger();

  Future<void> fetchConversations(String token) async {
    _conversations = await ApiService.fetchConversations(token);
    await Utils.setConversationsMembersListProfilePhotosURl(_conversations);
    notifyListeners();
  }

  Future<Conversation?> createConversation(String token, List<int> userIds) async {
    await Future.delayed(const Duration(seconds: 2));
    var conversation = await ApiService.createConversation(token, userIds);
    if (conversation != null) {
      _conversations.add(conversation);
      await Utils.setConversationsMembersListProfilePhotosURl(_conversations);
    }
    await fetchConversations(token);
    notifyListeners();
    return conversation;
  }
}
