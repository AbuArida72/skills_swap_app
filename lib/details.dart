import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SkillDetailScreen extends StatefulWidget {
  final DocumentSnapshot skill;
  const SkillDetailScreen({Key? key, required this.skill}) : super(key: key);

  @override
  State<SkillDetailScreen> createState() => _SkillDetailScreenState();
}

class _SkillDetailScreenState extends State<SkillDetailScreen> with SingleTickerProviderStateMixin {
  final user = FirebaseAuth.instance.currentUser;
  bool enrolled = false;
  bool loading = false;
  
  late AnimationController _btnController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _checkEnrollment();

    _btnController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      lowerBound: 0.0,
      upperBound: 0.1,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _btnController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _btnController.dispose();
    super.dispose();
  }

  Future<void> _checkEnrollment() async {
    if (user == null) return;
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
    final courses = userDoc['courses'] as List<dynamic>? ?? [];
    setState(() {
      enrolled = courses.contains('${widget.skill['title']} Course');
    });
  }

  Future<void> _toggleEnrollment() async {
    if (user == null) return;
    setState(() => loading = true);

    final userRef = FirebaseFirestore.instance.collection('users').doc(user!.uid);
    final courseName = '${widget.skill['title']} Course';

    final userDoc = await userRef.get();
    final courses = userDoc['courses'] as List<dynamic>? ?? [];

    if (enrolled) {
      courses.remove(courseName);
    } else {
      courses.add(courseName);
    }

    await userRef.update({'courses': courses});
    setState(() {
      enrolled = !enrolled;
      loading = false;
    });
  }

  Future<void> _deleteSkill() async {
    if (user == null || widget.skill['ownerId'] != user!.uid) return;

    setState(() => loading = true);

    try {
      await FirebaseFirestore.instance.collection('skills').doc(widget.skill.id).delete();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Skill deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete skill: $e')),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final skill = widget.skill;
    final isOwner = user != null && skill['ownerId'] == user!.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        elevation: 0,
        title: Text(
          skill['title'] ?? 'Skill Detail',
          style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.8),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.deepPurple.withOpacity(0.12),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      skill['title'] ?? '',
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.deepPurple, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          skill['location'] ?? 'Unknown location',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.deepPurple,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(
                      skill['description'] ?? 'No description provided.',
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.black87,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              GestureDetector(
                onTapDown: (_) => _btnController.forward(),
                onTapUp: (_) => _btnController.reverse(),
                onTapCancel: () => _btnController.reverse(),
                onTap: loading ? null : _toggleEnrollment,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      color: enrolled ? Colors.redAccent : Colors.deepPurple,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: (enrolled ? Colors.redAccent : Colors.deepPurple).withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: loading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                          )
                        : Text(
                            enrolled ? 'Unenroll from Course' : 'Enroll in Course',
                            style: const TextStyle(
                              fontSize: 20,
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.7,
                            ),
                          ),
                  ),
                ),
              ),

              if (isOwner) ...[
                const SizedBox(height: 20),
                GestureDetector(
                  onTapDown: (_) => _btnController.forward(),
                  onTapUp: (_) => _btnController.reverse(),
                  onTapCancel: () => _btnController.reverse(),
                  onTap: loading ? null : _deleteSkill,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        color: Colors.red.shade700,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.shade700.withOpacity(0.5),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: loading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                            )
                          : const Text(
                              'Delete Skill',
                              style: TextStyle(
                                fontSize: 20,
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.7,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
