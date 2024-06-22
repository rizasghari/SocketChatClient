import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import '../providers/profile_provider.dart';
import '../models/profile.dart';
import '../services/local_storage_service.dart';
import '../utils.dart';
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

  static const double coverHeight = 150.0;
  static const double profileHeight = 100.0;
  late double profilePhotoFromTop;

  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  bool _formEnabled = true;

  bool _isUploading = false;
  File? _selectedFile;
  final ImagePicker _picker = ImagePicker();

  late String? profilePhotoUrl;

  String? get _firstNameErrorText {
    final text = _firstNameController.value.text;
    if (text.isEmpty) {
      return 'Can\'t be empty';
    }
    if (text.length < 4) {
      return 'Too short';
    }
    return null;
  }

  String? get _lastNameErrorText {
    final text = _lastNameController.value.text;
    if (text.isEmpty) {
      return 'Can\'t be empty';
    }
    if (text.length < 4) {
      return 'Too short';
    }
    return null;
  }

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
      final url =
          await _profileProvider!.uploadProfilePhoto(jwtToken!, _selectedFile!);
      logger.i("Uploaded profile photo: $url");
      var profilePhoto = await Utils.getProfilePhotoUrl(url!);
      setState(() {
        _isUploading = false;
        profilePhotoUrl = profilePhoto;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please select a file to upload'),
      ));
    }
  }

  Future<void> _saveProfile() async {
    if (_formEnabled) {
      setState(() {
        _formEnabled = false;
      });
      bool updated = await _profileProvider!.updateProfile(
          jwtToken!, _firstNameController.text, _lastNameController.text);
      if (!mounted) return;
      if (updated) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Profile updated successfully'),
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Failed to update profile'),
        ));
      }
      setState(() {
        _formEnabled = true;
      });
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
          builder: (context) => EnvironmentSelectionPage(),
        ),
      );
    }

    if (!mounted) return;
    _profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    bool fetched = await _profileProvider!.fetchProfile(jwtToken!);

    if (fetched) {
      var profilePhoto = await Utils.getProfilePhotoUrl(
          _profileProvider!.profile!.profilePhoto!);
      setState(() {
        profilePhotoUrl = profilePhoto;
        _isLoading = false;

        _firstNameController =
            TextEditingController(text: _profileProvider?.profile?.firstName);

        _lastNameController =
            TextEditingController(text: _profileProvider?.profile?.lastName);
      });
    }
  }

  Widget _pageIsLoading() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<ProfileProvider>(
        builder: (context, profileProvider, child) {
          return _isLoading
              ? _pageIsLoading()
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
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(_profileProvider?.profile?.email ?? '',
              style: const TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.w300,
                color: Colors.grey,
              )),
          IconButton(
              onPressed: () {
                logout();
              },
              icon: const Icon(Icons.logout, color: Colors.grey)),
        ]),
        const SizedBox(height: 20.0),
        TextField(
          controller: _firstNameController,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            labelText: 'First name',
            hintText: 'Enter your first name',
            enabled: _formEnabled,
            errorText: _firstNameErrorText,
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 20.0),
        TextField(
          controller: _lastNameController,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            labelText: 'Last name',
            hintText: 'Enter your last name',
            enabled: _formEnabled,
            errorText: _lastNameErrorText,
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 20.0),
        FilledButton(
          onPressed: () {
            if (_firstNameErrorText == null && _lastNameErrorText == null) {
              _saveProfile();
            }
          },
          style: ButtonStyle(
              backgroundColor: WidgetStateProperty.all(Colors.blue)),
          child: _formEnabled
              ? const Text('Update')
              : const SizedBox(
                  height: 20.0,
                  width: 20.0,
                  child: Center(
                      child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.0,
                  )),
                ),
        ),
      ]),
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
      backgroundImage:
          profilePhotoUrl != null ? NetworkImage(profilePhotoUrl!) : null,
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
          Positioned(
              top: 0,
              left: 0,
              child: IconButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.arrow_back, color: Colors.white))),
          Positioned(top: profilePhotoFromTop, child: profilePhoto()),
          Positioned(
              top: profilePhotoFromTop,
              right: profileHeight * 1.5,
              child: Container(
                height: 25,
                width: 25,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                child: _isUploading
                    ? const SizedBox(
                        height: 12.0,
                        width: 12.0,
                        child: Center(
                            child: CircularProgressIndicator(
                          color: Colors.grey,
                          strokeWidth: 2.0,
                        )),
                      )
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

  void logout() async {
    await Provider.of<ProfileProvider>(context, listen: false).logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(
        context, '/env', (Route<dynamic> route) => false);
  }
}
