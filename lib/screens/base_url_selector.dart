import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import '../utils.dart';

class EnvironmentSelectionPage extends StatelessWidget {
  EnvironmentSelectionPage({super.key});

  final TextEditingController _controller = TextEditingController();

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
              onPressed: () =>
                  _setEnvironment(context, EnvironmentConfig.webHost),
              child: const Text('Web Environment'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _setEnvironment(
                  context, EnvironmentConfig.androidEmulatorHost),
              child: const Text('Android Emulator Environment'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => {
                _showMyDialog(context),
              },
              child: const Text('Android Device Environment'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showMyDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Enter the api host'),
          content: SingleChildScrollView(
            child: TextField(
              controller: _controller,
              decoration: const InputDecoration(
                border: UnderlineInputBorder(),
                hintText: 'Example: 192.168.1.44',
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Save'),
              onPressed: () {
                var host = _controller.text;
                if (host.isEmpty) {
                  Utils.showSnackBar(context, 'Host cannot be empty');
                } else {
                  _setEnvironment(context, host);
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _setEnvironment(BuildContext context, String url) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_host', url);
    Navigator.pushNamedAndRemoveUntil(
        context, '/login', (Route<dynamic> route) => false);
  }
}

class EnvironmentConfig {
  static const String webHost = 'localhost';
  static const String androidEmulatorHost = '10.0.2.2';
}
