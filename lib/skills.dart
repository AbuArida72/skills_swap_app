import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddSkillScreen extends StatefulWidget {
  const AddSkillScreen({Key? key}) : super(key: key);

  @override
  _AddSkillScreenState createState() => _AddSkillScreenState();
}

class _AddSkillScreenState extends State<AddSkillScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  String _selectedLocation = 'Amman'; // Default location
  bool _loading = false;
  String? _error;

  final List<String> _locations = ['Amman', 'Aqaba', 'Irbid'];

  Future<void> _addSkill() async {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    setState(() {
      _error = "You must be logged in.";
    });
    return;
  }
  if (_titleController.text.trim().isEmpty) {
    setState(() {
      _error = "Title cannot be empty";
    });
    return;
  }

  setState(() {
    _loading = true;
    _error = null;
  });

  try {
    // Add Skill first
    DocumentReference skillRef = await FirebaseFirestore.instance.collection('skills').add({
      'title': _titleController.text.trim(),
      'description': _descController.text.trim(),
      'ownerId': user.uid,
      'createdAt': FieldValue.serverTimestamp(),
      // Add other fields if needed
    });

    // Create a corresponding Course
    await FirebaseFirestore.instance.collection('courses').add({
      'skillId': skillRef.id,
      'courseName': '${_titleController.text.trim()} Course',
      'ownerId': user.uid,
      'createdAt': FieldValue.serverTimestamp(),
    });

    Navigator.pop(context);
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

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Skill'),
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
        // Use SafeArea and SingleChildScrollView to take full screen and enable scrolling
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height - kToolbarHeight - MediaQuery.of(context).padding.top,
              ),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                        ),
                      ),
                    TextField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'Skill Title',
                        labelStyle: const TextStyle(color: Colors.white),
                        filled: true,
                        fillColor: Colors.white24,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _descController,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        labelStyle: const TextStyle(color: Colors.white),
                        filled: true,
                        fillColor: Colors.white24,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      maxLines: 4,
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedLocation,
                      items: _locations
                          .map((loc) => DropdownMenuItem(
                                value: loc,
                                child: Text(loc),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedLocation = val;
                          });
                        }
                      },
                      decoration: InputDecoration(
                        labelText: 'Location',
                        labelStyle: const TextStyle(color: Colors.white),
                        filled: true,
                        fillColor: Colors.white24,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      dropdownColor: Colors.deepPurple,
                      style: const TextStyle(color: Colors.white),
                    ),
                    const Spacer(),
                    _loading
                        ? const Center(child: CircularProgressIndicator(color: Colors.white))
                        : ElevatedButton(
                            onPressed: _addSkill,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: Colors.deepPurpleAccent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Post Skill', style: TextStyle(fontSize: 18)),
                          ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
