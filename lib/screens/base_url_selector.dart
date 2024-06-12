import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_chat_flutter/main.dart';

class EnvironmentSelectionPage extends StatelessWidget {
  const EnvironmentSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Environment')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: () => _setEnvironment(context, EnvironmentConfig.webHost),
              child: const Text('Web Environment'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _setEnvironment(context, EnvironmentConfig.androidEmulatorHost),
              child: const Text('Android Emulator Environment'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _setEnvironment(context, EnvironmentConfig.androidDeviceHost),
              child: const Text('Android Device Environment'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _setEnvironment(BuildContext context, String url) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_host', url);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => ChatApp(apiHost: url)),
    );
  }
}

class EnvironmentConfig {
  static const String webHost = 'localhost';
  static const String androidEmulatorHost = '10.0.2.2';
  static const String androidDeviceHost = '192.168.1.74'; // Replace with your actual IP
}
