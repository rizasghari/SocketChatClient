import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:web_socket_channel/io.dart';
import '../models/conversation.dart';
import '../models/observing_event.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../utils.dart';

class ConversationsProvider extends ChangeNotifier {
  List<Conversation> _conversations = [];

  List<Conversation> get conversations => _conversations;
  bool _isConversationsFetching = true;

  bool get isConversationsFetching => _isConversationsFetching;
  late IOWebSocketChannel _socketChannel;
  List<User>? _discoverableUsers;

  List<User>? get discoverableUsers => _discoverableUsers;
  bool _isDiscoverableUsersFetching = true;

  bool get isDiscoverableUsersFetching => _isDiscoverableUsersFetching;

  Logger logger = Logger();

  void initialize(String token, IOWebSocketChannel socketChannel) {
    _socketChannel = socketChannel;
    _fetchDiscoverableUsers(token);
    _fetchConversations(token);
    _handleSocketEvents();
  }

  void _handleSocketEvents() {
    _socketChannel.stream.listen((event) {
      final decodedEvent = ObservingEvent.fromJson(jsonDecode(event));
      switch (decodedEvent.event) {
        case 'notify':
          _handleObservingEvent(decodedEvent);
          break;
        default:
          break;
      }
    });
  }

  void _handleObservingEvent(ObservingEvent event) {
    logger.i("_handleObservingEvent called with event: ${event.toString()}");
    notifyListeners();
  }

  Future<void> _fetchConversations(String token) async {
    await Future.delayed(const Duration(seconds: 2));
    _conversations = await ApiService.fetchConversations(token);
    await Utils.setConversationsMembersListProfilePhotosURl(_conversations);
    _isConversationsFetching = false;
    notifyListeners();
  }

  Future<Conversation?> createConversation(
      String token, List<int> userIds) async {
    await Future.delayed(const Duration(seconds: 2));
    var conversation = await ApiService.createConversation(token, userIds);
    if (conversation != null) {
      _conversations.add(conversation);
      await Utils.setConversationsMembersListProfilePhotosURl(_conversations);
    }
    await _fetchConversations(token);
    notifyListeners();
    return conversation;
  }

  Future<void> _fetchDiscoverableUsers(String token) async {
    await Future.delayed(const Duration(seconds: 2));
    _discoverableUsers = await ApiService.discoverUsers(token);
    await Utils.setUsersListProfilePhotosURl(_discoverableUsers);
    _isDiscoverableUsersFetching = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _socketChannel.sink.close();
    super.dispose();
  }
}
