import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EnrolledCoursesScreen extends StatefulWidget {
  const EnrolledCoursesScreen({Key? key}) : super(key: key);

  @override
  State<EnrolledCoursesScreen> createState() => _EnrolledCoursesScreenState();
}

class _EnrolledCoursesScreenState extends State<EnrolledCoursesScreen> {
  List<String> enrolledCourses = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    fetchCourses();
  }

  Future<void> fetchCourses() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        error = "User not logged in";
        loading = false;
      });
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final List<dynamic>? courseList = doc.data()?['courses'];

      if (courseList != null) {
        enrolledCourses = courseList.whereType<String>().where((c) => c.trim().isNotEmpty).toList();
      }

      setState(() {
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = 'Failed to load courses: $e';
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enrolled Courses'),
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
        padding: const EdgeInsets.all(16),
        child: loading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : error != null
                ? Center(child: Text(error!, style: const TextStyle(color: Colors.white)))
                : enrolledCourses.isEmpty
                    ? const Center(child: Text('No enrolled courses yet.', style: TextStyle(color: Colors.white)))
                    : ListView.builder(
                        itemCount: enrolledCourses.length,
                        itemBuilder: (context, index) {
                          final course = enrolledCourses[index];
                          return Card(
                            color: Colors.white.withOpacity(0.9),
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            child: ListTile(
                              title: Text(course, style: const TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold)),
                              leading: const Icon(Icons.book, color: Colors.deepPurple),
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}
