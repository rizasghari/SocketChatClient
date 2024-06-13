import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:socket_chat_flutter/repositories/local_storage.dart';
import 'package:web_socket_channel/io.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';

class ChatScreen extends StatefulWidget {
  final int conversationId;

  const ChatScreen({super.key, required this.conversationId});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  IOWebSocketChannel? _channel;
  ChatProvider? _chatProvider;

  @override
  void initState() {
    super.initState();
    _initializeWebSocket();
  }

  Future<void> _initializeWebSocket() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.loginResponse == null) {
      return;
    }
    final token = authProvider.loginResponse!.token;
    final user = authProvider.loginResponse!.user;

    String? apiHost = await LocalStorage.getString('api_host')
        .then((value) => value == null ? '10.0.2.2' : value.trim());

    String socketUrl =
        'ws://$apiHost:8000/ws?conversationId=${widget.conversationId}';

    _channel = IOWebSocketChannel.connect(
      Uri.parse(socketUrl),
      headers: {
        'Authorization': token,
      },
    );

    _chatProvider = ChatProvider()
      ..initialize(user, widget.conversationId, _channel!);

    // Scroll to bottom on new messages
    _chatProvider?.addListener(() {
      if (_chatProvider?.messages.isNotEmpty == true) {
        _scrollToBottom();
      }
    });

    setState(() {});
  }

  void _scrollToBottom() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _chatProvider?.dispose();
    _controller.dispose();
    _scrollController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_chatProvider == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Chat'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return ChangeNotifierProvider.value(
      value: _chatProvider!,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Chat'),
        ),
        body: Column(
          children: [
            Expanded(
              child: Consumer<ChatProvider>(
                builder: (context, chatProvider, child) {
                  return ListView.builder(
                    controller: _scrollController,
                    itemCount: chatProvider.messages.length,
                    itemBuilder: (context, index) {
                      final message = chatProvider.messages[index];
                      final isMe = message.senderId == chatProvider.user.id;
                      return ListTile(
                        title: Align(
                          alignment: isMe
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 8.0, horizontal: 12.0),
                            decoration: BoxDecoration(
                              color: isMe ? Colors.blue : Colors.grey[300],
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: Text(
                              message.content,
                              style: TextStyle(
                                  color: isMe ? Colors.white : Colors.black),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration:
                          const InputDecoration(labelText: 'Send a message'),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: () {
                      if (_controller.text.isNotEmpty) {
                        _chatProvider?.sendMessage(_controller.text);
                        _controller.clear();
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
