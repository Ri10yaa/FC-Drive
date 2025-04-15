import 'package:fc_drive/homepage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _error = '';

  void _login() async {
    try {
      // Validate input
      if (_emailController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
        setState(() {
          _error = 'Email and password are required';
        });
        return;
      }

      // Firebase Authentication Login
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Retrieve Firebase token
      String? token = await userCredential.user!.getIdToken();

      // API Request
      final response = await http.post(
        Uri.parse('http://127.0.0.1:5000/auth/login'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      // Handle response
      if (response.statusCode >= 200 && response.statusCode < 300) {
        setState(() {
          _error = ''; // Clear any previous errors
          print('Login successful');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => MyHomePage()),
          );
        });
      } else {
        setState(() {
          _error = 'API Login failed: ${response.body}';
        });
      }
    } catch (e) {
      print('Login error: $e'); // Log error for debugging
      setState(() {
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFD3CBE5), // Background color
      body: Stack(
        children: [
          // Back Button at the top-left corner
          Positioned(
            top: 10,
            left: 10,
            child: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
          Center(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // App Logo
                  Image.asset(
                    'assets/logo.png', // Replace with your actual logo path
                    height: 120,
                  ),
                  SizedBox(height: 16),
                  // Welcome Text
                  Text(
                    'Welcome Back!',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.bold,
                      fontSize: 28,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Login to continue managing your files securely.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 16,
                      color: Colors.grey[700],
                    ),
                  ),
                  SizedBox(height: 24),
                  // Email Input
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      children: [
                        TextField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        SizedBox(height: 16),
                        // Password Input
                        TextField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            border: OutlineInputBorder(),
                          ),
                          obscureText: true,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24),
                  // Login Button
                  ElevatedButton(
                    onPressed: _login,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                      textStyle: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    child: Text('Login'),
                  ),
                  if (_error.isNotEmpty) ...[
                    SizedBox(height: 16),
                    Text(
                      _error,
                      style: TextStyle(
                        color: Colors.red,
                        fontFamily: 'Roboto',
                        fontSize: 14,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
