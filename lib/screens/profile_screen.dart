import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import '../providers/profile_provider.dart';
import '../models/profile.dart';
import '../services/local_storage_service.dart';
import 'authentication/login_screen.dart';
import 'base_url_selector.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  ProfileProvider? _profileProvider;
  Profile? user;
  String? apiHost;
  late String? jwtToken;

  Logger logger = Logger();

  bool _isLoading = true;

  static const double coverHeight = 200.0;
  static const double profileHeight = 140.0;
  late double profilePhotoFromTop;

  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;

  bool _isUploading = false;
  File? _selectedFile;
  final ImagePicker _picker = ImagePicker();

  late String? profilePhotoUrl;

  Future<void> _pickFile() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedFile = File(pickedFile.path);
        _uploadFile();
      });
    }
  }

  Future<void> _uploadFile() async {
    if (_selectedFile != null) {
      setState(() {
        _isUploading = true;
      });
      final url = await _profileProvider!.uploadProfilePhoto(jwtToken!, _selectedFile!);
      logger.i("Uploaded profile photo: $url");
      setState(() {
        _isUploading = false;
        profilePhotoUrl = "http://$apiHost:9000$url";
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please select a file to upload'),
      ));
    }
  }

  @override
  void initState() {
    super.initState();
    profilePhotoFromTop = coverHeight - profileHeight / 2;
    _initialize();
  }

  Future<void> _initialize() async {
    jwtToken = await LocalStorage.getString('jwt_token');
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
        profilePhotoUrl = "http://$apiHost:9000${_profileProvider!.profile!.profilePhoto!}";
        _isLoading = false;
        _firstNameController =
            TextEditingController(text: _profileProvider?.profile?.firstName);
        _lastNameController =
            TextEditingController(text: _profileProvider?.profile?.lastName);
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
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Text(_profileProvider?.profile?.email ?? '',
              style: const TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              )),
          const SizedBox(height: 20.0),
          TextField(
            onChanged: (value) {},
            controller: _firstNameController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'First name',
              hintText: 'Enter your first name',
            ),
          ),
          const SizedBox(height: 20.0),
          TextField(
            onChanged: (value) {},
            controller: _lastNameController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Last name',
              hintText: 'Enter your last name',
            ),
          ),
          const SizedBox(height: 20.0),
          FilledButton(
              onPressed: () {},
              style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(Colors.blue)),
              child: const Text('Save')),
        ],
      ),
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
      backgroundImage: profilePhotoUrl != null
          ? NetworkImage(profilePhotoUrl!)
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
          Positioned(
              top: profilePhotoFromTop,
              right: profileHeight + 15,
              child: Container(
                height: 30,
                width: 30,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                child: _isUploading
                    ? const CircularProgressIndicator()
                    : IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          _pickFile();
                        },
                        color: Colors.grey,
                        iconSize: 20,
                        padding: EdgeInsets.zero,
                      ),
              )),
        ]);
  }
}
