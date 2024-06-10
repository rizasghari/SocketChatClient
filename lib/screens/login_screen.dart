import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            SizedBox(height: 20),
            _isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
                    child: Text('Login'),
                    onPressed: () async {
                      setState(() {
                        _isLoading = true;
                      });
                      final success = await authProvider.login(
                        _emailController.text,
                        _passwordController.text,
                      );
                      setState(() {
                        _isLoading = false;
                      });
                      if (success) {
                        // Navigate to the next screen or show success message
                      } else {
                        // Show error message
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Login failed'),
                        ));
                      }
                    },
                  ),
          ],
        ),
      ),
    );
  }
}
