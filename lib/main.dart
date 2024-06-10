import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:socket_chat_flutter/providers/chat_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/conversations_provider.dart';
import 'screens/authentication/signup_screen.dart';
import 'screens/conversations_screen.dart';
import 'screens/authentication/login_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
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
        initialRoute: '/login',
        routes: {
          '/': (context) => const ConversationsListScreen(),
          '/login': (context) => const LoginScreen(),
          '/signup': (context) => const SignupScreen(),
        },
      ),
    );
  }
}
