import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:web_socket_channel/io.dart';
import '../models/conversation.dart';
import '../models/observing_event.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/local_storage_service.dart';
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

  late int _currentUserId;

  void initialize(String token, int currentUserId) async {
    _currentUserId = currentUserId;
    await _fetchPageContent(token);
    List<int> notifiers = [];
    // Add all discoverable users to notifiers
    if (_discoverableUsers != null && _discoverableUsers!.isNotEmpty) {
      for (var notifier in _discoverableUsers!) {
        notifiers.add(notifier.id);
      }
    }
    // Add all conversation users to notifiers
    if (_conversations.isNotEmpty) {
      for (var conversation in _conversations) {
        for (var user in conversation.members) {
          if (user.id == _currentUserId) continue;
          notifiers.add(user.id);
        }
      }
    }
    logger.i('notifiers: $notifiers');
    await _initializeWithSocket(token, notifiers);
  }

  Future<void> _fetchPageContent(String token) async {
    await _fetchDiscoverableUsers(token);
    await _fetchConversations(token);
  }

  Future<void> _initializeWithSocket(
      String jwtToken, List<int> notifiers) async {
    String? apiHost = await LocalStorage.getString('api_host')
        .then((value) => value == null ? '10.0.2.2' : value.trim());
    String socketUrl =
        'ws://$apiHost:8000/ws/observe?notifiers=${notifiers.join(",")}';
    _socketChannel = IOWebSocketChannel.connect(
      Uri.parse(socketUrl),
      headers: {
        'Authorization': jwtToken,
      },
    );
    await _socketChannel.ready;
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
    // Update user online status in discoverable users list
    if (_discoverableUsers != null && _discoverableUsers!.isNotEmpty) {
      _discoverableUsers!
          .firstWhere((user) => user.id == event.payload.userId)
          .isOnline = event.payload.isOnline;
    }
    // Update user online status in conversations list
    // Todo...
    notifyListeners();
  }

  Future<void> _fetchConversations(String token) async {
    _conversations = await ApiService.fetchConversations(token);
    await Utils.setConversationsMembersListProfilePhotosURl(_conversations);
    _isConversationsFetching = false;
    notifyListeners();
  }

  Future<Conversation?> createConversation(
      String token, List<int> userIds) async {
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
    logger.i('_fetchDiscoverableUsers called');
    _discoverableUsers = await ApiService.discoverUsers(token);
    logger.i('_fetchDiscoverableUsers _discoverableUsers fetched');
    await Utils.setUsersListProfilePhotosURl(_discoverableUsers);
    _isDiscoverableUsersFetching = false;
    notifyListeners();
    return;
  }

  @override
  void dispose() {
    _socketChannel.sink.close();
    super.dispose();
  }
}
