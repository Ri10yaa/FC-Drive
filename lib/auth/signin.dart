import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class SignupPage extends StatefulWidget {
  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _error = '';
  String _message = '';

  void _signup() async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      String? token = await userCredential.user!.getIdToken();

      final response = await http.post(
        Uri.parse('http://127.0.0.1:5000/auth/signin'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: '{"email": "${_emailController.text}", "password": "${_passwordController.text}"}',
      );

      if (response.statusCode == 200) {
        setState(() {
          _message = "Signup successful! Welcome.";
          _error = '';
        });
      } else {
        setState(() {
          _error = 'API Signup failed: ${response.body}';
          _message = '';
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _message = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFD3CBE5),
      body: Stack(
        children: [
          // Back Button at the Top-Left
          Positioned(
            top: 10,
            left: 10,
            child: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () {
                Navigator.pop(context); // Navigates back to the previous screen
              },
            ),
          ),
          // Main Content
          Center(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/logo.png', // Replace with your actual logo path
                    height: 120,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Welcome to FC-Drive',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.bold,
                      fontSize: 28,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Sign up to manage and organize your files securely.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 16,
                      color: Colors.grey[700],
                    ),
                  ),
                  SizedBox(height: 24),
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
                  ElevatedButton(
                    onPressed: _signup,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                      textStyle: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    child: Text('Sign Up'),
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
                  if (_message.isNotEmpty) ...[
                    SizedBox(height: 16),
                    Text(
                      _message,
                      style: TextStyle(
                        color: Colors.green,
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
