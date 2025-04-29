import 'package:fc_drive/auth/login.dart';
import 'package:fc_drive/auth/signin.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:fc_drive/providers/UserProvider.dart';

import 'providers/FolderProvider.dart';
import 'homepage.dart';


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

  runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (context) => UserProvider()),
          ChangeNotifierProvider(create: (context) => FolderProvider()),
        ],
        child: MyApp()
      )
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        theme: ThemeData(
          scaffoldBackgroundColor: Colors.grey[100],
          progressIndicatorTheme: ProgressIndicatorThemeData(
            color: Color(0xFFBF9264),
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
      body: Center(
        child: Card(
          color: Theme.of(context).cardColor,
          elevation: 5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Replace with your logo
                Image.asset('assets/logo.png',),
                SizedBox(height: 10),
                Text(
                  "Welcome to FC-Drive. Keep It Close, Keep It Cloud.",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 20),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor:Color(0xFF67AE6E),
                    foregroundColor: Colors.black
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SignupPage()),
                    );
                  },
                  child: Text("Sign Up", style: TextStyle(
                      fontWeight: FontWeight.w500
                  ),),
                ),
                SizedBox(height: 10),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => LoginPage()),
                    );
                  },
                  child: Text("Log In",style: TextStyle(
                    decoration: TextDecoration.underline,
                    decorationColor: Color(0xFF67AE6E),
                    color: Color(0xFFBF9264),
                    fontWeight: FontWeight.w600
                  ),),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


