import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'providers/chat_provider.dart';
import 'providers/profile_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/conversations_provider.dart';
import 'screens/authentication/login_screen.dart';
import 'services/local_storage_service.dart';
import 'screens/authentication/signup_screen.dart';
import 'screens/base_url_selector.dart';
import 'screens/conversations_screen.dart';
import 'screens/profile_screen.dart';

Logger logger = Logger();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  String? jwtToken = await LocalStorage.getString('jwt_token');
  String? apiHost = await LocalStorage.getString('api_host');
  logger.i("JWT Token: $jwtToken");
  logger.i("API Host: $apiHost");

  runApp(ChatApp(jwtToken: jwtToken, apiHost: apiHost));
}

class ChatApp extends StatelessWidget {
  final String? jwtToken;
  final String? apiHost;

  const ChatApp({super.key, this.jwtToken, required this.apiHost});

  @override
  Widget build(BuildContext context) {
    logger.i("API Host: $apiHost");
    var initialRoute = apiHost == null
        ? '/env'
        : (jwtToken == null ? '/login' : '/conversations');
    logger.i("Initial route: $initialRoute");
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ConversationsProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Chat App',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        navigatorKey: navigatorKey,
        initialRoute: initialRoute,
        routes: {
          '/env': (context) => EnvironmentSelectionPage(),
          '/conversations': (context) => ConversationsListScreen(),
          '/login': (context) => LoginScreen(
                from: 'Home Page',
              ),
          '/signup': (context) => const SignupScreen(),
          '/profile': (context) => const ProfileScreen()
        },
      ),
    );
  }
}
