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
  static const double coverHeight = 200.0;
  static const double profileHeight = 140.0;
  late double profilePhotoFromTop;

  @override
  void initState() {
    super.initState();
    profilePhotoFromTop = coverHeight - profileHeight / 2;
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
      body: Consumer<ProfileProvider>(
        builder: (context, profileProvider, child) {
          return _isLoading
              ? const CircularProgressIndicator()
              : ListView(
                  children: [
                    buildTop(),
                    buildProfile(),
                  ],
                );
        },
      ),
    );
  }

  Widget buildProfile() {
    return Column(
      children: [
        const SizedBox(height: 10.0),
        Text(
          _profileProvider?.profile?.firstName ?? '',
          style: const TextStyle(
            fontSize: 28.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10.0),
        Text(
          _profileProvider?.profile?.email ?? '',
          style: const TextStyle(fontSize: 20.0, color: Colors.grey),
        ),
      ],
    );
  }

  Widget coverImage() {
    return Container(
      height: coverHeight,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/cover.jpeg'),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget profilePhoto() {
    return CircleAvatar(
      radius: profileHeight / 2,
      backgroundImage: _profileProvider?.profile?.profilePhoto != null
          ? NetworkImage(
              "http://$apiHost:9000${_profileProvider!.profile!.profilePhoto!}")
          : null,
      child: _profileProvider?.profile?.profilePhoto == null
          ? const Icon(Icons.person)
          : null,
    );
  }

  Widget buildTop() {
    return Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: profileHeight / 2),
            child: coverImage(),
          ),
          Positioned(top: profilePhotoFromTop, child: profilePhoto()),
        ]);
  }
}
