import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:socket_chat_flutter/providers/chat_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/conversations_provider.dart';
import 'services/local_storage_service.dart';
import 'screens/authentication/signup_screen.dart';
import 'screens/base_url_selector.dart';
import 'screens/conversations_screen.dart';
import 'screens/authentication/login_screen.dart';
import 'package:logger/logger.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final Logger logger = Logger();

  String? jwtToken = await LocalStorage.getString('jwt_token');
  logger.i("main JWT Token: $jwtToken");
  String? apiHost = await LocalStorage.getString('api_host');
  logger.i("main API Host: $apiHost");

  runApp(ChatApp(jwtToken: jwtToken, apiHost: apiHost));
}

class ChatApp extends StatelessWidget {
  final String? jwtToken;
  final String? apiHost;

  const ChatApp({super.key, this.jwtToken, required this.apiHost});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ConversationsProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Chat App',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        initialRoute:
            apiHost == null ? '/env' : (jwtToken == null ? '/login' : '/'),
        routes: {
          '/env': (context) => const EnvironmentSelectionPage(),
          '/': (context) => ConversationsListScreen(),
          '/login': (context) => const LoginScreen(),
          '/signup': (context) => const SignupScreen(),
        },
      ),
    );
  }
}
