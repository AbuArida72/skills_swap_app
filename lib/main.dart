import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

// Screens
import 'welcome.dart';
import 'login.dart';
import 'signup.dart';
import 'skills.dart';
import 'details.dart';
import 'home.dart';
import 'profile.dart';
import 'courses.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Skill Swap',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => WelcomeScreen(),
        '/login': (context) => LoginScreen(),
        '/signup': (context) => RegisterScreen(),
        '/home': (context) => HomeScreen(),
        '/skills': (context) => AddSkillScreen(),
        '/profile': (context) => ProfileScreen(),
        '/courses': (context) => EnrolledCoursesScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/details') {
          final skill = settings.arguments as DocumentSnapshot;
          return MaterialPageRoute(
            builder: (context) => SkillDetailScreen(skill: skill),
          );
        }
        return null;
      },
    );
  }
}
