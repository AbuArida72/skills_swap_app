import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'details.dart';

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

  Future<void> openSkillDetail(String courseName) async {
    final skillName = courseName.replaceAll(' Course', '').trim();

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('skills')
          .where('title', isEqualTo: skillName)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final skillDoc = querySnapshot.docs.first;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SkillDetailScreen(skill: skillDoc),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Skill "$skillName" not found')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading skill details: $e')),
      );
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
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: loading
                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                : error != null
                    ? Center(
                        child: Text(
                          error!,
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : enrolledCourses.isEmpty
                        ? const Center(
                            child: Text(
                              'No enrolled courses yet.',
                              style: TextStyle(color: Colors.white, fontSize: 18),
                            ),
                          )
                        : ListView.separated(
                            itemCount: enrolledCourses.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final course = enrolledCourses[index];

                              return Material(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                                child: InkWell(
                                  onTap: () => openSkillDetail(course),
                                  borderRadius: BorderRadius.circular(16),
                                  splashColor: Colors.deepPurpleAccent.withOpacity(0.2),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.book_rounded, size: 32, color: Colors.white),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Text(
                                            course,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white54),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ),
      ),
    );
  }
}
