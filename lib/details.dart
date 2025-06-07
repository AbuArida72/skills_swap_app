import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SkillDetailScreen extends StatefulWidget {
  const SkillDetailScreen({Key? key}) : super(key: key);

  @override
  State<SkillDetailScreen> createState() => _SkillDetailScreenState();
}

class _SkillDetailScreenState extends State<SkillDetailScreen> {
  final user = FirebaseAuth.instance.currentUser;
  bool isEnrolled = false;

  late DocumentSnapshot skill;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    skill = ModalRoute.of(context)!.settings.arguments as DocumentSnapshot;
    _checkEnrollment();
  }

  Future<void> _checkEnrollment() async {
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
    final List<dynamic> courses = userDoc['courses'] ?? [];
    final String courseName = '${skill['title']} Course';

    setState(() {
      isEnrolled = courses.contains(courseName);
    });
  }

  Future<void> _toggleEnrollment() async {
    final userRef = FirebaseFirestore.instance.collection('users').doc(user!.uid);
    final String courseName = '${skill['title']} Course';

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final userSnapshot = await transaction.get(userRef);
      List<dynamic> currentCourses = userSnapshot['courses'] ?? [];

      if (currentCourses.contains(courseName)) {
        currentCourses.remove(courseName);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unenrolled from $courseName')),
        );
      } else {
        currentCourses.add(courseName);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Enrolled in $courseName')),
        );
      }

      transaction.update(userRef, {'courses': currentCourses});
    });

    _checkEnrollment();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(skill['title']),
        backgroundColor: Colors.deepPurple,
      ),
      body: Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6D0EB5), Color(0xFF4059F1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(skill['title'], style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Text(skill['description'], style: const TextStyle(fontSize: 18)),
                  ],
                ),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _toggleEnrollment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isEnrolled ? Colors.red : Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  isEnrolled ? 'Unenroll from Course' : 'Enroll in Course',
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
