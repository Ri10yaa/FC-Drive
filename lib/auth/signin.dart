import 'dart:convert';
import 'package:fc_drive/user.dart';
import 'package:fc_drive/homepage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:fc_drive/auth/encryption.dart';
import 'package:provider/provider.dart';
import 'package:fc_drive/auth/encryption.dart';

import '../UserProvider.dart';

class SignupPage extends StatefulWidget {
  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true; // For password visibility toggle
  bool _showNotification = false; // In-app notification visibility
  String _notificationText = ''; // Notification text
  Color _notificationColor = Colors.red; // Notification color

  void _signup() async {
    try {
      // Validate input
      if (_emailController.text.trim().isEmpty ||
          _passwordController.text.trim().isEmpty) {
        _showInAppNotification('Email and password are required', Colors.red);
        return;
      }

      // API Call
      final response = await http.post(
        Uri.parse('http://127.0.0.1:5000/auth/signup'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': _emailController.text.trim(),
          'password': _passwordController.text.trim(),
        }),
      );
      final responseData = jsonDecode(response.body);
      // Handle Response
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (responseData['msg'] == "Signup successful") {
          print("Signup successful");
          CUser newUser = CUser(
            id: responseData['id'].toString(),
            email: responseData['email'].toString(),
            password: decrypt_it(responseData['password']).toString(),
            fId: responseData['firebase_uid'].toString(),
          );
          print('New User: id=${newUser.id}, email=${newUser.email}, password=${newUser.password}, fId=${newUser.fId}');

          Provider.of<UserProvider>(context, listen: false).setUser(newUser);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => MyHomePage()),
          );
        }

      }
      else if(response.statusCode==400){
        String? msg = responseData['error'];
        _showInAppNotification(
          'Error: $msg',
          Colors.red,
        );
      } else {
        _showInAppNotification(
          'API Signup failed: ${response.body}',
          Colors.red,
        );
      }
    } catch (e) {
      _showInAppNotification('Error: $e', Colors.red);
    }
  }


  void _showInAppNotification(String text, Color color) {
    setState(() {
      _notificationText = text;
      _notificationColor = color;
      _showNotification = true;
    });

    Future.delayed(Duration(seconds: 3), () {
      setState(() {
        _showNotification = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: SizedBox(
              width:
                  MediaQuery.of(context).size.width *
                  0.8, // Occupies 80% of screen width
              child: Card(
                color: Color(0xFFFDFAF6),
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 70.0,
                    horizontal: 20.0,
                  ),
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.stretch, // Stretch vertically
                      children: [
                        // Left Column: Logo and Title
                        Expanded(
                          flex: 1,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Image.asset('assets/logo.png', height: 90),
                              SizedBox(height: 16),
                              Text(
                                'Sign Up',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF27391C),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Vertical Line Separator
                        Container(
                          width: 1, // Thickness of the line
                          color: Colors.grey,
                        ),
                        // Right Column: Input Fields and Button
                        Expanded(
                          flex: 2,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20.0,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                TextField(
                                  cursorColor: Color(0xFF27391C),
                                  controller: _emailController,
                                  decoration: InputDecoration(
                                    labelText: 'Email',
                                    labelStyle: TextStyle(
                                      color: Color(0xFF27391C),
                                    ),
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(
                                      Icons.email,
                                      color: Color(0xFFBF9264),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Color(
                                          0xFF67AE6E,
                                        ), // Change this to your desired color
                                        width:
                                            2.0, // Adjust the width of the border
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 16),
                                TextField(
                                  cursorColor: Color(0xFF27391C),
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    labelStyle: TextStyle(
                                      color: Color(0xFF27391C),
                                    ),
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(
                                      Icons.lock,
                                      color: Color(0xFFBF9264),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Color(
                                          0xFF67AE6E,
                                        ), // Change this to your desired color
                                        width:
                                            2.0, // Adjust the width of the border
                                      ),
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility
                                            : Icons.visibility_off,
                                      ),
                                      color: Color(0xFF67AE6E),
                                      onPressed: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                    ),
                                  ),
                                ),
                                SizedBox(height: 24),
                                ElevatedButton(
                                  onPressed: _signup,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Color(0xFF67AE6E),
                                    foregroundColor: Colors.black,
                                  ),
                                  child: Text(
                                    'Sign Up',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Sliding In-App Notification
          if (_showNotification)
            AnimatedPositioned(
              duration: Duration(milliseconds: 700),
              right: _showNotification ? 10 : -300, // Slide in from right
              top: 20,
              child: Container(
                width: 300,
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _notificationColor,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(2, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        _notificationText,
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.white),
                      onPressed: () {
                        setState(() {
                          _showNotification = false; // Close notification
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
