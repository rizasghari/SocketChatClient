import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:socket_chat_flutter/repositories/local_storage.dart';
import '../providers/auth_provider.dart';
import '../providers/conversations_provider.dart';
import 'chat_screen.dart';

class ConversationsListScreen extends StatefulWidget {
  const ConversationsListScreen({super.key});
  @override
  _ConversationsListScreenState createState() =>
      _ConversationsListScreenState();
}

class _ConversationsListScreenState extends State<ConversationsListScreen> {
  AuthProvider? _authProvider;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    _authProvider = Provider.of<AuthProvider>(context, listen: false);
    final conversationsProvider =
        Provider.of<ConversationsProvider>(context, listen: false);
    if (_authProvider == null || _authProvider!.loginResponse == null) {
      return;
    }
    var jwtToken = await LocalStorage.getString('jwt_token');
    jwtToken ??= _authProvider!.loginResponse!.token;
    conversationsProvider.fetchConversations(jwtToken);
    _authProvider!.discoverUsers(jwtToken);
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
                if (_authProvider == null ||
                    _authProvider!.discoverableUsers == null ||
                    _authProvider!.discoverableUsers!.isEmpty) {
                  return const Center(
                    child: Text('No new users found.'),
                  );
                }

                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _authProvider!.discoverableUsers!.length,
                  itemBuilder: (context, index) {
                    final user = _authProvider!.discoverableUsers![index];
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
                    final conversation =
                        conversationsProvider.conversations[index];
                    return ListTile(
                      title: Text(conversation.name),
                      subtitle: Text(conversation.members
                          .map((m) => m.firstName)
                          .join(', ')),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ChatScreen(conversationId: conversation.id),
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
