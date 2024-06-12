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

  late AuthProvider _authProvider;
  late ConversationsProvider _conversationsProvider;

  @override
  void initState() {
    super.initState();

    _authProvider = Provider.of<AuthProvider>(context, listen: false);
    _conversationsProvider = Provider.of<ConversationsProvider>(context, listen: false);
    if (_authProvider.loginResponse == null) {
      return;
    }
    _conversationsProvider.fetchConversations(_authProvider.loginResponse!.token);
    _authProvider.discoverUsers(_authProvider.loginResponse!.token);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Conversations'),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 120,
            child: Consumer<AuthProvider>(
              builder: (context, discoverUsersProvider, child) {
                if (_authProvider.discoverableUsers == null || _authProvider.discoverableUsers!.isEmpty) {
                  return const Center(
                    child: Text('No new users found.'),
                  );
                }

                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _authProvider.discoverableUsers!.length,
                  itemBuilder: (context, index) {
                    final user = _authProvider.discoverableUsers![index];
                    return GestureDetector(
                      onTap: () {
                        // Handle user tap to start a new conversation
                      },
                      child: Container(
                        width: 100,
                        margin: const EdgeInsets.all(8.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundImage: user.profilePhoto != null
                                  ? NetworkImage(user.profilePhoto!)
                                  : null,
                              child: user.profilePhoto == null
                                  ? const Icon(Icons.person)
                                  : null,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${user.firstName} ${user.lastName}',
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Expanded(
            child: Consumer<ConversationsProvider>(
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
          ),
        ],
      ),
    );
  }
}
