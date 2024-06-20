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
import 'package:web_socket_channel/io.dart';
import 'chat_screen.dart';

class ConversationsListScreen extends StatefulWidget {
  ConversationsListScreen({super.key});

  final Logger logger = Logger();

  @override
  State<ConversationsListScreen> createState() =>
      _ConversationsListScreenState();
}

class _ConversationsListScreenState extends State<ConversationsListScreen> {
  ConversationsProvider? conversationsProvider;
  int? _currentUserID;
  String? jwtToken;
  bool _isLoading = false;
  int _discoverableUserIndex = -1;
  IOWebSocketChannel? _socketChannel;

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
    conversationsProvider =
        Provider.of<ConversationsProvider>(context, listen: false)
    ..initialize(jwtToken!);
  }

  Future<void> _createConversation(List<int> ids) async {
    Conversation? conversation =
        await conversationsProvider!.createConversation(jwtToken!, ids);
    setState(() {
      _isLoading = false;
    });
    if (conversation != null && mounted) {
      conversationsProvider!.discoverableUsers!.removeAt(_discoverableUserIndex);
      setState(() {
        _discoverableUserIndex = -1;
      });
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            conversation: conversation,
          ),
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
            child: Consumer<ConversationsProvider>(
              builder: (context, discoverUsersProvider, child) {
                return discoverUsersProvider.isDiscoverableUsersFetching
                    ? const Center(child: CircularProgressIndicator())
                    : _discoverableUsers();
              },
            ),
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
    if (conversationsProvider == null ||
        conversationsProvider!.discoverableUsers == null ||
        conversationsProvider!.discoverableUsers!.isEmpty) {
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
      itemCount: conversationsProvider!.discoverableUsers!.length,
      itemBuilder: (context, index) {
        final user = conversationsProvider!.discoverableUsers![index];
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
                      radius: 35,
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
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5.0),
                    Text(user.firstName,
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ],
            ),
          ),
        );
      },
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
                builder: (context) => ChatScreen(conversation: conversation),
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
    String? photo;
    for (var member in conversation.members) {
      if (member.id != _currentUserID) {
        photo = member.profilePhoto;
        break;
      }
    }
    return CircleAvatar(
      backgroundImage: photo != null ? NetworkImage(photo) : null,
      child: photo == null ? const Icon(Icons.person) : null,
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
