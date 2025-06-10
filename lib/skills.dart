import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddSkillScreen extends StatefulWidget {
  const AddSkillScreen({Key? key}) : super(key: key);

  @override
  _AddSkillScreenState createState() => _AddSkillScreenState();
}

class _AddSkillScreenState extends State<AddSkillScreen> {
  final title = TextEditingController();
  final description = TextEditingController();
  final key = GlobalKey<FormState>();
  String location = 'Amman';
  bool loading = false;
  final user = FirebaseAuth.instance.currentUser;

  final List<String> locations = ['Amman', 'Aqaba', 'Irbid', 'Online'];

  Future<void> _addSkill() async {
    if (!key.currentState!.validate()) return;
    if (user == null) return;

    setState(() => loading = true);

    try {
      await FirebaseFirestore.instance.collection('skills').add({
        'title': title.text.trim(),
        'description': description.text.trim(),
        'location': location,
        'ownerId': user!.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding skill: $e')),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    title.dispose();
    description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Skill'),
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Card(
          elevation: 12,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: key,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Create a Skill',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                  const SizedBox(height: 20),

                  TextFormField(
                    controller: title,
                    decoration: const InputDecoration(
                      labelText: 'Skill Title',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => (value == null || value.isEmpty) ? 'Enter a skill title' : null,
                  ),
                  const SizedBox(height: 20),

                  TextFormField(
                    controller: description,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Skill Description',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => (value == null || value.isEmpty) ? 'Enter a description' : null,
                  ),
                  const SizedBox(height: 20),

                  Text(
                    'Select Location',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.deepPurple.shade700),
                  ),
                  const SizedBox(height: 8),

                  DropdownButtonFormField<String>(
                    value: location,
                    items: locations.map((loc) => DropdownMenuItem(
                      value: loc,
                      child: Text(loc),
                    )).toList(),
                    onChanged: (value) => setState(() => location = value!),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: loading ? null : _addSkill,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: loading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Add Skill', style: TextStyle(fontSize: 18)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
