import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:scrollview_observer/scrollview_observer.dart';
import 'package:socket_chat_client/providers/conversations_provider.dart';
import 'package:socket_chat_client/providers/whiteboard_provider.dart';
import '../models/conversation.dart';
import '../models/message.dart';
import '../models/user.dart';
import '../models/whiteboard/api/whiteboard.dart';
import '../services/local_storage_service.dart';
import 'package:web_socket_channel/io.dart';
import '../providers/chat_provider.dart';
import '../utils.dart';
import 'authentication/login_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  IOWebSocketChannel? _socketChannel;

  ChatProvider? _chatProvider;
  ConversationsProvider? _conversationsProvider;
  WhiteboardProvider? _whiteboardProvider;

  int? _currentUserID;
  User? _otherSideUser;

  late String? jwtToken;

  Timer? _timer;

  Logger logger = Logger();

  @override
  void initState() {
    super.initState();
    _initializeAsync();
  }

  Future<void> _initializeAsync() async {
    jwtToken = await LocalStorage.getString('jwt_token');
    if (jwtToken == null) {
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => LoginScreen(from: "Chat Screen"),
        ),
      );
      return;
    }

    if (!mounted) return;
    _conversationsProvider =
        Provider.of<ConversationsProvider>(context, listen: false);
    if (_conversationsProvider == null ||
        _conversationsProvider!.currentConversationInChat == null) {
      Navigator.pop(context);
    }

    _conversationsProvider!.addListener(() {
      if (!mounted) return;
      setState(() {
        if (_conversationsProvider == null) {
          Navigator.pop(context);
          return;
        }
        _otherSideUser = _conversationsProvider!
            .currentConversationInChat!.members
            .firstWhere((user) => user.id != _currentUserID);
      });
    });

    _currentUserID = await LocalStorage.getInt('user_id');
    if (_currentUserID == null && mounted) {
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    _otherSideUser = _conversationsProvider!.currentConversationInChat!.members
        .firstWhere((user) => user.id != _currentUserID);

    String? apiHost = await LocalStorage.getString('api_host')
        .then((value) => value == null ? '10.0.2.2' : value.trim());

    String socketUrl =
        'ws://$apiHost:8000/ws/chat?conversationId=${_conversationsProvider!.currentConversationInChat!.id}';
    _socketChannel = IOWebSocketChannel.connect(
      Uri.parse(socketUrl),
      headers: {
        'Authorization': jwtToken,
      },
    );
    if (_socketChannel == null) return;
    await _socketChannel?.ready;

    if (!mounted) return;
    _chatProvider = Provider.of<ChatProvider>(context, listen: false)
      ..initialize(_conversationsProvider!.currentConversationInChat!.id,
          _socketChannel!, _currentUserID!);

    _whiteboardProvider =
        Provider.of<WhiteboardProvider>(context, listen: false);
    if (_conversationsProvider!.currentConversationInChat!.whiteboard != null) {
      _setWhiteboard(
          _conversationsProvider!.currentConversationInChat!.whiteboard!);
    }

    if (_chatProvider != null) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        _chatProvider?.addListener(() {
          if (_chatProvider?.messages.isNotEmpty == true) {
            // _scrollToBottom();
          }
        });
      });
      _chatProvider!.fetchConversationMessages(
          jwtToken!, _conversationsProvider!.currentConversationInChat!.id);
    }
    setState(() {});
  }

  Future<void> _createOrGetExistingWhiteboard(int currentUserID) async {
    if (_whiteboardProvider == null ||
        _conversationsProvider == null ||
        _conversationsProvider!.currentConversationInChat == null ||
        _otherSideUser == null) return;

    Utils.showLoadingDialog(context,
        "Joining live whiteboard with ${_otherSideUser!.firstName}...");

    await _whiteboardProvider?.createOrGetExistingWhiteboard(
        _conversationsProvider!.currentConversationInChat!.id,
        currentUserID,
        _otherSideUser);

    if (mounted) {
      _closeLoadingDialog();
      Navigator.pushNamed(context, "/whiteboard");
    }
  }

  void _setWhiteboard(Whiteboard whiteboard) {
    _whiteboardProvider!.setWhiteboard(
        whiteboard: whiteboard,
        currentUserId: _currentUserID,
        otherSideUser: _otherSideUser,
        initSocket: false);
  }

  void _scrollToBottom() {
    _scrollController.animateTo(
      _scrollController.position.minScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  Widget _pageIsLoading() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _userProfile() {
    var isOnline = _otherSideUser?.isOnline ?? false;
    String? lastSeen;
    if (_otherSideUser?.lastSeenAt != null) {
      lastSeen = Utils.getFormattedDate(_otherSideUser!.lastSeenAt!);
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 20,
          backgroundImage: _otherSideUser!.profilePhoto != null
              ? NetworkImage(_otherSideUser!.profilePhoto!)
              : null,
          child: _otherSideUser!.profilePhoto == null
              ? const Icon(Icons.person)
              : null,
        ),
        const SizedBox(width: 8),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isOnline ? Colors.green : Colors.grey,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${_otherSideUser!.firstName} ${_otherSideUser!.lastName}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ]),
            !isOnline &&
                    !Provider.of<ChatProvider>(context).otherSideUserIsTyping &&
                    lastSeen != null
                ? Text(
                    "Last seen at: $lastSeen",
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                    overflow: TextOverflow.ellipsis,
                  )
                : Container(),
            isOnline && Provider.of<ChatProvider>(context).otherSideUserIsTyping
                ? const Text(
                    "Is typing...",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                    overflow: TextOverflow.ellipsis,
                  )
                : Container()
          ],
        ),
      ],
    );
  }

  void _closeLoadingDialog() {
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  AppBar _appBar() {
    return AppBar(
      title: _userProfile(),
      elevation: 4.0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          Navigator.pop(context);
        },
      ),
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue, Colors.purple],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(
            Icons.brush,
            color: Colors.white,
            size: 18,
          ),
          onPressed: () {
            if (_whiteboardProvider!.whiteboard == null &&
                _currentUserID != null) {
              logger.i("Creating new whiteboard");
              _createOrGetExistingWhiteboard(_currentUserID!);
            } else {
              logger.i(
                  "Navigating to whiteboard ${_whiteboardProvider!.whiteboard!.id}");
              Navigator.pushNamed(context, "/whiteboard");
            }
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_chatProvider == null) {
      return _pageIsLoading();
    }
    return ChangeNotifierProvider.value(
        value: _chatProvider,
        child: Scaffold(
          appBar: _appBar(),
          body: Column(
            children: [
              Expanded(
                child: Consumer<ChatProvider>(
                  builder: (context, chatProvider, child) {
                    if (chatProvider.isFetching) {
                      return const Center(
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                    if (chatProvider.messages.isEmpty) {
                      return const Center(
                        child: Center(
                          child: Text("No messages found"),
                        ),
                      );
                    }
                    return ListViewObserver(
                      child: ListView.builder(
                        controller: _scrollController,
                        itemCount: chatProvider.messages.length,
                        reverse: true,
                        itemBuilder: (context, index) {
                          final message = chatProvider.messages[index];
                          final isMe = message.senderId == _currentUserID;
                          return _messageItem(message, isMe);
                        },
                      ),
                      onObserve: (resultMap) {
                        List<int> seenList = resultMap.displayingChildIndexList;
                        if (seenList.isEmpty) {
                          return;
                        }
                        chatProvider.handleSeenMessages(seenList);
                      },
                    );
                  },
                ),
              ),
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue, Colors.purple],
                    begin: Alignment.bottomRight,
                    end: Alignment.topLeft,
                  ),
                ),
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        onChanged: (value) {
                          if (_timer?.isActive ?? false) _timer?.cancel();
                          _timer = Timer(const Duration(milliseconds: 500), () {
                            if (value.isNotEmpty) {
                              Provider.of<ChatProvider>(context, listen: false)
                                  .sendIsTypingSocketEvent(
                                      true, _currentUserID!);
                            } else {
                              Provider.of<ChatProvider>(context, listen: false)
                                  .sendIsTypingSocketEvent(
                                      false, _currentUserID!);
                            }
                          });
                        },
                        controller: _controller,
                        style: const TextStyle(
                          color: Colors.white,
                        ),
                        decoration: const InputDecoration(
                            labelText: 'Send a message',
                            labelStyle: TextStyle(color: Colors.white70)),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send,
                          color: Colors.white, size: 30.0),
                      onPressed: () {
                        if (_controller.text.isNotEmpty) {
                          Provider.of<ChatProvider>(context, listen: false)
                              .sendMessage(_controller.text);
                          Provider.of<ChatProvider>(context, listen: false)
                              .sendIsTypingSocketEvent(false, _currentUserID!);
                          _controller.clear();
                          _scrollController.animateTo(
                            0.0,
                            duration: const Duration(milliseconds: 100),
                            curve: Curves.easeOut,
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ));
  }

  ListTile _messageItem(Message message, bool isMe) {
    return ListTile(
      title: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
              decoration: BoxDecoration(
                color: isMe ? Colors.blue : Colors.grey[300],
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Column(
                crossAxisAlignment:
                    isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: TextStyle(color: isMe ? Colors.white : Colors.black),
                  ),
                  const SizedBox(height: 4.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        Utils.getFormattedDate(message.createdAt),
                        style: TextStyle(
                          fontSize: 12.0,
                          color: isMe ? Colors.white60 : Colors.black38,
                        ),
                      ),
                      isMe
                          ? const SizedBox(width: 5.0)
                          : const SizedBox(width: 0.0),
                      isMe
                          ? Icon(
                              message.seenAt == null
                                  ? Icons.check_circle_outline
                                  : Icons.check_circle,
                              size: 16.0,
                              color: Colors.white60)
                          : const SizedBox(width: 0.0),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    logger.i("ChatScreen disposed");
    _conversationsProvider?.setCurrentConversationInChat(null, true);
    _chatProvider?.reset();
    _controller.dispose();
    _scrollController.dispose();
    _timer?.cancel();
    _whiteboardProvider?.clear();
    super.dispose();
  }
}
