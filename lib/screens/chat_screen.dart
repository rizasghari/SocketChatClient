import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  IOWebSocketChannel? _channel;
  ChatProvider? _chatProvider;

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.loginResponse == null) {
      return;
    }
    final token = authProvider.loginResponse!.token;
    final user = authProvider.loginResponse!.user;
    final url = 'ws://10.0.2.2:8000/ws?conversationId=${widget.conversationId}';

    _channel = IOWebSocketChannel.connect(
      Uri.parse(url),
      headers: {
        'Authorization': token,
      },
    );

    _chatProvider = ChatProvider()
      ..initialize(user, widget.conversationId, _channel!);
  }

  @override
  void dispose() {
    _chatProvider?.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                    itemCount: chatProvider.messages.length,
                    itemBuilder: (context, index) {
                      final message = chatProvider.messages[index];
                      final isMe = message.senderId == chatProvider.user.id;
                      return ListTile(
                        title: Align(
                          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                            decoration: BoxDecoration(
                              color: isMe ? Colors.blue : Colors.grey[300],
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: Text(
                              message.content,
                              style: TextStyle(color: isMe ? Colors.white : Colors.black),
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
                      decoration: const InputDecoration(labelText: 'Send a message'),
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
