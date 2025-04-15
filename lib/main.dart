import 'package:fc_drive/auth/login.dart';
import 'package:fc_drive/auth/signin.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'homepage.dart';
import 'theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: dotenv.env['FIREBASE_API_KEY']?? '',
        authDomain: dotenv.env['FIREBASE_AUTH_DOMAIN']??'',
        projectId: dotenv.env['FIREBASE_PROJECT_ID']??'',
        storageBucket: dotenv.env['FIREBASE_STORAGE_BUCKET'],
        messagingSenderId: dotenv.env['FIREBASE_MSG_ID']??'',
        appId: dotenv.env['FIREBASE_APP_ID']??'',
        measurementId: dotenv.env['FIREBASE_MSR_ID'],
      ),
    );
  } else {
    await Firebase.initializeApp();
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        theme: ThemeData(
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.primary,
      colorScheme: ColorScheme.fromSwatch().copyWith(
        secondary: AppColors.accent,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.black,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.accent,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    ),
        home: CheckFirstRun()
    );
  }
}

class CheckFirstRun extends StatelessWidget {
  Future<bool> isFirstRun() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('signed_in') ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: isFirstRun(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.data == true) {
            return MyHomePage();
          } else {
            return OnboardingPage();
          }
        }
        return Center(child: CircularProgressIndicator());
      },
    );
  }
}

// Onboarding Page
class OnboardingPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            // Welcome Text
            const Text(
              'Welcome to FC-Drive',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.green, // Green theme color
              ),
            ),
            const SizedBox(height: 10),
            // Description Text
            const Text(
              'FC-Drive helps you store, organize, and share your files securely, just like Google Drive—but with a unique, personal touch.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 40),
            // Sign In Button
            ElevatedButton(
              onPressed: () {
                // Navigate to Login Page
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LoginPage(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                 // Green theme for button
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                backgroundColor: null,
              ),
              child: const Text('Log In'),
            ),
            const SizedBox(height: 20),
            // Sign Up Button
            ElevatedButton(
              onPressed: () {
                // Navigate to Sign-Up Page
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SignupPage(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green, // Green theme for button
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
              ),
              child: const Text('Sign Up'),
            ),
          ],
        ),
      ),
    );
  }
}

