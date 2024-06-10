import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

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
        title: const Text('Login'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    child: const Text('Login'),
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
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Login successful'),
                        ));
                        Navigator.pushNamed(context, '/');
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
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
