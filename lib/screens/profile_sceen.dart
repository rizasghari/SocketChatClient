import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        
      ),
      body: const SingleChildScrollView(
        child: Column(
          children: [
            Text('Profile'),
            Text('Profile'),
            Text('Profile'),
            Text('Profile'),
            Text('Profile'),
            Text('Profile'),
            Text('Profile'),
            Text('Profile'),
          ],
        ),
      ),
    );
  }
}
