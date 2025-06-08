import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  final _emailController = TextEditingController();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();

  String? _profileImageUrl;
  bool _loading = false;
  String? _error;

  final User? user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    if (user != null) {
      _emailController.text = user!.email ?? '';
      FirebaseFirestore.instance.collection('users').doc(user!.uid).get().then((doc) {
        if (doc.exists) {
          final data = doc.data()!;
          _usernameController.text = data['username'] ?? '';
          _bioController.text = data['bio'] ?? '';
          setState(() {
            _profileImageUrl = data['profileImageUrl'];
          });
        }
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      if (_emailController.text.trim() != user!.email) {
        if (_oldPasswordController.text.isEmpty) {
          setState(() {
            _error = 'Please enter your current password to update email.';
            _loading = false;
          });
          return;
        }
        final credential = EmailAuthProvider.credential(
          email: user!.email!,
          password: _oldPasswordController.text,
        );
        await user!.reauthenticateWithCredential(credential);
        await user!.updateEmail(_emailController.text.trim());
      }

      if (_newPasswordController.text.isNotEmpty) {
        if (_oldPasswordController.text.isEmpty) {
          setState(() {
            _error = 'Please enter your current password to update password.';
            _loading = false;
          });
          return;
        }
        final credential = EmailAuthProvider.credential(
          email: user!.email!,
          password: _oldPasswordController.text,
        );
        await user!.reauthenticateWithCredential(credential);
        await user!.updatePassword(_newPasswordController.text);
      }

      await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
        'username': _usernameController.text.trim(),
        'bio': _bioController.text.trim(),
        'profileImageUrl': _profileImageUrl ?? '',
        'email': _emailController.text.trim(),
      }, SetOptions(merge: true));

      setState(() {
        _error = 'Profile updated successfully!';
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  void _pickProfileImage() {
    // Future implementation
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    _emailController.dispose();
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Not logged in')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6D0EB5), Color(0xFF4059F1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: _error!.contains('success') ? Colors.greenAccent : Colors.redAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              Center(
                child: GestureDetector(
                  onTap: _pickProfileImage,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage: _profileImageUrl != null && _profileImageUrl!.isNotEmpty
                        ? NetworkImage(_profileImageUrl!)
                        : null,
                    child: _profileImageUrl == null || _profileImageUrl!.isEmpty
                        ? const Icon(Icons.person, size: 50, color: Colors.white70)
                        : null,
                    backgroundColor: Colors.deepPurple.shade300,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildInputCard(
                label: 'Username',
                controller: _usernameController,
                validator: (val) => val == null || val.trim().isEmpty ? 'Username cannot be empty' : null,
              ),
              const SizedBox(height: 16),
              _buildInputCard(
                label: 'Bio',
                controller: _bioController,
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              _buildInputCard(
                label: 'Email',
                controller: _emailController,
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Email cannot be empty';
                  if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w]{2,4}').hasMatch(val)) {
                    return 'Enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildInputCard(
                label: 'Current Password',
                controller: _oldPasswordController,
                obscureText: true,
              ),
              const SizedBox(height: 16),
              _buildInputCard(
                label: 'New Password',
                controller: _newPasswordController,
                obscureText: true,
                validator: (val) {
                  if (val != null && val.isNotEmpty && val.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              _loading
                  ? const Center(child: CircularProgressIndicator(color: Colors.white))
                  : ElevatedButton(
                      onPressed: _saveProfile,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.deepPurple,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Save Changes', style: TextStyle(fontSize: 18)),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputCard({
    required String label,
    required TextEditingController controller,
    int maxLines = 1,
    bool obscureText = false,
    String? Function(String?)? validator,
  }) {
    return Card(
      color: Colors.white.withOpacity(0.1),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: TextFormField(
          controller: controller,
          maxLines: maxLines,
          obscureText: obscureText,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(color: Colors.white),
            border: InputBorder.none,
          ),
          validator: validator,
        ),
      ),
    );
  }
}
