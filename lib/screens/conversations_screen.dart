import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:socket_chat_client/models/conversation.dart';
import '../utils.dart';
import 'authentication/login_screen.dart';
import '../services/local_storage_service.dart';
import '../providers/auth_provider.dart';
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
  AuthProvider? _authProvider;
  int? _currentUserID;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    _authProvider = Provider.of<AuthProvider>(context, listen: false);
    ConversationsProvider conversationsProvider =
        Provider.of<ConversationsProvider>(context, listen: false);

    var jwtToken = await LocalStorage.getString('jwt_token');
    if (jwtToken == null) {
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => LoginScreen(from: "Conversations"),
        ),
      );
    }

    conversationsProvider.fetchConversations(jwtToken!);
    _authProvider!.discoverUsers(jwtToken);

    _currentUserID = await LocalStorage.getInt('user_id');
    if (_currentUserID == null) {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Conversations'),
      ),
      bottomNavigationBar: _navigationBar(),
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
          SizedBox(
            height: 120,
            child: Consumer<AuthProvider>(
              builder: (context, discoverUsersProvider, child) {
                return _discoverableUsers();
              },
            ),
          ),
          Expanded(
            child: Consumer<ConversationsProvider>(
              builder: (context, conversationsProvider, child) {
                return _conversationsList(conversationsProvider);
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
    if (_authProvider == null ||
        _authProvider!.discoverableUsers == null ||
        _authProvider!.discoverableUsers!.isEmpty) {
      return _noDiscoverableUsers();
    }
    return _discoverableUsersList();
  }

  Widget _noDiscoverableUsers() {
    return const Center(
      child: Text('No new users found.'),
    );
  }

  Widget _discoverableUsersList() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: _authProvider!.discoverableUsers!.length,
      itemBuilder: (context, index) {
        final user = _authProvider!.discoverableUsers![index];
        return GestureDetector(
          onTap: () {
            Utils.showSnackBar(context, "${user.firstName} ${user.lastName}");
          },
          child: Container(
            width: 90,
            margin: const EdgeInsets.all(5.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 35,
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
  }

  Widget _conversationsList(ConversationsProvider conversationsProvider) {
    if (conversationsProvider.conversations.isEmpty) {
      return _noConversation();
    }
    return ListView.builder(
      itemCount: conversationsProvider.conversations.length,
      itemBuilder: (context, index) {
        final conversation = conversationsProvider.conversations[index];
        return ListTile(
          leading: _conversationItemUserProfilePhoto(conversation),
          title: _conversationItemTitle(conversation),
          subtitle:
              Text(conversation.members.map((m) => m.firstName).join(', ')),
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
  }

  Widget _noConversation() {
    return const Center(
      child: Text('No conversations found.'),
    );
  }

  Widget _conversationItemUserProfilePhoto(Conversation conversation) {
    return CircleAvatar(
      backgroundImage: conversation.members[0].profilePhoto != null
          ? NetworkImage(conversation.members[0].profilePhoto!)
          : null,
      child: conversation.members[0].profilePhoto == null
          ? const Icon(Icons.person)
          : null,
    );
  }

  Widget _conversationItemTitle(Conversation conversation) {
    var title = "";
    for (var member in conversation.members) {
      if (member.id != _currentUserID) {
        title = "${member.firstName} ${member.lastName}";
        break;
      }
    }
    return Text(
      title,
      overflow: TextOverflow.ellipsis,
    );
  }
}
