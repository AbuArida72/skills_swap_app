import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {

  final key = GlobalKey<FormState>();
  final username = TextEditingController();
  final biography = TextEditingController();
  final email = TextEditingController();
  final pass1 = TextEditingController();
  final pass2 = TextEditingController();

  String? image;
  bool loading = false;
  bool upload = false;
  String? error;

  final User? user = FirebaseAuth.instance.currentUser;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (user != null) {
      email.text = user!.email ?? '';
      FirebaseFirestore.instance.collection('users').doc(user!.uid).get().then((doc) {
        if (doc.exists) {
          final data = doc.data()!;
          username.text = data['username'];
          biography.text = data['bio'];
          setState(() {
            image = data['profileImageUrl'];
          });
        }
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!key.currentState!.validate()) return;

    setState(() {
      loading = true;
      error = null;
    });

    try {
      if (email.text.trim() != user!.email) {
        if (pass1.text.isEmpty) {
          setState(() {
            error = 'Please enter your current password to update email.';
            loading = false;
          });
          return;
        }
        final credential = EmailAuthProvider.credential(
          email: user!.email!,
          password: pass1.text,
        );
        await user!.reauthenticateWithCredential(credential);
        await user!.updateEmail(email.text.trim());
      }

      if (pass2.text.isNotEmpty) {
        if (pass1.text.isEmpty) {
          setState(() {
            error = 'Please enter your current password to update password.';
            loading = false;
          });
          return;
        }
        final credential = EmailAuthProvider.credential(
          email: user!.email!,
          password: pass1.text,
        );
        await user!.reauthenticateWithCredential(credential);
        await user!.updatePassword(pass2.text);
      }

      await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
        'username': username.text.trim(),
        'bio': biography.text.trim(),
        'profileImageUrl': image ?? '',
        'email': email.text.trim(),
      }, SetOptions(merge: true));

      setState(() {
        error = 'Profile updated successfully!';
      });
    } catch (e) {
      setState(() {
        error = e.toString();
      });
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  Future<void> _pickProfileImage() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() {
          upload = true;
          error = null;
        });

        final String fileName = 'profile_images/${user!.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final Reference storageRef = FirebaseStorage.instance.ref().child(fileName);
        
        final UploadTask uploadTask = storageRef.putFile(File(pickedFile.path));
        final TaskSnapshot snapshot = await uploadTask;
        
        final String downloadUrl = await snapshot.ref.getDownloadURL();
        
        setState(() {
          image = downloadUrl;
          upload = false;
        });

        await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
          'profileImageUrl': downloadUrl,
        });

        setState(() {
          error = 'Profile picture uploaded successfully!';
        });
      }
    } catch (e) {
      setState(() {
        upload = false;
        error = 'Failed to upload image: ${e.toString()}';
      });
    }
  }

  @override
  void dispose() {
    username.dispose();
    biography.dispose();
    email.dispose();
    pass1.dispose();
    pass2.dispose();
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
          key: key,
          child: ListView(
            children: [
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    error!,
                    style: TextStyle(
                      color: error!.contains('success') ? Colors.greenAccent : Colors.redAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _pickProfileImage,
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundImage: image != null && image!.isNotEmpty
                                ? NetworkImage(image!)
                                : null,
                            child: image == null || image!.isEmpty
                                ? const Icon(Icons.person, size: 50, color: Colors.white70)
                                : null,
                            backgroundColor: Colors.deepPurple.shade300,
                          ),
                          if (upload)
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.5),
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: upload ? null : _pickProfileImage,
                      icon: upload 
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.deepPurple,
                              ),
                            )
                          : const Icon(Icons.photo_camera, size: 18),
                      label: Text(upload ? 'Uploading...' : 'Upload Photo'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.deepPurple,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildInputCard(
                label: 'Username',
                controller: username,
                validator: (val) => val == null || val.trim().isEmpty ? 'Username cannot be empty' : null,
              ),
              const SizedBox(height: 16),
              _buildInputCard(
                label: 'Bio',
                controller: biography,
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              _buildInputCard(
                label: 'Email',
                controller: email,
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
                controller: pass1,
                obscureText: true,
              ),
              const SizedBox(height: 16),
              _buildInputCard(
                label: 'New Password',
                controller: pass2,
                obscureText: true,
                validator: (val) {
                  if (val != null && val.isNotEmpty && val.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              loading
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