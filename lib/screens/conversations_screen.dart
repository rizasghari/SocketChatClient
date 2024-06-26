import 'dart:async';

import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:socket_chat_client/models/conversation.dart';
import 'package:socket_chat_client/providers/whiteboard_provider.dart';
import '../models/message.dart';
import '../utils.dart';
import 'authentication/login_screen.dart';
import '../services/local_storage_service.dart';
import '../providers/conversations_provider.dart';
import 'chat_screen.dart';

class ConversationsListScreen extends StatefulWidget {
  ConversationsListScreen({super.key});

  final Logger logger = Logger();

  @override
  State<ConversationsListScreen> createState() =>
      _ConversationsListScreenState();
}

class _ConversationsListScreenState extends State<ConversationsListScreen> {
  ConversationsProvider? _conversationsProvider;
  WhiteboardProvider? _whiteboardProvider;
  int? _currentUserID;
  String? jwtToken;
  bool _isLoading = false;
  int _discoverableUserIndex = -1;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    jwtToken = await LocalStorage.getString('jwt_token');
    if (jwtToken == null) {
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => LoginScreen(from: "Conversations"),
        ),
      );
    }

    _currentUserID = await LocalStorage.getInt('user_id');
    if (_currentUserID == null) {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    if (!mounted) return;
    _conversationsProvider =
    Provider.of<ConversationsProvider>(context, listen: false)
      ..initialize(jwtToken!, _currentUserID!);

    // Update conversation whiteboard if any changes.
    // It's possible that new whiteboard is created and user joined conversation
    // so we need to update whiteboard here
    _whiteboardProvider =
    Provider.of<WhiteboardProvider>(context, listen: false)
      ..whiteboardChanged = (whiteboard) {
        if (_whiteboardProvider == null || _whiteboardProvider!.whiteboard == null) return;
        _conversationsProvider?.setConversationWhiteboard(whiteboard);
      };
  }

  Future<void> _createConversation(List<int> ids) async {
    Conversation? conversation =
    await _conversationsProvider!.createConversation(jwtToken!, ids);
    setState(() {
      _isLoading = false;
    });
    if (conversation != null && mounted) {
      _conversationsProvider!.discoverableUsers!
          .removeAt(_discoverableUserIndex);
      setState(() {
        _discoverableUserIndex = -1;
      });
      _conversationsProvider!.setCurrentConversationInChat(conversation, false);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const ChatScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Conversations'),
      ),
      bottomNavigationBar: _navigationBar(),
      drawer: const Drawer(
        child: DrawerHeader(
          decoration: BoxDecoration(
            color: Colors.blue,
          ),
          child: SizedBox(
            width: double.infinity,
            height: 100.0,
            child: Center(
              child: Text(
                'Drawer Header',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
          ),
        ),
      ),
      body: _pageContent(),
    );
  }

  NavigationBar _navigationBar() {
    return NavigationBar(
      destinations: const [
        NavigationDestination(
            icon: Icon(Icons.message), label: 'Conversations'),
        NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
      ],
      onDestinationSelected: (int index) {
        // Handle navigation
        if (index == 0) {
          Navigator.pushNamed(context, '/conversations');
        } else if (index == 1) {
          Navigator.pushNamed(context, '/profile');
        }
      },
      selectedIndex: 0,
    );
  }

  Widget _pageContent() {
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      color: Colors.white,
      backgroundColor: Colors.blue,
      child: Column(
        children: [
          Consumer<ConversationsProvider>(
            builder: (context, discoverUsersProvider, child) {
              return discoverUsersProvider.isDiscoverableUsersFetching
                  ? const Center(child: CircularProgressIndicator())
                  : _discoverableUsers();
            },
          ),
          Expanded(
            child: Consumer<ConversationsProvider>(
              builder: (context, conversationsProvider, child) {
                return conversationsProvider.isConversationsFetching
                    ? const Center(child: CircularProgressIndicator())
                    : _conversationsList(conversationsProvider);
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleRefresh() async {
    _initialize();
  }

  Widget _discoverableUsers() {
    if (_conversationsProvider == null ||
        _conversationsProvider!.discoverableUsers == null ||
        _conversationsProvider!.discoverableUsers!.isEmpty) {
      return _noDiscoverableUsers();
    }
    return _discoverableUsersList();
  }

  Widget _noDiscoverableUsers() {
    return Container();
  }

  Widget _discoverableUsersList() {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _conversationsProvider!.discoverableUsers!.length,
        itemBuilder: (context, index) {
          final user = _conversationsProvider!.discoverableUsers![index];
          return GestureDetector(
            onTap: () {
              setState(() {
                _discoverableUserIndex = index;
                _isLoading = true;
              });
              _createConversation([user.id, _currentUserID!]);
            },
            child: Container(
              width: 85,
              margin: const EdgeInsets.all(5.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      CircleAvatar(
                        radius: 30.0,
                        backgroundImage: user.profilePhoto != null
                            ? NetworkImage(user.profilePhoto!)
                            : null,
                        child: user.profilePhoto == null
                            ? const Icon(Icons.person)
                            : null,
                      ),
                      _isLoading && _discoverableUserIndex == index
                          ? _createingConversationIndicator()
                          : const SizedBox.shrink()
                    ],
                  ),
                  const SizedBox(height: 5.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: user.isOnline! ? Colors.green : Colors.grey,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5.0),
                      Flexible(
                        child: Text(
                          "${user.firstName} ${user.lastName}",
                          overflow: TextOverflow.fade,
                          maxLines: 1,
                          softWrap: false,
                          style: const TextStyle(
                            fontSize: 12.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _createingConversationIndicator() {
    return const Positioned(
      child: SizedBox(
          width: 20.0,
          height: 20.0,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2.0,
          )),
    );
  }

  Widget _conversationsList(ConversationsProvider conversationsProvider) {
    if (conversationsProvider.conversations.isEmpty) {
      return _noConversation();
    }
    return ListView.separated(
      separatorBuilder: (context, index) {
        return const Divider(
          thickness: 0.2,
          height: 1.0,
          color: Colors.grey,
          indent: 70.0,
        );
      },
      itemCount: conversationsProvider.conversations.length,
      itemBuilder: (context, index) {
        final conversation = conversationsProvider.conversations[index];
        return ListTile(
          leading: _conversationItemUserProfilePhoto(conversation),
          title: _conversationItemTitle(conversation),
          subtitle: _conversationItemLastMessage(conversation),
          trailing: _conversationItemTrailing(conversation),
          isThreeLine: false,
          onTap: () {
            conversationsProvider.setCurrentConversationInChat(
                conversation, false);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ChatScreen(),
              ),
            );
          },
        );
      },
    );
  }

  Widget _conversationItemTrailing(Conversation conversation) {
    DateTime? lastMessageTime = conversation.lastMessage?.createdAt;
    var time = lastMessageTime != null
        ? Utils.getConciseFormattedDate(lastMessageTime)
        : "";
    var unread = conversation.unread?.toString();
    if (time.isNotEmpty) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            time,
            style: TextStyle(color: Colors.grey[600], fontSize: 10.0),
          ),
          const SizedBox(height: 3.0),
          unread != null && unread != "0"
              ? Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(
              color: Colors.deepPurpleAccent,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                unread,
                style:
                const TextStyle(color: Colors.white, fontSize: 8.0),
              ),
            ),
          )
              : const SizedBox(
            width: 25,
            height: 25,
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  Widget _noConversation() {
    return const Center(
      child: Text('No conversations found.'),
    );
  }

  Widget _conversationItemUserProfilePhoto(Conversation conversation) {
    String? photo;
    for (var member in conversation.members) {
      if (member.id != _currentUserID) {
        photo = member.profilePhoto;
        break;
      }
    }
    return CircleAvatar(
      radius: 25,
      backgroundImage: photo != null ? NetworkImage(photo) : null,
      child: photo == null ? const Icon(Icons.person) : null,
    );
  }

  Widget _conversationItemLastMessage(Conversation conversation) {
    Message? lastMessage = conversation.lastMessage;
    var lastMessageText = "";
    late bool isMe;
    Color color = Colors.grey;
    if (lastMessage == null) {
      lastMessageText = "Send first message";
      color = Colors.blueAccent;
      isMe = false;
    } else {
      if (lastMessage.senderId == _currentUserID) {
        isMe = true;
        lastMessageText = 'You: ${lastMessage.content}';
      } else {
        isMe = false;
        lastMessageText = lastMessage.content;
      }
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        lastMessage != null && isMe
            ? Icon(
            lastMessage.seenAt == null
                ? Icons.check_circle_outline
                : Icons.check_circle,
            size: 16.0,
            color: Colors.grey)
            : const SizedBox(width: 0.0),
        const SizedBox(width: 5.0),
        Flexible(
          child: Text(
            lastMessageText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: color, fontSize: 12.0),
          ),
        ),
      ],
    );
  }

  Widget _conversationItemTitle(Conversation conversation) {
    var title = "";
    var isOnline = false;
    for (var member in conversation.members) {
      if (member.id != _currentUserID) {
        title = "${member.firstName} ${member.lastName}";
        isOnline = member.isOnline!;
        break;
      }
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: isOnline ? Colors.green : Colors.grey,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5.0),
        Flexible(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14.0,
                fontWeight: FontWeight.bold,
                // color: Colors.black,
                color: conversation.whiteboard != null ? Colors.blue : Colors.black,
              ),
            )),
      ],
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
