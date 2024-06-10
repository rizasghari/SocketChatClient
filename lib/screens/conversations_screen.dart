import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/conversations_provider.dart';
import 'chat_screen.dart';

class ConversationsListScreen extends StatefulWidget {
  const ConversationsListScreen({super.key});

  @override
  _ConversationsListScreenState createState() => _ConversationsListScreenState();
}

class _ConversationsListScreenState extends State<ConversationsListScreen> {
  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final conversationsProvider = Provider.of<ConversationsProvider>(context, listen: false);
    if (authProvider.loginResponse == null) {
      return;
    }
    conversationsProvider.fetchConversations(authProvider.loginResponse!.token);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Conversations'),
      ),
      body: Consumer<ConversationsProvider>(
        builder: (context, conversationsProvider, child) {
          if (conversationsProvider.conversations.isEmpty) {
            return const Center(
              child: Text('No conversations found.'),
            );
          }

          return ListView.builder(
            itemCount: conversationsProvider.conversations.length,
            itemBuilder: (context, index) {
              final conversation = conversationsProvider.conversations[index];
              return ListTile(
                title: Text(conversation.name),
                subtitle: Text(conversation.members.map((m) => m.firstName).join(', ')),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(conversationId: conversation.id),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
