import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/profile_provider.dart';
import '../models/profile.dart';
import '../services/local_storage_service.dart';
import 'authentication/login_screen.dart';
import 'base_url_selector.dart';
import '../services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  ProfileProvider? _profileProvider;
  Profile? user;
  bool _isLoading = true;
  String? apiHost;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    var jwtToken = await LocalStorage.getString('jwt_token');
    if (jwtToken == null) {
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => LoginScreen(from: "Profile"),
        ),
      );
    }

    apiHost = await LocalStorage.getString("api_host");
    if (apiHost == null) {
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const EnvironmentSelectionPage(),
        ),
      );
    }

    if (!mounted) return;
    _profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    bool fetched = await _profileProvider!.fetchProfile(jwtToken!);

    if (fetched) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Consumer<ProfileProvider>(
          builder: (context, profileProvider, child) {
            return _isLoading
                ? const CircularProgressIndicator()
                : Column(children: [
                    Stack(
                      children: [
                        Container(
                          width: MediaQuery.of(context).size.width,
                          height: 280,
                          decoration: const BoxDecoration(
                              gradient: LinearGradient(
                            colors: [Color(0xFFFACCCC), Color(0xFFF6EFE9)],
                          )),
                        ),
                        CircleAvatar(
                          radius: 30,
                          backgroundImage:
                              _profileProvider?.profile?.profilePhoto != null
                                  ? NetworkImage(
                                      "http://$apiHost${_profileProvider!.profile!.profilePhoto!}")
                                  : null,
                          child: _profileProvider?.profile?.profilePhoto == null
                              ? const Icon(Icons.person)
                              : null,
                        ),
                      ],
                    ),
                  ]);
          },
        ),
      ),
    );
  }
}
