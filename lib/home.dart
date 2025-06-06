import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeScreen extends StatelessWidget {
  final user = FirebaseAuth.instance.currentUser;

  // Static sample data
  final List<Map<String, String>> trendingSkills = [
    {'title': 'Photography', 'description': 'Learn to shoot like a pro'},
    {'title': 'Guitar', 'description': 'Basic chords and strumming patterns'},
    {'title': 'Cooking', 'description': 'Easy recipes for beginners'},
  ];

  final List<Map<String, String>> yourSkills = [
    {'title': 'Flutter Development', 'description': 'Build cross-platform apps'},
    {'title': 'Graphic Design', 'description': 'Create stunning visuals'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Remove back arrow from AppBar by setting automaticallyImplyLeading to false
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Skill Swap'),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
              icon: Icon(Icons.add),
              onPressed: () => Navigator.pushNamed(context, '/skills')),
          IconButton(
              icon: Icon(Icons.person),
              onPressed: () => Navigator.pushNamed(context, '/profile')),
          IconButton(
              icon: Icon(Icons.logout),
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.pushReplacementNamed(context, '/login');
              }),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple.shade700, Colors.deepPurple.shade200],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: EdgeInsets.all(16),
        child: ListView(
          children: [
            Text(
              'Trending Skills',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 10),
            ...trendingSkills.map((skill) => Card(
                  color: Colors.deepPurple.shade400,
                  child: ListTile(
                    title: Text(
                      skill['title']!,
                      style: TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      skill['description']!,
                      style: TextStyle(color: Colors.white70),
                    ),
                    onTap: () {
                      // TODO: Navigate to skill detail if needed
                    },
                  ),
                )),
            SizedBox(height: 30),
            Text(
              'Your Registered Skills',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 10),
            ...yourSkills.map((skill) => Card(
                  color: Colors.deepPurple.shade600,
                  child: ListTile(
                    title: Text(
                      skill['title']!,
                      style: TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      skill['description']!,
                      style: TextStyle(color: Colors.white70),
                    ),
                    onTap: () {
                      // TODO: Show skill details or edit
                    },
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
